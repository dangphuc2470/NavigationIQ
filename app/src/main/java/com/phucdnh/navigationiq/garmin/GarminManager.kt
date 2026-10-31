package com.phucdnh.navigationiq.garmin

import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.adb.AdbConnection
import com.phucdnh.navigationiq.map.OsmMapManager
import com.phucdnh.navigationiq.map.OsmMapPacket
import com.phucdnh.navigationiq.model.NavigationInfo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Singleton managing Garmin ConnectIQ lifecycle, device discovery and message transmission.
 * Supports both the original HeadUpNav watch app and the custom NavigationIQ watch app.
 */
object GarminManager {

    private const val TAG = "GarminManager"

    // NavigationIQ Official Release Watch App ID (Unique Custom UUID)
    const val NAVIQ_APP_ID = "0da65dc3-6e66-4072-bd03-802b2b9c3807"

    // NavigationIQ Beta Watch App ID (Backward compatibility for beta testers)
    const val NAVIQ_BETA_APP_ID = "e24767ea-b254-4f25-9391-ff4c409a037c"

    // Garmin Connect IQ Store URL
    const val GARMIN_STORE_URL = "https://apps.garmin.com/apps/c2c48dd7-47e7-4fac-98e2-6762d57ff181"

    // Open Source GitHub Repository URL
    const val GITHUB_REPO_URL = "https://github.com/dangphuc2470/NavigationIQ"

    val SUPPORTED_APP_IDS = listOf(
        NAVIQ_APP_ID,
        NAVIQ_BETA_APP_ID
    )

    enum class WatchAppChannel(val id: String, val label: String) {
        RELEASE(NAVIQ_APP_ID, "Release"),
        BETA(NAVIQ_BETA_APP_ID, "Beta")
    }

    private val _selectedChannel = MutableStateFlow(
        if (com.phucdnh.navigationiq.BuildConfig.VERSION_NAME.contains("beta", ignoreCase = true)) {
            WatchAppChannel.BETA
        } else {
            WatchAppChannel.RELEASE
        }
    )
    val selectedChannelFlow = _selectedChannel.asStateFlow()
    val selectedChannel get() = _selectedChannel.value

    fun setWatchAppChannel(context: Context, channel: WatchAppChannel) {
        _selectedChannel.value = channel
        activeAppId = channel.id
        context.getSharedPreferences("navigation_iq_prefs", Context.MODE_PRIVATE)
            .edit()
            .putString("pref_target_channel", channel.name)
            .putString("pref_active_app_id", channel.id)
            .apply()
        addLog("[CHANNEL] Kênh gửi đồng hồ: ${channel.label} (${channel.id.take(8)}...)")

        for (device in devices) {
            val app = registeredApps.getOrPut(channel.id) { IQApp(channel.id) }
            registerAppEvents(device, app)
        }
    }

    // Max log entries shown in UI
    private const val MAX_LOGS = 50

    private val mapScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var mapJob: Job? = null
    var isMapMode = false; private set

    // -------------------------------------------------------------------------
    // Observable state for UI
    private val _isWatchFound = MutableStateFlow(false)
    val isWatchFoundFlow = _isWatchFound.asStateFlow()

    private val _isHeartbeatLive = MutableStateFlow(false)
    val isHeartbeatLiveFlow = _isHeartbeatLive.asStateFlow()

    private val _watchName = MutableStateFlow<String?>(null)
    val watchNameFlow = _watchName.asStateFlow()

    private val _sentCount = MutableStateFlow(0)
    val sentCountFlow = _sentCount.asStateFlow()

    /** Ring-buffer of recent log lines: "[HH:mm:ss] message" */
    private val _logs = MutableStateFlow<List<String>>(emptyList())
    val logsFlow = _logs.asStateFlow()

    private val _watchBattery = MutableStateFlow<Float?>(null)
    val watchBatteryFlow = _watchBattery.asStateFlow()

    private val _watchDrainRate = MutableStateFlow<Float?>(null)
    val watchDrainRateFlow = _watchDrainRate.asStateFlow()

    private val _isActivityRecording = MutableStateFlow(false)
    val isActivityRecordingFlow = _isActivityRecording.asStateFlow()

    private var lastWatchRxTime = 0L

    // -------------------------------------------------------------------------
    // Internal state
    // -------------------------------------------------------------------------
    private var connectIQ: ConnectIQ? = null
    private var devices: List<IQDevice> = emptyList()
    private val registeredApps = mutableMapOf<String, IQApp>()

    @Volatile private var isSdkReady = false
    private val cache = SentDataCache()
    private var failedCount = 0

    val isWatchFound get() = _isWatchFound.value
    var isAppFound = false; private set
    var isWatchAppAlive = false; private set

    @Volatile
    var isNavigating = false
        private set

    @Volatile
    private var lastNavInfoTime = 0L

    @Volatile
    private var activeAppId: String? = null

    init {
        for (id in SUPPORTED_APP_IDS) {
            registeredApps[id] = IQApp(id)
        }
    }

    /**
     * Resolves target apps installed on the watch.
     * Prioritizes the active app that responded to avoid duplicate/blocking transmissions.
     */
    fun getTargetApps(): List<IQApp> {
        val targetId = _selectedChannel.value.id
        val app = registeredApps.getOrPut(targetId) { IQApp(targetId) }
        return listOf(app)
    }

    // -------------------------------------------------------------------------
    // Public API
    // -------------------------------------------------------------------------

    private fun isEmulator(): Boolean {
        return (android.os.Build.BRAND.startsWith("generic") && android.os.Build.DEVICE.startsWith("generic"))
                || android.os.Build.FINGERPRINT.startsWith("generic")
                || android.os.Build.FINGERPRINT.startsWith("unknown")
                || android.os.Build.HARDWARE.contains("goldfish")
                || android.os.Build.HARDWARE.contains("ranchu")
                || android.os.Build.MODEL.contains("google_sdk")
                || android.os.Build.MODEL.contains("Emulator")
                || android.os.Build.MODEL.contains("Android SDK built for x86")
                || android.os.Build.MANUFACTURER.contains("Genymotion")
                || android.os.Build.PRODUCT.contains("sdk_google")
                || android.os.Build.PRODUCT.contains("google_sdk")
                || android.os.Build.PRODUCT.contains("sdk")
                || android.os.Build.PRODUCT.contains("sdk_x86")
                || android.os.Build.PRODUCT.contains("vbox86p")
                || android.os.Build.PRODUCT.contains("emulator")
                || android.os.Build.PRODUCT.contains("simulator")
    }

    private var isSdkInitializing = false

    /** Init SDK. Safe to call multiple times – skips if already ready. */
    @Synchronized
    fun initSdk(context: Context, onReady: (() -> Unit)? = null) {
        initPreferences(context)
        if (isSdkReady) {
            loadDevices(context)
            onReady?.invoke()
            return
        }
        if (isSdkInitializing) {
            return
        }
        isSdkInitializing = true
        _disposeSdk(context)
        try {
            val connectType = if (isEmulator()) {
                ConnectIQ.IQConnectType.TETHERED
            } else {
                ConnectIQ.IQConnectType.WIRELESS
            }
            connectIQ = ConnectIQ.getInstance(context, connectType).apply {
                initialize(context, false, object : ConnectIQ.ConnectIQListener {
                    override fun onSdkReady() {
                        addLog("Garmin SDK ready ($connectType)")
                        isSdkInitializing = false
                        isSdkReady = true
                        loadDevices(context)
                        startHeartbeatMonitor()
                        onReady?.invoke()
                    }
                    override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus) {
                        addLog("SDK init error: $status")
                        isSdkInitializing = false
                        isSdkReady = false
                    }
                    override fun onSdkShutDown() {
                        addLog("SDK shut down")
                        isSdkInitializing = false
                        isSdkReady = false
                        _isWatchFound.value = false
                        _isHeartbeatLive.value = false
                    }
                })
            }
        } catch (e: Exception) {
            isSdkInitializing = false
            addLog("Init exception: ${e.message}")
            Log.e(TAG, "ConnectIQ init exception: ${e.message}")
        }
    }

    /** Full restart when Bluetooth turns back ON. */
    @Synchronized
    fun restartConnection(context: Context) {
        addLog("BT reconnect – restarting SDK")
        if (!isBluetoothEnabled(context)) {
            addLog("BT still off – skip restart")
            return
        }
        isSdkReady = false
        isAppFound = false
        isWatchAppAlive = false
        devices = emptyList()
        cache.reset()
        failedCount = 0
        _isWatchFound.value = false
        _watchName.value = null
        initSdk(context) {
            addLog("SDK re-initialized after BT reconnect")
        }
    }

    /** Full recovery: sends naviend to watch, clears queues/caches, restarts SDK, and probes with ping. */
    fun recoverConnection(context: Context, onComplete: ((Boolean) -> Unit)? = null) {
        addLog("[RECOVER] Initiating full connection recovery...")
        try {
            sendNavigationEnd(context)
        } catch (_: Exception) {}

        isSending = false
        sendTimeoutHandler.removeCallbacks(timeoutRunnable)
        latestPendingInfo = null
        cache.reset()

        restartConnection(context)

        mapScope.launch {
            delay(1500)
            sendPing(context)
            onComplete?.invoke(true)
        }
    }

    fun loadDevices(context: Context) {
        appContext = context.applicationContext
        if (!isSdkReady) return
        val ciq = connectIQ ?: return
        try {
            val known = ciq.knownDevices ?: emptyList()
            devices = known
            if (devices.isNotEmpty()) {
                _isWatchFound.value = true
                val first = devices.first()
                _watchName.value = first.friendlyName?.takeIf { it.isNotBlank() } ?: "Garmin Watch"
                for (dev in devices) {
                    val name = dev.friendlyName?.takeIf { it.isNotBlank() } ?: "Garmin Watch"
                    addLog("Device: $name (${dev.status})")
                    checkAndRegisterApps(context, dev)
                    ciq.registerForDeviceEvents(dev) { device, status ->
                        onDeviceStatusChanged(context, device, status)
                    }
                }
            } else {
                _isWatchFound.value = false
                addLog("No paired Garmin devices found in Connect app")
            }
        } catch (e: Exception) {
            addLog("loadDevices error: ${e.message}")
            Log.e(TAG, "loadDevices: ${e.message}")
        }
    }

    private const val SEND_TIMEOUT_MS = 400L

    @Volatile
    private var isSending = false
    @Volatile
    private var latestPendingInfo: NavigationInfo? = null
    @Volatile
    private var sendStartTime = 0L

    private val sendTimeoutHandler = Handler(Looper.getMainLooper())
    private val timeoutRunnable = Runnable {
        if (isSending) {
            addLog("[WARN] Send timeout (${SEND_TIMEOUT_MS}ms) – forcing unlock & dispatching latest")
            isSending = false
            latestPendingInfo?.let {
                dispatchLatest(appContext ?: return@Runnable)
            }
        }
    }

    private var appContext: Context? = null

    fun sendNavigationInfo(context: Context, info: NavigationInfo) {
        appContext = context.applicationContext
        latestPendingInfo = info
        isNavigating = true
        lastNavInfoTime = System.currentTimeMillis()

        if (isMapMode) {
            // Map tab is active on Garmin watch: pause detailed HUD transmission to prioritize map bandwidth
            return
        }
        if (!isSdkReady) {
            initSdk(context) { 
                latestPendingInfo?.let { sendNavigationInfo(context, it) }
            }
            return
        }

        if (isSending) {
            // UDP style: if previous send is stuck beyond threshold, force unlock and dispatch latest immediately
            if (System.currentTimeMillis() - sendStartTime > SEND_TIMEOUT_MS) {
                sendTimeoutHandler.removeCallbacks(timeoutRunnable)
                isSending = false
                dispatchLatest(context)
            }
            return
        }

        dispatchLatest(context)
    }

    @Synchronized
    private fun dispatchLatest(context: Context) {
        val info = latestPendingInfo ?: return
        latestPendingInfo = null
        isSending = true
        sendStartTime = System.currentTimeMillis()

        sendTimeoutHandler.removeCallbacks(timeoutRunnable)
        sendTimeoutHandler.postDelayed(timeoutRunnable, SEND_TIMEOUT_MS)

        // Refresh devices list if empty
        if (devices.isEmpty()) {
            val ciq = connectIQ
            if (ciq != null) {
                devices = ciq.knownDevices ?: emptyList()
            }
        }

        if (devices.isEmpty()) {
            addLog("[WARN] No Garmin device found to send to")
            isSending = false
            sendTimeoutHandler.removeCallbacks(timeoutRunnable)
            return
        }

        val message = GarminMessage(context, info, cache)
        if (message.isEmpty()) {
            isSending = false
            sendTimeoutHandler.removeCallbacks(timeoutRunnable)
            if (latestPendingInfo != null) dispatchLatest(context)
            return
        }

        val targetApps = mutableListOf<Pair<IQDevice, IQApp>>()
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                targetApps.add(device to app)
            }
        }

        if (targetApps.isEmpty()) {
            addLog("[WARN] No registered apps found, re-checking devices...")
            for (dev in devices) {
                checkAndRegisterApps(context, dev)
            }
            isSending = false
            sendTimeoutHandler.removeCallbacks(timeoutRunnable)
            return
        }



        var completedCount = 0
        var anySuccess = false
        var isUnlocked = false
        for ((device, app) in targetApps) {
            sendMessage(context, device, app, message) { success ->
                if (success) {
                    anySuccess = true
                    if (activeAppId != app.applicationId) {
                        activeAppId = app.applicationId
                        context.getSharedPreferences("navigation_iq_prefs", Context.MODE_PRIVATE)
                            .edit().putString("pref_active_app_id", app.applicationId).apply()
                    }
                }
                completedCount++
                // UDP mode: Immediately unlock as soon as active app succeeds, or all finished
                if (!isUnlocked && (anySuccess || completedCount >= targetApps.size)) {
                    isUnlocked = true
                    sendTimeoutHandler.removeCallbacks(timeoutRunnable)
                    isSending = false
                    if (anySuccess) {
                        failedCount = 0
                    } else {
                        failedCount++
                        if (failedCount >= 10) {
                            addLog("[WARN] Consecutive failures across all watch apps – restarting connection")
                            failedCount = 0
                            restartConnection(context)
                        }
                    }
                    // If a newer update arrived during transmission, send it immediately
                    if (latestPendingInfo != null) {
                        dispatchLatest(context)
                    }
                }
            }
        }
        _sentCount.value++
        addLog("[SEND #${_sentCount.value}] ${info.distance} | ${info.signs} | ETA: ${info.eta}")
    }

    fun sendNavigationEnd(context: Context) {
        isNavigating = false
        latestPendingInfo = null
        val endMsg = GarminMessage()
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                sendMessage(context, device, app, endMsg)
            }
        }
        cache.reset()
        addLog("[SEND] Navigation ended (naviend)")
    }

    fun sendNavigationArrived(context: Context, summary: com.phucdnh.navigationiq.model.TripSummary) {
        isNavigating = false
        latestPendingInfo = null
        val arrivedMsg = GarminMessage.createArrivedMessage(summary)
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                sendMessage(context, device, app, arrivedMsg)
            }
        }
        cache.reset()
        addLog("[SEND] Navigation arrived: ${summary.destination} | ${summary.duration} | ${summary.distance} | ${summary.avgSpeed}")
    }
    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private fun onDeviceStatusChanged(context: Context, device: IQDevice, status: IQDevice.IQDeviceStatus) {
        val name = if (device.friendlyName == "Simulator") "Garmin Simulator" else (device.friendlyName?.takeIf { it.isNotBlank() } ?: "Garmin Watch")
        addLog("Device '$name' → $status")
        when (status) {
            IQDevice.IQDeviceStatus.CONNECTED, IQDevice.IQDeviceStatus.UNKNOWN -> {
                _isWatchFound.value = true
                _watchName.value = name
                checkAndRegisterApps(context, device)
            }
            IQDevice.IQDeviceStatus.NOT_CONNECTED -> {
                val isAdbConnected = AdbConnection.getInstance().isConnected
                val stillConnected = isAdbConnected || devices.any { it.status != IQDevice.IQDeviceStatus.NOT_CONNECTED && it.status != IQDevice.IQDeviceStatus.NOT_PAIRED }
                _isWatchFound.value = stillConnected
                if (!stillConnected) _watchName.value = null
            }
            else -> {}
        }
    }

    private fun checkAndRegisterApps(context: Context, device: IQDevice) {
        for (appId in SUPPORTED_APP_IDS) {
            val app = registeredApps.getOrPut(appId) { IQApp(appId) }
            registerAppEvents(device, app)
            connectIQ?.getApplicationInfo(appId, device, object : ConnectIQ.IQApplicationInfoListener {
                override fun onApplicationInfoReceived(infoApp: IQApp?) {
                    if (infoApp != null) {
                        registeredApps[appId] = infoApp
                        isAppFound = true
                        val label = "NavigationIQ"
                        addLog("Found $label: ${infoApp.status}")
                        registerAppEvents(device, infoApp)
                    }
                }
                override fun onApplicationNotInstalled(id: String?) {
                    // Do NOT remove from registeredApps. Sideloaded PRG binaries installed via USB
                    // are not registered in the Garmin Connect IQ Store database and will report
                    // onApplicationNotInstalled here. Removing them breaks sideloaded communication.
                }
            })
        }
    }

    private var currentMapZoom = 16
    private var currentPanDx = 0
    private var currentPanDy = 0

    private fun registerAppEvents(device: IQDevice, app: IQApp) {
        connectIQ?.registerForAppEvents(device, app) { _, _, messages, _ ->
            if (messages.isNullOrEmpty()) return@registerForAppEvents
            if (activeAppId != app.applicationId) {
                activeAppId = app.applicationId
                appContext?.getSharedPreferences("navigation_iq_prefs", Context.MODE_PRIVATE)
                    ?.edit()?.putString("pref_active_app_id", app.applicationId)?.apply()
                addLog("[APP] Active watch app locked from RX: ${app.applicationId.take(8)}...")
            }
            lastWatchRxTime = System.currentTimeMillis()
            _isHeartbeatLive.value = true
            _isWatchFound.value = true

            val first = messages[0]
            if (first is List<*> && first.isNotEmpty()) {
                val action = first[0]?.toString()
                when (action) {
                    "next_stop", "resume_nav" -> {
                        addLog("[WATCH ACTION] Nhận lệnh Next Stop từ nút trên đồng hồ!")
                        com.phucdnh.navigationiq.service.NavNotificationService.triggerNextStop()
                    }
                    "map_zoom" -> {
                        val zoom = (first.getOrNull(1) as? Number)?.toInt() ?: 16
                        currentMapZoom = zoom
                        addLog("[MAP] Changed Zoom to $zoom")
                        triggerInstantMapUpdate()
                    }
                    "map_pan" -> {
                        val dx = (first.getOrNull(1) as? Number)?.toInt() ?: 0
                        val dy = (first.getOrNull(2) as? Number)?.toInt() ?: 0
                        currentPanDx = dx
                        currentPanDy = dy
                        addLog("[MAP] Pan request: dx=$dx, dy=$dy")
                    }
                    "battery_stat" -> {
                        val batPct = (first.getOrNull(1) as? Number)?.toFloat() ?: -1f
                        val drainRate = (first.getOrNull(2) as? Number)?.toFloat() ?: 0f
                        val isAct = (first.getOrNull(3) as? Number)?.toInt() ?: 0
                        if (batPct >= 0f) {
                            _watchBattery.value = batPct
                            _watchDrainRate.value = drainRate
                            val drainStr = if (drainRate > 0f) "-${String.format(java.util.Locale.US, "%.1f", drainRate)}%/h" else "--"
                            addLog("[BATTERY] Pin đồng hồ: ${batPct.toInt()}% ($drainStr) | Chế độ Activity: ${if (isAct == 1) "BẬT" else "TẮT"}")
                        }
                    }
                }
                return@registerForAppEvents
            }

            val msg = first?.toString() ?: return@registerForAppEvents
            addLog("[RECV from watch] $msg")
            when (msg) {
                "next_stop", "resume_nav" -> {
                    addLog("[WATCH ACTION] Nhận lệnh Next Stop từ nút trên đồng hồ!")
                    com.phucdnh.navigationiq.service.NavNotificationService.triggerNextStop()
                }
                "reset", "alive", "pong" -> {
                    cache.reset()
                    isWatchAppAlive = true
                    _isWatchFound.value = true
                    _isHeartbeatLive.value = true
                }
                "resetimage" -> {
                    cache.sendBitmap = true
                    isWatchAppAlive = true
                }
                "dead" -> {
                    isWatchAppAlive = false
                    _isHeartbeatLive.value = false
                }
                // Map mode disabled by user request
                // "map_on" -> { ... }
                // "map_off" -> { ... }
                // "map_recenter" -> { ... }
            }
        }
    }

    private var heartbeatJob: Job? = null

    private fun startHeartbeatMonitor() {
        heartbeatJob?.cancel()
        heartbeatJob = mapScope.launch {
            while (isActive) {
                val now = System.currentTimeMillis()
                val isAlive = (now - lastWatchRxTime < 25_000L && lastWatchRxTime > 0L)
                _isHeartbeatLive.value = isAlive
                // Auto-clear stuck isNavigating if no Google Maps update arrived for > 5 minutes
                if (isNavigating && lastNavInfoTime > 0L && (now - lastNavInfoTime > 300_000L)) {
                    isNavigating = false
                    addLog("[WATCHDOG] Không có bản tin điều hướng mới sau 5 phút -> Ngắt ping giữ kết nối để tiết kiệm pin")
                }
                // Only send ping if there is an active navigation running to let watch radio deep-sleep when idle
                if (!isMapMode && latestPendingInfo == null && isSdkReady && isNavigating) {
                    sendPing()
                }
                // When actively navigating, ping every 15s. When idle, check every 60s without pinging radio.
                val pingInterval = if (isNavigating) 15_000L else 60_000L
                delay(pingInterval)
            }
        }
    }

    fun sendPing(context: Context? = null) {
        val ctx = context ?: appContext
        if (devices.isEmpty()) {
            devices = connectIQ?.knownDevices ?: emptyList()
        }
        if (registeredApps.isEmpty() && devices.isNotEmpty() && ctx != null) {
            for (dev in devices) {
                checkAndRegisterApps(ctx, dev)
            }
        }
        val payload = listOf("ping", System.currentTimeMillis())
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                try {
                    connectIQ?.sendMessage(device, app, payload) { _, _, status ->
                        if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                            lastWatchRxTime = System.currentTimeMillis()
                            _isHeartbeatLive.value = true
                        }
                    }
                } catch (e: Exception) {
                    // Ignore ping failures
                }
            }
        }
    }

    private fun triggerInstantMapUpdate() {
        if (!isMapMode) return
        mapScope.launch {
            try {
                val mapPacket = OsmMapManager.generateMapPacket(zoom = currentMapZoom)
                if (mapPacket != null && isMapMode) {
                    sendMapPacket(mapPacket)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Instant map update error: ${e.message}")
            }
        }
    }

    private fun startMapLoop() {
        // Map mode loop disabled by user request
        /*
        appContext?.let {
            OsmMapManager.initialize(it)
            OsmMapManager.startLocationUpdates(it)
        }
        mapJob?.cancel()
        mapJob = mapScope.launch {
            while (isActive && isMapMode) {
                try {
                    val mapPacket = OsmMapManager.generateMapPacket(zoom = currentMapZoom)
                    if (mapPacket != null && isMapMode) {
                        sendMapPacket(mapPacket)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in map loop: ${e.message}")
                }
                delay(5000L)
            }
        }
        */
    }

    private fun stopMapLoop() {
        mapJob?.cancel()
        mapJob = null
        // OsmMapManager.stopLocationUpdates()
    }

    fun sendMapPacket(packet: OsmMapPacket) {
        val payload = listOf(
            "map",
            packet.width,
            packet.height,
            packet.zoom,
            packet.speedKmh,
            packet.headingDeg,
            packet.rleData,
            packet.palette
        )
        if (devices.isEmpty()) {
            devices = connectIQ?.knownDevices ?: emptyList()
        }
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                try {
                    connectIQ?.sendMessage(device, app, payload) { _, _, status ->
                        if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                            _sentCount.value = _sentCount.value + 1
                            addLog("[MAP] Sent 5s OSM map tile OK")
                        } else {
                            addLog("[MAP] Send map tile status: $status")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "sendMapPacket error: ${e.message}")
                }
            }
        }
    }

    fun sendToastNotification(appName: String, sender: String, message: String, durationSec: Int = 5) {
        val payload = listOf("toast", appName, sender, message, durationSec)
        if (devices.isEmpty()) {
            devices = connectIQ?.knownDevices ?: emptyList()
        }
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                try {
                    connectIQ?.sendMessage(device, app, payload) { _, _, status ->
                        if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                            addLog("[TOAST] Sent in-app banner to watch: $appName - $sender")
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "sendToastNotification error: ${e.message}")
                }
            }
        }
    }

    private var lastPromptTime = 0L

    fun promptOpenWatchApp(device: IQDevice, app: IQApp) {
        val now = System.currentTimeMillis()
        // Never prompt if watch app is already alive or was communicating recently
        if (isWatchAppAlive || (now - lastWatchRxTime < 30_000L && lastWatchRxTime > 0L)) {
            return
        }
        if (now - lastPromptTime < 15_000L) return // Throttled to avoid prompt spam
        lastPromptTime = now
        try {
            connectIQ?.openApplication(device, app) { _, _, status ->
                addLog("Prompt watch to open app: $status")
            }
        } catch (e: Exception) {
            Log.e(TAG, "openApplication exception: ${e.message}")
        }
    }

    fun setActivityRecording(context: Context, enabled: Boolean) {
        _isActivityRecording.value = enabled
        val prefs = context.getSharedPreferences("navigation_iq_prefs", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("pref_activity_recording", enabled).apply()
        sendActivityModeSetting(enabled)
    }

    fun initPreferences(context: Context) {
        val prefs = context.getSharedPreferences("navigation_iq_prefs", Context.MODE_PRIVATE)
        val saved = prefs.getBoolean("pref_activity_recording", false) // Default OFF
        _isActivityRecording.value = saved
        val savedChannelName = prefs.getString("pref_target_channel", null)
        if (savedChannelName != null) {
            try {
                _selectedChannel.value = WatchAppChannel.valueOf(savedChannelName)
            } catch (_: Exception) {}
        }
        activeAppId = _selectedChannel.value.id
        addLog("[INIT] Kênh gửi đồng hồ: ${_selectedChannel.value.label} (${_selectedChannel.value.id.take(8)}...)")
    }

    fun sendActivityModeSetting(isEnabled: Boolean) {
        val payload = listOf("set_activity_mode", if (isEnabled) 1 else 0)
        if (devices.isEmpty()) {
            devices = connectIQ?.knownDevices ?: emptyList()
        }
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                try {
                    connectIQ?.sendMessage(device, app, payload) { _, _, status ->
                        if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                            addLog("[SETTING] Chế độ Activity đã đồng bộ sang đồng hồ: ${if (isEnabled) "BẬT" else "TẮT"}")
                        }
                    }
                } catch (_: Exception) {}
            }
        }
    }

    /**
     * Send Text Size & Layout Preset to Garmin Watch
     * 0 = Balanced, 1 = Street Focus, 2 = Distance Focus, 3 = Large Text
     */
    fun sendTextPreset(presetId: Int, onComplete: ((Boolean) -> Unit)? = null) {
        if (devices.isEmpty()) {
            devices = connectIQ?.knownDevices ?: emptyList()
        }
        val payload = listOf("set_text_preset", presetId)
        var anyDispatched = false
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                try {
                    connectIQ?.sendMessage(device, app, payload) { _, _, status ->
                        val success = (status == ConnectIQ.IQMessageStatus.SUCCESS)
                        if (success) {
                            addLog("[PRESET] Set text size preset to $presetId OK")
                            lastWatchRxTime = System.currentTimeMillis()
                            _isHeartbeatLive.value = true
                        } else {
                            addLog("[PRESET] Set text size failed: $status")
                        }
                        onComplete?.invoke(success)
                    }
                    anyDispatched = true
                } catch (e: Exception) {
                    addLog("[PRESET] Error sending preset: ${e.message}")
                }
            }
        }
        if (!anyDispatched) {
            onComplete?.invoke(false)
        }
    }

    /**
     * Send Watch Layout Profile to Garmin Watch
     * 0 = Auto Detect, 1 = Rect (Venu Sq / X1), 2 = Round (Fenix / Venu 2), 3 = Instinct Crossover
     */
    fun sendLayoutProfile(profileId: Int, onComplete: ((Boolean) -> Unit)? = null) {
        if (devices.isEmpty()) {
            devices = connectIQ?.knownDevices ?: emptyList()
        }
        val payload = listOf("set_layout_profile", profileId)
        var anyDispatched = false
        val apps = getTargetApps()
        for (device in devices) {
            for (app in apps) {
                try {
                    connectIQ?.sendMessage(device, app, payload) { _, _, status ->
                        val success = (status == ConnectIQ.IQMessageStatus.SUCCESS)
                        if (success) {
                            addLog("[PROFILE] Set layout profile to $profileId OK")
                            lastWatchRxTime = System.currentTimeMillis()
                            _isHeartbeatLive.value = true
                        } else {
                            addLog("[PROFILE] Set layout profile failed: $status")
                        }
                        onComplete?.invoke(success)
                    }
                    anyDispatched = true
                } catch (e: Exception) {
                    addLog("[PROFILE] Error sending profile: ${e.message}")
                }
            }
        }
        if (!anyDispatched) {
            onComplete?.invoke(false)
        }
    }

    private fun sendMessage(context: Context, device: IQDevice, app: IQApp, message: GarminMessage, onComplete: ((Boolean) -> Unit)? = null) {
        try {
            connectIQ?.sendMessage(device, app, message.toDataPayload()) { _, _, status ->
                val success = (status == ConnectIQ.IQMessageStatus.SUCCESS)
                if (success) {
                    lastWatchRxTime = System.currentTimeMillis()
                    _isHeartbeatLive.value = true
                    _isWatchFound.value = true
                } else {
                    addLog("[FAIL] Send to ${app.applicationId.take(8)}...: $status")
                }
                onComplete?.invoke(success)
            }
        } catch (e: Exception) {
            addLog("[ERR] sendMessage: ${e.message}")
            Log.e(TAG, "sendMessage: ${e.message}")
            onComplete?.invoke(false)
        }
    }

    private fun _disposeSdk(context: Context? = null) {
        try {
            connectIQ?.shutdown(context)
        } catch (_: Exception) {}
        connectIQ = null
    }

    private fun isBluetoothEnabled(context: Context): Boolean {
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return btManager?.adapter?.isEnabled == true
    }

    // -------------------------------------------------------------------------
    // Log helper
    // -------------------------------------------------------------------------
    private val timeFmt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

    fun addLog(msg: String) {
        val entry = "[${timeFmt.format(Date())}] $msg"
        Log.d(TAG, entry)
        val current = _logs.value.toMutableList()
        current.add(0, entry)
        if (current.size > MAX_LOGS) current.removeAt(current.size - 1)
        _logs.value = current
    }
}
