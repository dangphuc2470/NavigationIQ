package com.phucdnh.navigationiq.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.phucdnh.navigationiq.MainActivity
import com.phucdnh.navigationiq.R
import com.phucdnh.navigationiq.garmin.BluetoothStateReceiver
import com.phucdnh.navigationiq.garmin.GarminManager
import com.phucdnh.navigationiq.map.OsmMapManager
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
        private const val NOTIFICATION_CHANNEL_ID = "navigation_iq_service_channel"
        private const val NOTIFICATION_ID = 2470

        const val ACTION_STOP_NAVIGATION = "com.phucdnh.navigationiq.action.STOP_NAVIGATION"
        const val ACTION_EXIT_APP = "com.phucdnh.navigationiq.action.EXIT_APP"

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

        createNotificationChannel()

        // Register Bluetooth state receiver to auto-reconnect Garmin after BT toggle
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        registerReceiver(btReceiver, filter)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_NAVIGATION -> {
                Log.i(TAG, "ACTION_STOP_NAVIGATION received")
                GarminManager.addLog("[ACTION] Navigation ended from notification")
                startDuration = ""
                _currentNavigationInfo.value = null
                OsmMapManager.stopLocationUpdates()
                GarminManager.sendNavigationEnd(this)
                updateStatusNotification(null, false)
            }
            ACTION_EXIT_APP -> {
                Log.i(TAG, "ACTION_EXIT_APP received")
                GarminManager.addLog("[ACTION] App exited from notification")
                startDuration = ""
                _currentNavigationInfo.value = null
                OsmMapManager.stopLocationUpdates()
                GarminManager.sendNavigationEnd(this)
                try {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } catch (_: Exception) {}
                val notifManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                notifManager?.cancel(NOTIFICATION_ID)
                stopSelf()
                // Terminate process completely to free all RAM/battery
                android.os.Process.killProcess(android.os.Process.myPid())
            }
        }
        return super.onStartCommand(intent, flags, startId)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "NavNotificationService connected")
        isConnected = true

        // Initialize (or re-use) the Garmin SDK on listener connect
        GarminManager.initSdk(this)
        updateStatusNotification(null, false)

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
        try {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } catch (e: Exception) {
            // Ignore
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        // 1. Navigation notification handling (Google Maps, OsmAnd)
        if (pkg == GOOGLE_MAPS_PACKAGE || pkg == OSMAND_PACKAGE || pkg.contains("map", ignoreCase = true)) {
            val notif = sbn.notification
            val extras = notif?.extras
            val rawTitle = extras?.getCharSequence("android.title")?.toString() ?: ""
            val rawText = extras?.getCharSequence("android.text")?.toString() ?: ""
            val rawSubText = extras?.getCharSequence("android.subText")?.toString() ?: ""
            GarminManager.addLog("[MAPS POST] title=\"$rawTitle\" | text=\"$rawText\" | sub=\"$rawSubText\"")

            serviceScope.launch {
                try {
                    val parsedValues = NotificationParser.parse(this@NavNotificationService, sbn)
                    val navInfo = GoogleMapsParser.parse(this@NavNotificationService, parsedValues)

                    if (navInfo != null) {
                        GarminManager.addLog("[MAPS PARSED] signs=\"${navInfo.signs}\" | dist=\"${navInfo.distance}\" | eta=\"${navInfo.eta}\" | arrived=${navInfo.isArrived()} | hasDir=${navInfo.hasDirections()}")
                    } else {
                        GarminManager.addLog("[MAPS PARSE] parseCar/PT returned null")
                    }

                    if (navInfo != null && navInfo.hasDirections()) {
                        if (startDuration.isEmpty()) {
                            startDuration = navInfo.duration
                        }
                        if (!navInfo.setProgress(this@NavNotificationService, startDuration)) {
                            startDuration = navInfo.duration
                        }

                        _currentNavigationInfo.value = navInfo
                        updateStatusNotification(navInfo, true)
                        GarminManager.sendNavigationInfo(this@NavNotificationService, navInfo)
                        Log.d(TAG, "Dispatched nav update: ${navInfo.distance} -> ${navInfo.signs} (ETA: ${navInfo.eta})")
                    }
                } catch (e: Exception) {
                    GarminManager.addLog("[MAPS ERROR] ${e.message}")
                    Log.e(TAG, "Error in onNotificationPosted: ${e.message}")
                }
            }
            return
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (pkg == GOOGLE_MAPS_PACKAGE || pkg == OSMAND_PACKAGE) {
            val lastInfo = _currentNavigationInfo.value
            val lastSigns = lastInfo?.signs ?: ""
            val lastDist = lastInfo?.distance ?: ""
            val lastArrived = lastInfo?.isArrived() ?: false
            val isNear = lastInfo?.isNearDestination() ?: false
            GarminManager.addLog("[MAPS REMOVED] id=${sbn.id} | lastSigns=\"$lastSigns\" | lastDist=\"$lastDist\" | nearDest=$isNear | arrived=$lastArrived")

            // SMART ARRIVAL FALLBACK:
            // If user was near destination (e.g. ETA <= 2m, dist <= 150m, foreign language, or arrived)
            // before notification was dismissed, dispatch Arrival to Garmin watch so the Reached screen is shown!
            if (isNear && lastInfo != null) {
                GarminManager.addLog("[SMART ARRIVAL] Fallback triggered! Near destination (dist=$lastDist, eta=${lastInfo.eta}). Dispatching Arrived screen.")
                val arrivalSigns = when {
                    lastArrived -> lastSigns
                    lastSigns.isNotBlank() -> "Arrived · $lastSigns"
                    else -> "Arrived"
                }
                val arrivalInfo = lastInfo.copy(
                    distance = "0 m",
                    signs = arrivalSigns
                )
                _currentNavigationInfo.value = arrivalInfo
                GarminManager.sendNavigationInfo(this, arrivalInfo)
                startDuration = ""
                OsmMapManager.stopLocationUpdates()
                updateStatusNotification(null, false)
                return
            }

            Log.i(TAG, "Navigation notification removed, sending end signal")
            startDuration = ""
            _currentNavigationInfo.value = null
            OsmMapManager.stopLocationUpdates()
            GarminManager.sendNavigationEnd(this)
            updateStatusNotification(null, false)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isConnected = false
        unregisterReceiver(btReceiver)
        OsmMapManager.stopLocationUpdates()
        Log.i(TAG, "NavNotificationService destroyed")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Navigation IQ Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Maintains background connection and syncs navigation with Garmin watch"
                setShowBadge(false)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun updateStatusNotification(navInfo: NavigationInfo?, isNavigating: Boolean) {
        try {
            val isVi = java.util.Locale.getDefault().language == "vi"

            val contentIntent = PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val pStopNav = PendingIntent.getService(
                this,
                101,
                Intent(this, NavNotificationService::class.java).apply { action = ACTION_STOP_NAVIGATION },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val pExitApp = PendingIntent.getService(
                this,
                102,
                Intent(this, NavNotificationService::class.java).apply { action = ACTION_EXIT_APP },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val title = if (isNavigating && navInfo != null) {
                "Navigation IQ: ${navInfo.signs}"
            } else {
                "Navigation IQ"
            }

            val text = if (isNavigating && navInfo != null) {
                "${navInfo.distance} • ETA ${navInfo.eta}"
            } else {
                if (isVi) "Đang chạy nền • Sẵn sàng kết nối Garmin" else "Running in background • Ready for Garmin"
            }

            val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(contentIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(if (isNavigating) NotificationCompat.CATEGORY_NAVIGATION else NotificationCompat.CATEGORY_SERVICE)
                .setOnlyAlertOnce(true)

            if (isNavigating) {
                builder.addAction(0, if (isVi) "Dừng chỉ đường" else "End Route", pStopNav)
            }
            builder.addAction(0, if (isVi) "Thoát app" else "Exit App", pExitApp)

            val notification = builder.build()

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val fgsType = ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                try {
                    startForeground(NOTIFICATION_ID, notification, fgsType)
                } catch (e: Exception) {
                    Log.w(TAG, "startForeground with types failed, fallback: ${e.message}")
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update status notification: ${e.message}")
        }
    }
}
