package com.phucdnh.navigationiq.service

import android.Manifest
import android.app.ActivityOptions
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.PowerManager
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
import kotlinx.coroutines.isActive
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

        private val _lastTripSummary = MutableStateFlow<com.phucdnh.navigationiq.model.TripSummary?>(null)
        val lastTripSummary = _lastTripSummary.asStateFlow()
        val lastTripSummaryFlow get() = lastTripSummary

        fun setSimulatedTripSummary(summary: com.phucdnh.navigationiq.model.TripSummary?) {
            _lastTripSummary.value = summary
        }

        var instance: NavNotificationService? = null
            private set

        fun triggerNextStop(): Boolean {
            return instance?.performNextStop() ?: false
        }
    }

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private var startDuration: String = ""
    private var tripStartTimeMs: Long = 0L
    private var tripStartLength: String = ""
    private var maxTripDistanceMeters: Int = 0
    private var lastKnownDestination: String = ""
    private var lastKnownStreet: String = ""
    private var lastValidNavInfo: NavigationInfo? = null
    private var hasDispatchedArrival: Boolean = false
    private var totalDistanceMeters: Double = 0.0
    private var lastGpsLocation: Location? = null
    private var isTrackingGps: Boolean = false
    private var locationManager: LocationManager? = null
    private var latestResumeIntent: PendingIntent? = null
    private var autoResumeJob: kotlinx.coroutines.Job? = null
    private var hasWaypointAhead: Boolean = false

    private fun stripAccents(str: String): String {
        val n = java.text.Normalizer.normalize(str, java.text.Normalizer.Form.NFD)
        return n.replace(Regex("\\p{InCombiningDiacriticalMarks}+"), "")
            .replace('đ', 'd')
            .replace('Đ', 'D')
    }

    private fun isResumeNavigationNotification(sbn: StatusBarNotification): Boolean {
        // 1. Check known Google Maps Waypoint Notification ID / Tag
        if (sbn.id == 1554 || sbn.tag == "yev") {
            return true
        }

        val notif = sbn.notification ?: return false
        val extras = notif.extras
        val rawTitle = extras?.getCharSequence("android.title")?.toString() ?: ""
        val rawText = extras?.getCharSequence("android.text")?.toString() ?: ""
        val rawSubText = extras?.getCharSequence("android.subText")?.toString() ?: ""

        val combined = "$rawTitle $rawText $rawSubText".lowercase().trim()
        val unaccented = stripAccents(combined)

        val resumeKeywords = listOf(
            "resume", "tiep tuc", "tiếp tục", "next stop", "chặng tiếp theo", "chang tiep theo",
            "chặng kế", "chang ke", "điểm dừng", "diem dung", "điểm dừng chân", "diem dung chan",
            "trạm dừng", "tram dung", "tiếp tục chuyển hướng", "tiếp tục điều hướng",
            "tiep tuc chuyen huong", "tiep tuc dieu huong"
        )

        if (resumeKeywords.any { combined.contains(it) || unaccented.contains(it) }) {
            return true
        }

        // 2. Check Action Buttons (e.g. "Tiếp tục" / "Tiếp tục đi" / "Resume")
        notif.actions?.forEach { action ->
            val at = action.title?.toString()?.lowercase()?.trim() ?: ""
            if (at.isNotEmpty()) {
                val atUnaccented = stripAccents(at)
                if (resumeKeywords.any { at.contains(it) || atUnaccented.contains(it) }) {
                    return true
                }
            }
        }

        return false
    }

    private fun isIntermediateStopNotification(sbn: StatusBarNotification, navInfo: NavigationInfo?): Boolean {
        if (sbn.id == 1554 || sbn.tag == "yev") return true
        val notif = sbn.notification ?: return false
        val extras = notif.extras
        val rawTitle = extras?.getCharSequence("android.title")?.toString() ?: ""
        val rawText = extras?.getCharSequence("android.text")?.toString() ?: ""
        val rawSubText = extras?.getCharSequence("android.subText")?.toString() ?: ""
        val combined = "$rawTitle $rawText $rawSubText".lowercase().trim()
        val unaccented = stripAccents(combined)

        val waypointKeywords = listOf(
            "diem dung", "điểm dừng", "tram dung", "trạm dừng",
            "next stop", "chặng tiếp theo", "chang tiep theo",
            "chặng kế", "chang ke", "tiep tuc", "tiếp tục", "resume"
        )
        if (waypointKeywords.any { combined.contains(it) || unaccented.contains(it) }) {
            return true
        }

        notif.actions?.forEach { action ->
            val at = action.title?.toString()?.lowercase()?.trim() ?: ""
            if (at.isNotEmpty()) {
                val atUnaccented = stripAccents(at)
                val actionKeywords = listOf(
                    "skip", "bo qua", "bỏ qua", "stop",
                    "diem dung", "điểm dừng", "tram dung", "trạm dừng",
                    "tiep tuc", "tiếp tục", "resume", "next"
                )
                if (actionKeywords.any { at.contains(it) || atUnaccented.contains(it) }) {
                    return true
                }
            }
        }

        if (hasWaypointAhead) {
            return true
        }

        return false
    }

    private fun wakeScreenBriefly(durationMs: Long = 5000L) {
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
            if (!pm.isInteractive) {
                GarminManager.addLog("[WAKE] Màn hình đang tắt -> Bật sáng màn hình ${durationMs / 1000}s để Google Maps tiếp tục chặng...")
                @Suppress("DEPRECATION")
                val wakeLock = pm.newWakeLock(
                    PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
                    "NavigationIQ:WaypointWakeUp"
                )
                wakeLock.acquire(durationMs)
            }
        } catch (e: Exception) {
            Log.w(TAG, "WakeLock error: ${e.message}")
        }
    }

    private fun sendPendingIntentWithBal(intent: PendingIntent): Boolean {
        return try {
            val options = ActivityOptions.makeBasic()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                options.setPendingIntentBackgroundActivityStartMode(
                    ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                )
            }
            intent.send(this, 0, null, null, null, null, options.toBundle())
            true
        } catch (e: Exception) {
            GarminManager.addLog("[NEXT STOP ERROR] Gửi PendingIntent thất bại: ${e.message}")
            false
        }
    }

    fun performNextStop(): Boolean {
        autoResumeJob?.cancel()
        autoResumeJob = null
        hasWaypointAhead = false

        // 1. Đánh thức màn hình sáng lên để Google Maps thoát trạng thái ngủ/Doze
        wakeScreenBriefly(5000L)

        // 2. Ưu tiên gửi PendingIntent đã lưu kèm quyền BAL (Background Activity Launch)
        val intent = latestResumeIntent
        if (intent != null) {
            GarminManager.addLog("[NEXT STOP] Đang gửi PendingIntent tiếp tục chuyển hướng Google Maps...")
            if (sendPendingIntentWithBal(intent)) {
                latestResumeIntent = null
                return true
            }
        }

        // 3. Quét thông báo đang hoạt động tìm action tiếp tục
        try {
            activeNotifications?.forEach { sbn ->
                if (sbn.packageName == GOOGLE_MAPS_PACKAGE) {
                    val notif = sbn.notification ?: return@forEach
                    if (isResumeNavigationNotification(sbn) || isIntermediateStopNotification(sbn, null)) {
                        GarminManager.addLog("[NEXT STOP] Tìm thấy thông báo trong activeNotifications")
                        val actIntent = notif.actions?.firstOrNull { action ->
                            val at = stripAccents(action.title?.toString()?.lowercase() ?: "")
                            at.contains("tiep tuc") || at.contains("resume") || at.contains("next")
                        }?.actionIntent ?: notif.contentIntent ?: notif.actions?.firstOrNull()?.actionIntent

                        if (actIntent != null && sendPendingIntentWithBal(actIntent)) {
                            GarminManager.addLog("[NEXT STOP] Kích hoạt Action/ContentIntent thành công")
                            return true
                        }
                    }
                }
            }
        } catch (e: Exception) {
            GarminManager.addLog("[NEXT STOP ERROR] Quét activeNotifications thất bại: ${e.message}")
        }

        // 4. Fallback: Đưa Google Maps lên Foreground để kích hoạt tiếp tục chặng
        try {
            val launchIntent = packageManager.getLaunchIntentForPackage(GOOGLE_MAPS_PACKAGE)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                val options = ActivityOptions.makeBasic()
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    options.setPendingIntentBackgroundActivityStartMode(
                        ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED
                    )
                }
                startActivity(launchIntent, options.toBundle())
                GarminManager.addLog("[NEXT STOP] Kích hoạt lại Google Maps qua LaunchIntent")
                return true
            }
        } catch (e: Exception) {
            GarminManager.addLog("[NEXT STOP ERROR] LaunchIntent thất bại: ${e.message}")
        }

        return false
    }

    private val tripLocationListener = object : LocationListener {
        override fun onLocationChanged(location: Location) {
            if (location.hasAccuracy() && location.accuracy > 50f) return
            val lastLoc = lastGpsLocation
            if (lastLoc != null) {
                val dist = lastLoc.distanceTo(location).toDouble()
                // Filter out small jitter (< 1.5m) and allow smooth increments (up to 500m for mock/drive)
                if (dist in 1.5..500.0) {
                    totalDistanceMeters += dist
                    lastGpsLocation = location
                }
            } else {
                lastGpsLocation = location
            }
        }
        override fun onProviderEnabled(provider: String) {}
        override fun onProviderDisabled(provider: String) {}
    }

    private fun startTripDistanceTracking() {
        if (isTrackingGps) return
        try {
            if (checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED ||
                checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
                if (locationManager == null) {
                    locationManager = getSystemService(Context.LOCATION_SERVICE) as? LocationManager
                }
                val lm = locationManager ?: return
                if (lm.isProviderEnabled(LocationManager.PASSIVE_PROVIDER)) {
                    lm.requestLocationUpdates(LocationManager.PASSIVE_PROVIDER, 1000L, 1f, tripLocationListener)
                    isTrackingGps = true
                    GarminManager.addLog("[GPS TRACK] Started PASSIVE tracker for trip distance")
                } else if (lm.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                    lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 2000L, 2f, tripLocationListener)
                    isTrackingGps = true
                    GarminManager.addLog("[GPS TRACK] Started GPS tracker for trip distance")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start trip distance tracking: ${e.message}")
        }
    }

    private fun stopTripDistanceTracking() {
        if (!isTrackingGps) return
        try {
            locationManager?.removeUpdates(tripLocationListener)
            isTrackingGps = false
            lastGpsLocation = null
            GarminManager.addLog("[GPS TRACK] Stopped tracker (total: ${totalDistanceMeters.toInt()}m)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop trip distance tracking: ${e.message}")
        }
    }

    private val btReceiver = BluetoothStateReceiver()

    override fun onCreate() {
        super.onCreate()
        instance = this
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
                stopTripDistanceTracking()
                totalDistanceMeters = 0.0
                maxTripDistanceMeters = 0
                startDuration = ""
                _currentNavigationInfo.value = null
                OsmMapManager.stopLocationUpdates()
                GarminManager.sendNavigationEnd(this)
                updateStatusNotification(null, false)
            }
            ACTION_EXIT_APP -> {
                Log.i(TAG, "ACTION_EXIT_APP received")
                GarminManager.addLog("[ACTION] App exited from notification")
                stopTripDistanceTracking()
                totalDistanceMeters = 0.0
                maxTripDistanceMeters = 0
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
        if (pkg == GOOGLE_MAPS_PACKAGE || pkg == OSMAND_PACKAGE || pkg == "com.google.android.apps.mapslite") {
            val notif = sbn.notification
            val extras = notif?.extras
            val rawTitle = extras?.getCharSequence("android.title")?.toString() ?: ""
            val rawText = extras?.getCharSequence("android.text")?.toString() ?: ""
            val rawSubText = extras?.getCharSequence("android.subText")?.toString() ?: ""
            GarminManager.addLog("[MAPS POST] title=\"$rawTitle\" | text=\"$rawText\" | sub=\"$rawSubText\"")

            // Track whether route has waypoints/intermediate stops ahead
            val notifActions = notif?.actions
            val hasSkipStopAction = notifActions?.any { action ->
                val at = stripAccents(action.title?.toString()?.lowercase() ?: "")
                at.contains("skip") || at.contains("bo qua") || (at.contains("stop") && !at.contains("navigation") && !at.contains("dung chi duong"))
            } ?: false
            val combinedText = "$rawTitle $rawText $rawSubText".lowercase()
            val unaccCombined = stripAccents(combinedText)
            val textHasWaypoint = listOf("diem dung", "tram dung", "next stop", "waypoint").any {
                unaccCombined.contains(it)
            }
            if (hasSkipStopAction || textHasWaypoint) {
                hasWaypointAhead = true
            } else if (notifActions != null && notifActions.isNotEmpty() && !hasSkipStopAction) {
                // If notification has actions but none of them is skip stop, we are on the final destination leg
                hasWaypointAhead = false
            }

            // Check if this is an intermediate stop (waypoint) "Resume navigation" notification
            if (isResumeNavigationNotification(sbn)) {
                latestResumeIntent = notif?.actions?.firstOrNull { action ->
                    val at = stripAccents(action.title?.toString()?.lowercase() ?: "")
                    at.contains("tiep tuc") || at.contains("resume") || at.contains("next")
                }?.actionIntent ?: notif?.contentIntent ?: notif?.actions?.firstOrNull()?.actionIntent

                val destName = rawText.substringBefore("•").trim().ifEmpty { rawTitle.ifEmpty { "Điểm dừng tiếp theo" } }
                wakeScreenBriefly(5000L)
                GarminManager.addLog("[WAYPOINT] Điểm dừng trung gian: \"$rawTitle\" -> \"$destName\" (Đã bật sáng màn hình)")
                GarminManager.addLog("[WAYPOINT] Tự động đi tiếp sau 7 giây, hoặc bấm nút trên đồng hồ...")

                if (!hasDispatchedArrival) {
                    hasDispatchedArrival = true
                    dispatchArrivalSummary(destName, isIntermediate = true)
                }

                autoResumeJob?.cancel()
                autoResumeJob = serviceScope.launch {
                    kotlinx.coroutines.delay(7000L)
                    if (isActive) {
                        GarminManager.addLog("[AUTO-RESUME] Đã hết 7s -> Tự động kích hoạt Google Maps đi tiếp chặng sau!")
                        performNextStop()
                    }
                }
                return
            }

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
                        if (tripStartTimeMs == 0L) {
                            tripStartTimeMs = System.currentTimeMillis()
                            totalDistanceMeters = 0.0
                            lastGpsLocation = null
                            maxTripDistanceMeters = 0
                        }
                        if (tripStartLength.isEmpty() && navInfo.length.isNotEmpty() && navInfo.length != "-") {
                            tripStartLength = navInfo.length
                        }
                        val currentMeters = navInfo.getLengthMeters()
                        if (currentMeters > 0 && currentMeters > maxTripDistanceMeters) {
                            maxTripDistanceMeters = currentMeters
                        }
                        lastValidNavInfo = navInfo

                        // Extract destination / house number / street name
                        val rawSigns = navInfo.signs.trim()
                        if (rawSigns.isNotEmpty()) {
                            val lowerSigns = rawSigns.lowercase()
                            if (navInfo.isArrived() ||
                                lowerSigns.contains("điểm đến") || lowerSigns.contains("destination") ||
                                lowerSigns.contains("bạn đã đến") || lowerSigns.contains("you have arrived") ||
                                lowerSigns.contains("arrived at") || lowerSigns.contains("arriving")) {
                                lastKnownDestination = rawSigns
                            } else {
                                lastKnownStreet = rawSigns
                                if (rawSigns.matches(Regex(".*\\b\\d+.*"))) {
                                    lastKnownDestination = rawSigns
                                }
                            }
                        }

                        if (navInfo.isArrived()) {
                            stopTripDistanceTracking()
                            val finalDest = lastKnownDestination.ifEmpty {
                                lastKnownStreet.ifEmpty {
                                    rawSigns.ifEmpty { "Điểm đến" }
                                }
                            }
                            val isIntermediate = isIntermediateStopNotification(sbn, navInfo)
                            if (isIntermediate) {
                                latestResumeIntent = notif?.actions?.firstOrNull { action ->
                                    val at = stripAccents(action.title?.toString()?.lowercase() ?: "")
                                    at.contains("tiep tuc") || at.contains("resume") || at.contains("next")
                                }?.actionIntent ?: notif?.contentIntent ?: notif?.actions?.firstOrNull()?.actionIntent

                                wakeScreenBriefly(5000L)
                                GarminManager.addLog("[WAYPOINT] Đến trạm dừng: \"$finalDest\" -> Sáng màn hình 5s, tự động đi tiếp sau 7s...")

                                autoResumeJob?.cancel()
                                autoResumeJob = serviceScope.launch {
                                    kotlinx.coroutines.delay(7000L)
                                    if (isActive) {
                                        GarminManager.addLog("[AUTO-RESUME] Đã hết 7s -> Tự động kích hoạt Google Maps đi tiếp chặng sau!")
                                        performNextStop()
                                    }
                                }
                            }
                            if (!hasDispatchedArrival) {
                                hasDispatchedArrival = true
                                dispatchArrivalSummary(finalDest, isIntermediate = isIntermediate)
                            }
                            _currentNavigationInfo.value = navInfo
                            updateStatusNotification(navInfo, true)
                        } else {
                            hasDispatchedArrival = false
                            startTripDistanceTracking()
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
                    }
                } catch (e: Exception) {
                    GarminManager.addLog("[MAPS ERROR] ${e.message}")
                    Log.e(TAG, "Error in onNotificationPosted: ${e.message}")
                }
            }
            return
        }
    }

    private fun dispatchArrivalSummary(finalDest: String, isIntermediate: Boolean = false) {
        stopTripDistanceTracking()
        val now = System.currentTimeMillis()
        val durationMs = if (tripStartTimeMs > 0L) (now - tripStartTimeMs) else 0L
        val durationMin = (durationMs / 60000).toInt()
        val durationStr = if (durationMin >= 60) {
            "${durationMin / 60}h ${durationMin % 60}m"
        } else {
            "${if (durationMin < 1) 1 else durationMin}m"
        }

        val distanceStr: String
        val avgSpeedStr: String

        if (isIntermediate) {
            // Intermediate stop (waypoint): User requested NOT to show distance and speed (set to "--")
            distanceStr = "--"
            avgSpeedStr = "--"
            GarminManager.addLog("[WAYPOINT ARRIVAL] Điểm dừng trung gian: $finalDest -> ẩn khoảng cách và vận tốc (-- / -)")
        } else {
            // Determine the most reliable trip distance in meters:
            // Priority 1: If GPS actively recorded distance >= 70% of Maps, use the larger value
            // Priority 2: If GPS recorded actual travel distance (>= 50m), use totalDistanceMeters
            // Priority 3: Fallback to Maps maxTripDistanceMeters or last valid length
            val effectiveMeters: Double = when {
                maxTripDistanceMeters > 0 && totalDistanceMeters >= maxTripDistanceMeters * 0.7 -> {
                    maxOf(totalDistanceMeters, maxTripDistanceMeters.toDouble())
                }
                totalDistanceMeters >= 50.0 -> {
                    totalDistanceMeters
                }
                maxTripDistanceMeters > 0 -> {
                    maxTripDistanceMeters.toDouble()
                }
                else -> {
                    val fallbackMeters = lastValidNavInfo?.getLengthMeters() ?: -1
                    if (fallbackMeters > 0) fallbackMeters.toDouble() else 0.0
                }
            }

            distanceStr = when {
                effectiveMeters >= 1000.0 -> {
                    String.format(java.util.Locale.US, "%.1f km", effectiveMeters / 1000.0)
                }
                effectiveMeters > 0.0 -> {
                    "${effectiveMeters.toInt()} m"
                }
                tripStartLength.isNotEmpty() -> tripStartLength
                else -> {
                    lastValidNavInfo?.length?.takeIf { it.isNotEmpty() && it != "-" } ?: "--"
                }
            }

            val distanceKm = effectiveMeters / 1000.0
            val durationSec = durationMs / 1000.0
            val hours = durationSec / 3600.0
            val rawAvgSpeed = if (hours > 0.0 && durationSec >= 15.0 && distanceKm >= 0.05) {
                Math.round(distanceKm / hours).toInt()
            } else 0
            avgSpeedStr = if (rawAvgSpeed in 1..180) "$rawAvgSpeed km/h" else "--"
        }

        val timeFormat = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault())
        val startTimeStr = if (tripStartTimeMs > 0L) timeFormat.format(java.util.Date(tripStartTimeMs)) else ""
        val endTimeStr = timeFormat.format(java.util.Date(now))

        val summary = com.phucdnh.navigationiq.model.TripSummary(
            destination = finalDest,
            duration = durationStr,
            distance = distanceStr,
            avgSpeed = avgSpeedStr,
            startTime = startTimeStr,
            endTime = endTimeStr
        )
        _lastTripSummary.value = summary
        GarminManager.sendNavigationArrived(this, summary)
        GarminManager.addLog("[ARRIVED] Dispatched to Garmin: $finalDest ($durationStr, $distanceStr, $avgSpeedStr, isIntermediate=$isIntermediate)")
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (pkg == GOOGLE_MAPS_PACKAGE || pkg == OSMAND_PACKAGE) {
            if (sbn.id == 1554 || sbn.tag == "yev") {
                GarminManager.addLog("[MAPS REMOVED] Resume notification removed (id=${sbn.id}) -> Chặng mới tiếp tục")
                return
            }

            val lastInfo = _currentNavigationInfo.value ?: lastValidNavInfo
            val lastSigns = lastInfo?.signs ?: ""
            val lastDist = lastInfo?.distance ?: ""
            val lastArrived = lastInfo?.isArrived() ?: false
            val isNear = lastInfo?.isNearDestination() ?: false
            GarminManager.addLog("[MAPS REMOVED] id=${sbn.id} | lastSigns=\"$lastSigns\" | lastDist=\"$lastDist\" | nearDest=$isNear | arrived=$lastArrived")

            // SMART ARRIVAL FALLBACK:
            // If user was near destination (e.g. ETA <= 2m, dist <= 150m, foreign language, or arrived)
            // before notification was dismissed, dispatch Arrival + TripSummary to Garmin watch!
            val shouldDispatchArrival = isNear || lastArrived
            if (shouldDispatchArrival) {
                if (!hasDispatchedArrival) {
                    GarminManager.addLog("[SMART ARRIVAL] Fallback triggered! Near destination (dist=$lastDist, eta=${lastInfo?.eta}). Dispatching Arrived screen.")
                    val finalDest = lastKnownDestination.ifEmpty {
                        lastKnownStreet.ifEmpty {
                            lastInfo?.signs?.ifEmpty { "Điểm đến" } ?: "Điểm đến"
                        }
                    }
                    val isIntermediate = isIntermediateStopNotification(sbn, lastInfo) || hasWaypointAhead
                    dispatchArrivalSummary(finalDest, isIntermediate = isIntermediate)
                }
            } else {
                Log.i(TAG, "Navigation notification removed, sending end signal")
                GarminManager.sendNavigationEnd(this)
            }

            stopTripDistanceTracking()
            hasDispatchedArrival = false
            totalDistanceMeters = 0.0
            maxTripDistanceMeters = 0
            tripStartTimeMs = 0L
            tripStartLength = ""
            lastKnownDestination = ""
            lastKnownStreet = ""
            lastValidNavInfo = null
            startDuration = ""
            _currentNavigationInfo.value = null
            OsmMapManager.stopLocationUpdates()
            updateStatusNotification(null, false)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        autoResumeJob?.cancel()
        autoResumeJob = null
        if (instance == this) instance = null
        isConnected = false
        stopTripDistanceTracking()
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
                    try {
                        startForeground(NOTIFICATION_ID, notification)
                    } catch (e2: Exception) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                        nm?.notify(NOTIFICATION_ID, notification)
                    }
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update status notification: ${e.message}")
        }
    }
}
