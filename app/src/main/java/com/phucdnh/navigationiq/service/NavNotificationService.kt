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
                        updateStatusNotification(navInfo, true)
                        GarminManager.sendNavigationInfo(this@NavNotificationService, navInfo)
                        Log.d(TAG, "Dispatched nav update: ${navInfo.distance} -> ${navInfo.signs} (ETA: ${navInfo.eta})")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error in onNotificationPosted: ${e.message}")
                }
            }
            return
        }

        // 2. Incoming messaging notification (Zalo, Messenger, SMS...) while navigation is active
        if (_currentNavigationInfo.value != null) {
            handleMessagingNotification(sbn)
        }
    }

    private fun handleMessagingNotification(sbn: StatusBarNotification) {
        val pkg = sbn.packageName ?: return
        val notif = sbn.notification ?: return

        val isMessageCategory = notif.category == android.app.Notification.CATEGORY_MESSAGE
        val isChatApp = when (pkg) {
            "com.zing.zalo",
            "com.facebook.orca", "com.facebook.mlite",
            "org.telegram.messenger",
            "com.whatsapp",
            "com.google.android.apps.messaging", "com.samsung.android.messaging",
            "jp.naver.line.android", "com.viber.voip",
            "com.skype.raider", "com.microsoft.teams" -> true
            else -> false
        }

        if (!isMessageCategory && !isChatApp) {
            return
        }

        val extras = notif.extras ?: return
        val sender = extras.getCharSequence(android.app.Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        val message = extras.getCharSequence(android.app.Notification.EXTRA_TEXT)?.toString()?.trim()
            ?: extras.getCharSequence(android.app.Notification.EXTRA_BIG_TEXT)?.toString()?.trim()
            ?: ""

        if (sender.isEmpty() && message.isEmpty()) {
            return
        }

        val appName = when (pkg) {
            "com.zing.zalo" -> "Zalo"
            "com.facebook.orca", "com.facebook.mlite" -> "Messenger"
            "org.telegram.messenger" -> "Telegram"
            "com.whatsapp" -> "WhatsApp"
            "com.google.android.apps.messaging", "com.samsung.android.messaging" -> "SMS"
            "jp.naver.line.android" -> "Line"
            "com.viber.voip" -> "Viber"
            else -> try {
                packageManager.getApplicationLabel(packageManager.getApplicationInfo(pkg, 0)).toString()
            } catch (e: Exception) {
                "Chat"
            }
        }

        Log.d(TAG, "Forwarding chat message as watch banner: [$appName] $sender: $message")
        GarminManager.sendToastNotification(appName, sender, message, durationSec = 5)
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (pkg == GOOGLE_MAPS_PACKAGE || pkg == OSMAND_PACKAGE) {
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
            val contentIntent = PendingIntent.getActivity(
                this,
                0,
                Intent(this, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
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
                "Ready to connect and sync with Garmin watch"
            }

            val builder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(text)
                .setContentIntent(contentIntent)
                .setOngoing(isNavigating)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(if (isNavigating) NotificationCompat.CATEGORY_NAVIGATION else NotificationCompat.CATEGORY_SERVICE)
                .setOnlyAlertOnce(true)

            val notification = builder.build()

            if (isNavigating) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    val fgsType = ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE or ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION
                    try {
                        startForeground(NOTIFICATION_ID, notification, fgsType)
                    } catch (e: Exception) {
                        Log.w(TAG, "startForeground with types failed, fallback: ${e.message}")
                        startForeground(NOTIFICATION_ID, notification)
                    }
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } else {
                try {
                    stopForeground(STOP_FOREGROUND_DETACH)
                } catch (e: Exception) {
                    // Ignore
                }
                NotificationManagerCompat.from(this).notify(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update status notification: ${e.message}")
        }
    }
}
