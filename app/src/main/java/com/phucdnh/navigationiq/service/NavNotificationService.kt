package com.phucdnh.navigationiq.service

import android.bluetooth.BluetoothAdapter
import android.content.IntentFilter
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.phucdnh.navigationiq.garmin.BluetoothStateReceiver
import com.phucdnh.navigationiq.garmin.GarminManager
import com.phucdnh.navigationiq.model.NavigationInfo
import com.phucdnh.navigationiq.parser.GoogleMapsParser
import com.phucdnh.navigationiq.parser.NotificationParser
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * Foreground NotificationListenerService capturing Google Maps navigation events.
 * Directly ported from HeadUpNav com.navigationparser.lib.NotificationService.
 */
class NavNotificationService : NotificationListenerService() {

    companion object {
        private const val TAG = "NavNotificationService"
        const val GOOGLE_MAPS_PACKAGE = "com.google.android.apps.maps"
        const val OSMAND_PACKAGE = "net.osmand"

        var isConnected: Boolean = false
            private set

        private val _currentNavigationInfo = MutableStateFlow<NavigationInfo?>(null)
        val currentNavigationInfo = _currentNavigationInfo.asStateFlow()
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var startDuration: String = ""
    private val btReceiver = BluetoothStateReceiver()

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "NavNotificationService created")

        // Register Bluetooth state receiver to auto-reconnect Garmin after BT toggle
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        registerReceiver(btReceiver, filter)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "NavNotificationService connected")
        isConnected = true

        // Initialize (or re-use) the Garmin SDK on listener connect
        GarminManager.initSdk(this)

        try {
            activeNotifications?.forEach { sbn -> onNotificationPosted(sbn) }
        } catch (e: Exception) {
            Log.e(TAG, "Error iterating active notifications: ${e.message}")
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.i(TAG, "NavNotificationService disconnected")
        isConnected = false
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (pkg != GOOGLE_MAPS_PACKAGE && pkg != OSMAND_PACKAGE && !pkg.contains("map", ignoreCase = true)) {
            return
        }

        serviceScope.launch {
            try {
                val parsedValues = NotificationParser.parse(this@NavNotificationService, sbn)
                val navInfo = GoogleMapsParser.parse(this@NavNotificationService, parsedValues)

                if (navInfo != null && navInfo.hasDirections()) {
                    if (startDuration.isEmpty()) {
                        startDuration = navInfo.duration
                    }
                    if (!navInfo.setProgress(this@NavNotificationService, startDuration)) {
                        startDuration = navInfo.duration
                    }

                    _currentNavigationInfo.value = navInfo
                    GarminManager.sendNavigationInfo(this@NavNotificationService, navInfo)
                    Log.d(TAG, "Dispatched nav update: ${navInfo.distance} -> ${navInfo.signs} (ETA: ${navInfo.eta})")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in onNotificationPosted: ${e.message}")
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (pkg == GOOGLE_MAPS_PACKAGE || pkg == OSMAND_PACKAGE) {
            Log.i(TAG, "Navigation notification removed, sending end signal")
            startDuration = ""
            _currentNavigationInfo.value = null
            GarminManager.sendNavigationEnd(this)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isConnected = false
        unregisterReceiver(btReceiver)
        Log.i(TAG, "NavNotificationService destroyed")
    }
}
