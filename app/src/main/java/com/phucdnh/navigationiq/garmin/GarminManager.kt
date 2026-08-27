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

    // NavigationIQ Watch App ID (Unique Custom UUID)
    const val NAVIQ_APP_ID = "e24767ea-b254-4f25-9391-ff4c409a037c"

    val SUPPORTED_APP_IDS = listOf(
        NAVIQ_APP_ID
    )

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

    init {
        for (appId in SUPPORTED_APP_IDS) {
            registeredApps[appId] = IQApp(appId)
        }
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

    fun loadDevices(context: Context) {
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

    @Volatile
    private var isSending = false
    @Volatile
    private var latestPendingInfo: NavigationInfo? = null
    @Volatile
    private var sendStartTime = 0L
    private val sendTimeoutHandler = Handler(Looper.getMainLooper())
    private val timeoutRunnable = Runnable {
        if (isSending) {
            addLog("[WARN] Send timeout (2.5s) – forcing unlock & dispatching latest")
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
            // If currently sending, check if send has timed out (>2500ms)
            if (System.currentTimeMillis() - sendStartTime > 2500) {
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
        sendTimeoutHandler.postDelayed(timeoutRunnable, 2500)

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
        for (device in devices) {
            for (app in registeredApps.values) {
                targetApps.add(device to app)
            }
        }

        if (targetApps.isEmpty()) {
            isSending = false
            sendTimeoutHandler.removeCallbacks(timeoutRunnable)
            if (latestPendingInfo != null) dispatchLatest(context)
            return
        }

        var completedCount = 0
        for ((device, app) in targetApps) {
            sendMessage(context, device, app, message) {
                completedCount++
                if (completedCount >= targetApps.size) {
                    sendTimeoutHandler.removeCallbacks(timeoutRunnable)
                    isSending = false
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
        latestPendingInfo = null
        val endMsg = GarminMessage()
        for (device in devices) {
            for (app in registeredApps.values) {
                sendMessage(context, device, app, endMsg)
            }
        }
        cache.reset()
        addLog("[SEND] Navigation ended (naviend)")
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
            connectIQ?.getApplicationInfo(appId, device, object : ConnectIQ.IQApplicationInfoListener {
                override fun onApplicationInfoReceived(app: IQApp?) {
                    if (app != null) {
                        registeredApps[appId] = app
                        isAppFound = true
                        val label = "NavigationIQ"
                        addLog("Found $label: ${app.status}")
                        registerAppEvents(device, app)
                    }
                }
                override fun onApplicationNotInstalled(id: String?) {
                    // Normal if only one of the two apps is installed
                }
            })
            registeredApps[appId]?.let { registerAppEvents(device, it) }
        }
    }

    private var currentMapZoom = 16
    private var currentPanDx = 0
    private var currentPanDy = 0

    private fun registerAppEvents(device: IQDevice, app: IQApp) {
        connectIQ?.registerForAppEvents(device, app) { _, _, messages, _ ->
            if (messages.isNullOrEmpty()) return@registerForAppEvents
            lastWatchRxTime = System.currentTimeMillis()
            _isHeartbeatLive.value = true
            _isWatchFound.value = true

            val first = messages[0]
            if (first is List<*> && first.isNotEmpty()) {
                val action = first[0]?.toString()
                when (action) {
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
                }
                return@registerForAppEvents
            }

            val msg = first?.toString() ?: return@registerForAppEvents
            addLog("[RECV from watch] $msg")
            when (msg) {
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
                "map_on" -> {
                    isMapMode = true
                    addLog("[MAP] Activated Map Mode on watch - starting 5s loop")
                    startMapLoop()
                }
                "map_off" -> {
                    isMapMode = false
                    stopMapLoop()
                    addLog("[MAP] Deactivated Map Mode - resuming HUD")
                    latestPendingInfo?.let {
                        appContext?.let { ctx -> sendNavigationInfo(ctx, it) }
                    }
                }
                "map_recenter" -> {
                    currentPanDx = 0
                    currentPanDy = 0
                    addLog("[MAP] Recenter GPS")
                    triggerInstantMapUpdate()
                }
            }
        }
    }

    private var heartbeatJob: Job? = null

    private fun startHeartbeatMonitor() {
        heartbeatJob?.cancel()
        heartbeatJob = mapScope.launch {
            while (isActive) {
                val now = System.currentTimeMillis()
                _isHeartbeatLive.value = (now - lastWatchRxTime < 15_000L && lastWatchRxTime > 0L)
                if (!isMapMode && latestPendingInfo == null && isSdkReady) {
                    sendPing()
                }
                delay(8000L)
            }
        }
    }

    fun sendPing() {
        if (devices.isEmpty()) {
            devices = connectIQ?.knownDevices ?: emptyList()
        }
        val payload = listOf("ping", System.currentTimeMillis())
        for (device in devices) {
            for (app in registeredApps.values) {
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
        appContext?.let { OsmMapManager.initialize(it) }
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
    }

    private fun stopMapLoop() {
        mapJob?.cancel()
        mapJob = null
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
        for (device in devices) {
            for (app in registeredApps.values) {
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

    private var lastPromptTime = 0L

    fun promptOpenWatchApp(device: IQDevice, app: IQApp) {
        val now = System.currentTimeMillis()
        if (now - lastPromptTime < 8_000) return // Throttled to avoid prompt spam
        lastPromptTime = now
        try {
            connectIQ?.openApplication(device, app) { _, _, status ->
                addLog("Prompt watch to open app: $status")
            }
        } catch (e: Exception) {
            Log.e(TAG, "openApplication exception: ${e.message}")
        }
    }

    private fun sendMessage(context: Context, device: IQDevice, app: IQApp, message: GarminMessage, onComplete: (() -> Unit)? = null) {
        try {
            connectIQ?.sendMessage(device, app, message.toDataPayload()) { _, _, status ->
                if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                    failedCount = 0
                } else {
                    failedCount++
                    addLog("[FAIL] Send to ${app.applicationId.take(8)}...: $status")
                    // If watch app is not opened yet, trigger Garmin system prompt to open app
                    promptOpenWatchApp(device, app)
                    if (failedCount >= 10) {
                        addLog("[WARN] Consecutive failures – restarting connection")
                        failedCount = 0
                        restartConnection(context)
                    }
                }
                onComplete?.invoke()
            }
        } catch (e: Exception) {
            addLog("[ERR] sendMessage: ${e.message}")
            Log.e(TAG, "sendMessage: ${e.message}")
            onComplete?.invoke()
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
