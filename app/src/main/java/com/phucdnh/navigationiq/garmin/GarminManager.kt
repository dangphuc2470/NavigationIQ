package com.phucdnh.navigationiq.garmin

import android.bluetooth.BluetoothManager
import android.content.Context
import android.util.Log
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import com.garmin.android.connectiq.adb.AdbConnection
import com.phucdnh.navigationiq.model.NavigationInfo
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Singleton managing Garmin ConnectIQ lifecycle, device discovery and message transmission.
 * Supports both the original HeadUpNav watch app and the custom NavigationIQ watch app.
 */
object GarminManager {

    private const val TAG = "GarminManager"

    // Supported Watch App IDs:
    // 1. Original HeadUpNav watch app on Garmin IQ Store
    const val HEADUPNAV_APP_ID = "37618bc537a04c81b2ebef246f9da6f7"
    // 2. Custom NavigationIQ watch app
    const val NAVIQ_APP_ID     = "e24767ea-b254-4f25-9391-ff4c409a037c"

    val SUPPORTED_APP_IDS = listOf(
        NAVIQ_APP_ID
    )

    // Max log entries shown in UI
    private const val MAX_LOGS = 50

    // -------------------------------------------------------------------------
    // Observable state for UI
    private val _isWatchFound = MutableStateFlow(false)
    val isWatchFoundFlow = _isWatchFound.asStateFlow()

    private val _watchName = MutableStateFlow<String?>(null)
    val watchNameFlow = _watchName.asStateFlow()

    private val _sentCount = MutableStateFlow(0)
    val sentCountFlow = _sentCount.asStateFlow()

    /** Ring-buffer of recent log lines: "[HH:mm:ss] message" */
    private val _logs = MutableStateFlow<List<String>>(emptyList())
    val logsFlow = _logs.asStateFlow()

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

    /** Init SDK. Safe to call multiple times – skips if already ready. */
    @Synchronized
    fun initSdk(context: Context, onReady: (() -> Unit)? = null) {
        if (isSdkReady) {
            loadDevices(context)
            onReady?.invoke()
            return
        }
        _disposeSdk(context)
        try {
            connectIQ = ConnectIQ.getInstance(context, ConnectIQ.IQConnectType.TETHERED).apply {
                initialize(context, false, object : ConnectIQ.ConnectIQListener {
                    override fun onSdkReady() {
                        addLog("Garmin SDK ready (TETHERED)")
                        isSdkReady = true
                        loadDevices(context)
                        onReady?.invoke()
                    }
                    override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus) {
                        addLog("SDK init error: $status")
                        isSdkReady = false
                    }
                    override fun onSdkShutDown() {
                        addLog("SDK shut down")
                        isSdkReady = false
                        _isWatchFound.value = false
                    }
                })
            }
        } catch (e: Exception) {
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

    fun sendNavigationInfo(context: Context, info: NavigationInfo) {
        if (!isSdkReady) {
            initSdk(context) { sendNavigationInfo(context, info) }
            return
        }

        // Refresh devices list if empty
        if (devices.isEmpty()) {
            val ciq = connectIQ
            if (ciq != null) {
                devices = ciq.knownDevices ?: emptyList()
            }
        }

        if (devices.isEmpty()) {
            addLog("[WARN] No Garmin device found to send to")
            return
        }

        val message = GarminMessage(context, info, cache)
        if (message.isEmpty()) return

        for (device in devices) {
            for (app in registeredApps.values) {
                sendMessage(context, device, app, message)
            }
        }
        _sentCount.value++
        addLog("[SEND #${_sentCount.value}] ${info.distance} | ${info.signs} | ETA: ${info.eta}")
    }

    fun sendNavigationEnd(context: Context) {
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
                        val label = if (appId == HEADUPNAV_APP_ID) "HeadUpNav (Store)" else "NavIQ (Custom)"
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

    private fun registerAppEvents(device: IQDevice, app: IQApp) {
        connectIQ?.registerForAppEvents(device, app) { _, _, messages, _ ->
            if (messages.isNullOrEmpty()) return@registerForAppEvents
            val msg = messages[0]?.toString() ?: return@registerForAppEvents
            addLog("[RECV from watch] $msg")
            when (msg) {
                "reset", "alive" -> {
                    cache.reset()
                    isWatchAppAlive = true
                    _isWatchFound.value = true
                }
                "resetimage" -> {
                    cache.sendBitmap = true
                    isWatchAppAlive = true
                }
                "dead" -> isWatchAppAlive = false
            }
        }
    }

    private fun sendMessage(context: Context, device: IQDevice, app: IQApp, message: GarminMessage) {
        try {
            connectIQ?.sendMessage(device, app, message.toDataPayload()) { _, _, status ->
                if (status == ConnectIQ.IQMessageStatus.SUCCESS) {
                    failedCount = 0
                } else {
                    failedCount++
                    addLog("[FAIL] Send to ${app.applicationId.take(8)}...: $status")
                    if (failedCount >= 10) {
                        addLog("[WARN] Consecutive failures – restarting connection")
                        failedCount = 0
                        restartConnection(context)
                    }
                }
            }
        } catch (e: Exception) {
            addLog("[ERR] sendMessage: ${e.message}")
            Log.e(TAG, "sendMessage: ${e.message}")
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
