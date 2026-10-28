import Toybox.Application;
import Toybox.Communications;
import Toybox.Attention;
import Toybox.ActivityRecording;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

// Direction constants
const DIR_UNKNOWN          = 0;
const DIR_STRAIGHT         = 1;
const DIR_LEFT             = 2;
const DIR_RIGHT            = 3;
const DIR_UTURN            = 4;
const DIR_SLIGHT_LEFT      = 5;
const DIR_SLIGHT_RIGHT     = 6;
const DIR_SHARP_LEFT       = 7;
const DIR_SHARP_RIGHT      = 8;
const DIR_ROUNDABOUT_1     = 9;  // Roundabout 1st exit (45 deg slight right)
const DIR_ROUNDABOUT_2     = 10; // Roundabout 2nd exit (90 deg right)
const DIR_ROUNDABOUT_3     = 11; // Roundabout 3rd exit (0 deg straight)
const DIR_ROUNDABOUT_4     = 12; // Roundabout 4th exit (270 deg left)
const DIR_ROUNDABOUT_5     = 13; // Roundabout 5th exit (225 deg sharp left)
const DIR_ARRIVED          = 14; // Reached destination

// Haptic alert distance thresholds (meters)
const HAPTIC_ALERT_FAR  = 100; // First warning tick
const HAPTIC_ALERT_NEAR = 30;  // Urgent turn tick

module CommManager {

    // Current navigation state (shared with NavigationIQView)
    var navText        as String = "";
    var distText       as String = "";
    var etaText        as String = "";
    var nextStreet     as String = "";
    var direction      as Number = DIR_UNKNOWN;
    var exitNumber     as Number = 0;
    var rleBitmap      as Array<Number>? = null;
    var isWaitingImage as Boolean = false;
    var isActive       as Boolean = false;
    var rxCount        as Number = 0;

    // Haptic alert tracking - prevent repeated triggers at same threshold
    var _alertedFar  as Boolean = false;
    var _alertedNear as Boolean = false;

    // Map Mode State (OSM Live Mini-Map)
    var isMapMode          as Boolean = false;
    var mapRleData         as Array<Number>? = null;
    var mapPalette         as Array<Number>? = null;
    var mapWidth           as Number = 100;
    var mapHeight          as Number = 100;
    var mapZoom            as Number = 16;
    var mapSpeed           as Number = 0;
    var mapHeading         as Number = 0;
    var mapRxCount         as Number = 0;
    var lastRxTime         as Number = 0;

    // Vector Route Radar State (Cách 1: Breadcrumbs & Radial Alley Network)
    var isVectorRouteActive as Boolean = false;
    var mapHeadingUp       as Boolean = true;
    var vecOriginLat       as Float = 0.0;
    var vecOriginLon       as Float = 0.0;
    var vecPathPoints      as Array<Number>? = null;    // [dx0, dy0, dx1, dy1, ...]
    var vecAlleySegments   as Array<Number>? = null;    // [x1, y1, x2, y2, ...]
    var vecDestName        as String = "";
    var vecTotalDist       as Number = 0;
    var vecUserDx          as Number = 0;
    var vecUserDy          as Number = 0;
    var vecHeading         as Number = 0;
    var vecSpeedKmh        as Number = 0;
    var vecNextTurnDist    as Number = 0;
    var vecNextTurnAngle   as Number = 0;
    var vecNextStreet      as String = "";
    var vecStreetLabels    as Array<Object>? = null;    // [name1, x1, y1, name2, x2, y2, ...]

    function isHeadingUp() as Boolean {
        var saved = Application.Storage.getValue("map_heading_up");
        if (saved != null) {
            mapHeadingUp = saved as Boolean;
        }
        return mapHeadingUp;
    }

    function setMapHeadingUp(headingUp as Boolean) as Void {
        mapHeadingUp = headingUp;
        Application.Storage.setValue("map_heading_up", headingUp);
        WatchUi.requestUpdate();
    }

    function toggleMapOrientation() as Void {
        setMapHeadingUp(!isHeadingUp());
    }

    // In-App Toast Notification Banner State
    var toastAppName   as String = "";
    var toastSender    as String = "";
    var toastMessage   as String = "";
    var toastExpiry    as Number = 0;

    // Arrival / Destination Reached State
    var isArrived          as Boolean = false;
    var arrivedDest        as String = "";
    var arrivedDuration    as String = "";
    var arrivedDistance    as String = "";
    var arrivedAvgSpeed    as String = "";
    var arrivedStartTime   as String = "";
    var arrivedEndTime     as String = "";
    var arrivedTimestamp   as Number = 0;
    var isArrivedDetail    as Boolean = false;

    // Text Size & Layout Preset (0=Balanced, 1=Street Focus, 2=Distance Focus, 3=Large Text)
    var textPreset     as Number = 0;

    // Automatic Activity Session (Garmin OS "During Activity" DND suppression)
    var _session as ActivityRecording.Session? = null;
    var isAutoActivitySuppression as Boolean = true;

    function showToastNotification(app as String, sender as String, msg as String, durSec as Number) as Void {
        toastAppName = app;
        toastSender = sender;
        toastMessage = msg;
        toastExpiry = System.getTimer() + (durSec * 1000);
        if (Attention has :vibrate) {
            try {
                var vibeProfile = [new Attention.VibeProfile(60, 200)];
                Attention.vibrate(vibeProfile);
            } catch (e) {}
        }
    }

    function isToastActive() as Boolean {
        return (toastExpiry > 0 && System.getTimer() < toastExpiry && toastMessage.length() > 0);
    }

    function dismissToastNotification() as Void {
        toastExpiry = 0;
        toastMessage = "";
        toastSender = "";
        toastAppName = "";
    }

    function startActivitySession() as Void {
        if (!isAutoActivitySuppression) {
            return;
        }
        if (Toybox has :ActivityRecording) {
            if (_session == null || !_session.isRecording()) {
                try {
                    _session = ActivityRecording.createSession({
                        :name => "Navigation",
                        :sport => ActivityRecording.SPORT_GENERIC,
                        :subSport => ActivityRecording.SUB_SPORT_GENERIC
                    });
                    _session.start();
                } catch (e) {
                    System.println("ERR session: " + e.getErrorMessage());
                }
            }
        }
    }

    function stopActivitySession() as Void {
        if (_session != null) {
            try {
                if (_session.isRecording()) {
                    _session.stop();
                }
                _session.discard();
            } catch (e) {
                System.println("ERR stopSession: " + e.getErrorMessage());
            }
            _session = null;
        }
    }

    function isConnected() as Boolean {
        if (lastRxTime <= 0) {
            return false;
        }
        return (System.getTimer() - lastRxTime < 15000);
    }

    function setMapMode(enabled as Boolean) as Void {
        isMapMode = enabled;
        try {
            Communications.transmit(enabled ? "map_on" : "map_off", null, new PhoneCommListener());
        } catch (e) {
        }
    }

    function requestZoom(zoom as Number) as Void {
        mapZoom = zoom;
        try {
            Communications.transmit(["map_zoom", zoom], null, new PhoneCommListener());
        } catch (e) {
        }
    }

    function requestPan(dx as Number, dy as Number) as Void {
        try {
            Communications.transmit(["map_pan", dx, dy], null, new PhoneCommListener());
        } catch (e) {
        }
    }

    function recenterMap() as Void {
        try {
            Communications.transmit("map_recenter", null, new PhoneCommListener());
        } catch (e) {
        }
    }

    function start() as Void {
        navText     = "";
        distText    = "";
        etaText     = "";
        direction   = DIR_UNKNOWN;
        exitNumber  = 0;
        nextStreet  = "";
        rleBitmap   = null;
        isActive    = false;
        mapRleData  = null;
        lastRxTime  = 0;
    }

    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        onPhoneMessageRaw(msg.data);
    }

    function onPhoneMessageRaw(data as Object?) as Void {
        if (data == null) {
            return;
        }
        rxCount++;
        lastRxTime = System.getTimer();
        System.println(">>> CommManager parsed data: " + data);

        // Keep-Alive Ping packet: ["ping", timestamp]
        if (data instanceof Lang.Array && data.size() >= 1) {
            if (data[0] instanceof Lang.String && data[0].equals("ping")) {
                WatchUi.requestUpdate();
                return;
            }
        }

        // 1. Vector Route definition packet:
        // ["vec_route", originLat, originLon, pathCoords, alleyCoords, destName, totalDist]
        if (data instanceof Lang.Array && data.size() >= 7) {
            if (data[0] instanceof Lang.String && data[0].equals("vec_route")) {
                if (data[1] != null) {
                    if (data[1] instanceof Lang.Float || data[1] instanceof Lang.Double) {
                        vecOriginLat = (data[1] as Lang.Float);
                    } else if (data[1] instanceof Lang.Number) {
                        vecOriginLat = (data[1] as Lang.Number).toFloat();
                    }
                }
                if (data[2] != null) {
                    if (data[2] instanceof Lang.Float || data[2] instanceof Lang.Double) {
                        vecOriginLon = (data[2] as Lang.Float);
                    } else if (data[2] instanceof Lang.Number) {
                        vecOriginLon = (data[2] as Lang.Number).toFloat();
                    }
                }
                if (data[3] instanceof Lang.Array) { vecPathPoints = data[3] as Array<Number>; }
                if (data[4] instanceof Lang.Array) { vecAlleySegments = data[4] as Array<Number>; }
                if (data[5] != null) { vecDestName = data[5] as String; }
                if (data[6] != null) { vecTotalDist = data[6] as Number; }
                if (data.size() >= 8 && data[7] instanceof Lang.Array) {
                    vecStreetLabels = data[7] as Array<Object>;
                }
                isVectorRouteActive = true;
                isActive = true;
                lastRxTime = System.getTimer();
                var app = Application.getApp();
                if (app has :getMainView) {
                    var v = app.getMainView();
                    if (v != null) {
                        v.switchToMapTab();
                    }
                }
                WatchUi.requestUpdate();
                return;
            }
        }

        // 2. Vector Position & Telemetry packet:
        // ["vec_pos", userDx, userDy, heading, speed, nextTurnDist, nextTurnAngle, nextStreet]
        if (data instanceof Lang.Array && data.size() >= 8) {
            if (data[0] instanceof Lang.String && data[0].equals("vec_pos")) {
                if (data[1] != null) { vecUserDx = data[1] as Number; }
                if (data[2] != null) { vecUserDy = data[2] as Number; }
                if (data[3] != null) { vecHeading = data[3] as Number; }
                if (data[4] != null) { vecSpeedKmh = data[4] as Number; }
                if (data[5] != null) { vecNextTurnDist = data[5] as Number; }
                if (data[6] != null) { vecNextTurnAngle = data[6] as Number; }
                if (data[7] != null) { vecNextStreet = data[7] as String; }
                lastRxTime = System.getTimer();
                WatchUi.requestUpdate();
                return;
            }
        }

        // 3. Set Map Orientation packet:
        // ["set_map_orientation", isHeadingUp (1 or 0)]
        if (data instanceof Lang.Array && data.size() >= 2) {
            if (data[0] instanceof Lang.String && data[0].equals("set_map_orientation")) {
                var flag = (data[1] != null && (data[1] as Number) == 1);
                setMapHeadingUp(flag);
                return;
            }
        }

        // Map data packet from Android: [ "map", width, height, zoom, speed, heading, rleData, palette ] (Disabled by user request)
        /*
        if (data instanceof Lang.Array && data.size() >= 7) {
            if (data[0] instanceof Lang.String && data[0].equals("map")) {
                mapWidth   = (data[1] != null) ? data[1] as Number : 180;
                mapHeight  = (data[2] != null) ? data[2] as Number : 180;
                mapZoom    = (data[3] != null) ? data[3] as Number : 16;
                mapSpeed   = (data[4] != null) ? data[4] as Number : 0;
                mapHeading = (data[5] != null) ? data[5] as Number : 0;
                if (data[6] instanceof Lang.Array) {
                    mapRleData = data[6] as Array<Number>;
                } else if (data[6] instanceof Lang.String) {
                    mapRleData = _decodeHexRle(data[6] as String);
                } else {
                    mapRleData = null;
                }
                if (data.size() >= 8 && data[7] != null) {
                    mapPalette = data[7] as Array<Number>;
                }
                mapRxCount++;
                WatchUi.requestUpdate();
                return;
            }
        }
        */

        // Toast / In-app notification packet from Android:
        // ["toast", appName, sender, message, durationSec]
        if (data instanceof Lang.Array && data.size() >= 4) {
            if (data[0] instanceof Lang.String && (data[0].equals("toast") || data[0].equals("notif"))) {
                var appName = (data[1] != null) ? data[1] as String : "";
                var sender = (data[2] != null) ? data[2] as String : "";
                var msg = (data[3] != null) ? data[3] as String : "";
                var dur = (data.size() >= 5 && data[4] != null) ? data[4] as Number : 5;
                showToastNotification(appName, sender, msg, dur);
                WatchUi.requestUpdate();
                return;
            }
        }

        // Text Size & Layout Preset packet from Android:
        // ["set_text_preset", presetId]
        if (data instanceof Lang.Array && data.size() >= 2) {
            if (data[0] instanceof Lang.String && data[0].equals("set_text_preset")) {
                var pId = (data[1] != null) ? data[1] as Number : 0;
                textPreset = pId;
                Application.Storage.setValue("text_preset", pId);
                var app = Application.getApp();
                if (app has :getMainView) {
                    var v = app.getMainView();
                    if (v != null) {
                        v.reloadSettings();
                    }
                }
                WatchUi.requestUpdate();
                return;
            }
        }

        // Layout Profile packet from Android (0=Auto, 1=Venu Sq, 2=Round, 3=Instinct):
        // ["set_layout_profile", profileId]
        if (data instanceof Lang.Array && data.size() >= 2) {
            if (data[0] instanceof Lang.String && data[0].equals("set_layout_profile")) {
                var profId = (data[1] != null) ? data[1] as Number : 0;
                Application.Storage.setValue("layout_profile", profId);
                var app = Application.getApp();
                if (app has :getMainView) {
                    var v = app.getMainView();
                    if (v != null) {
                        v.reloadSettings();
                    }
                }
                WatchUi.requestUpdate();
                return;
            }
        }

        // Arrived at destination signal: ["arrived", destination, duration, distance, avgSpeed, startTime, endTime]
        if (data instanceof Lang.Array && data.size() >= 1) {
            if (data[0] instanceof Lang.String && data[0].equals("arrived")) {
                _handleArrived(data);
                WatchUi.requestUpdate();
                return;
            }
        }

        // End-of-navigation signal
        if ((data instanceof Lang.Array && data.size() == 1 && data[0] instanceof Lang.String && data[0].equals("naviend")) ||
            (data instanceof Lang.String && data.equals("naviend"))) {
            // If watch is actively showing Destination Reached screen, keep it alive so user can view it!
            // The user can dismiss it anytime by pressing the Back button.
            if (direction == DIR_ARRIVED || isArrived) {
                stopActivitySession();
                WatchUi.requestUpdate();
                return;
            }
            _resetNav();
            WatchUi.requestUpdate();
            return;
        }

        // Standard GarminMessage payload from Android:
        // [ settingsArray, navigationArray, bitmapDataArray, imageHashString ]
        if (!(data instanceof Lang.Array) || data.size() < 2) {
            return;
        }

        var navData = data[1]; // navigation array: [units, eta, length, duration, distance, signs, time]
        if (navData instanceof Lang.Array && navData.size() >= 6) {
            // Index 1: eta
            if (navData[1] != null && navData[1] instanceof Lang.String) {
                etaText = navData[1] as String;
            }
            // Index 4: distance
            if (navData[4] != null && navData[4] instanceof Lang.String) {
                distText = navData[4] as String;
            }
            // Index 5: signs / instruction
            if (navData[5] != null && navData[5] instanceof Lang.String) {
                var newNav = navData[5] as String;
                if (!newNav.equals(navText)) {
                    navText = newNav;
                    _inferDirectionAndExit(navText);
                    nextStreet = _extractNextStreet(navText);
                    // Preserve cached rleBitmap; only mark waiting if no bitmap exists
                    if (rleBitmap == null) {
                        isWaitingImage = true;
                    }
                }
            }

            if (navText.length() > 0 || distText.length() > 0) {
                if (!isActive) {
                    startActivitySession();
                }
                isActive = true;
                if (direction != DIR_ARRIVED) {
                    isArrived = false;
                }
            }
        }

        // Parse optional RLE bitmap from index 2
        if (data.size() >= 3 && data[2] instanceof Lang.Array) {
            var bmpArray = data[2] as Array;
            if (bmpArray.size() > 2) {
                rleBitmap = bmpArray as Array<Number>;
                isWaitingImage = false;
            }
        }

        // Evaluate haptic alerts based on distance
        _checkHaptic();

        WatchUi.requestUpdate();
    }

    // Call this from NavigationIQView.onUpdate when distance changes
    function checkHapticUpdate() as Void {
        _checkHaptic();
    }

    // Arrival screen stays until user presses Back or a new navigation route starts
    function checkArrivedExpiry() as Void {
        // No auto-dismiss: user stays on arrival summary until manual action
    }

    function getArrivedRemainingSeconds() as Number {
        return 0;
    }

    function dismissArrived() as Void {
        isArrived = false;
        direction = DIR_UNKNOWN;
        _resetNav();
        WatchUi.requestUpdate();
    }

    function toggleArrivedDetail() as Void {
        isArrivedDetail = !isArrivedDetail;
        WatchUi.requestUpdate();
    }

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    function _handleArrived(data as Lang.Array) as Void {
        isArrived = true;
        isActive = false;
        isArrivedDetail = false;
        arrivedTimestamp = System.getTimer();
        stopActivitySession();

        arrivedDest = (data.size() > 1 && data[1] != null) ? (data[1] as String) : (nextStreet.length() > 0 ? nextStreet : navText);
        if (arrivedDest.length() == 0) {
            arrivedDest = "Destination";
        }
        arrivedDuration = (data.size() > 2 && data[2] != null) ? (data[2] as String) : "--";
        arrivedDistance = (data.size() > 3 && data[3] != null) ? (data[3] as String) : "--";
        arrivedAvgSpeed = (data.size() > 4 && data[4] != null) ? (data[4] as String) : "--";
        arrivedStartTime = (data.size() > 5 && data[5] != null) ? (data[5] as String) : "";
        arrivedEndTime = (data.size() > 6 && data[6] != null) ? (data[6] as String) : "";

        _triggerArrivalVibe();
    }

    function _fallbackToArrived() as Void {
        isArrived = true;
        isActive = false;
        isArrivedDetail = false;
        arrivedTimestamp = System.getTimer();
        stopActivitySession();

        arrivedDest = (nextStreet.length() > 0) ? nextStreet : (navText.length() > 0 ? navText : "Destination");
        arrivedDuration = (etaText.length() > 0) ? etaText : "--";
        arrivedDistance = (distText.length() > 0) ? distText : "--";
        arrivedAvgSpeed = "--";
        arrivedStartTime = "";
        arrivedEndTime = "";

        _triggerArrivalVibe();
    }

    function _triggerArrivalVibe() as Void {
        if (Attention has :vibrate) {
            try {
                var vibeData = [
                    new Attention.VibeProfile(80, 200),
                    new Attention.VibeProfile(0, 100),
                    new Attention.VibeProfile(100, 350)
                ];
                Attention.vibrate(vibeData);
            } catch (e) {}
        }
    }

    function _resetNav() as Void {
        navText     = "";
        distText    = "";
        etaText     = "";
        nextStreet  = "";
        direction   = DIR_UNKNOWN;
        exitNumber  = 0;
        rleBitmap   = null;
        isActive    = false;
        isArrived   = false;
        _alertedFar  = false;
        _alertedNear = false;
        toastExpiry = 0;
        stopActivitySession();
        try {
            Application.Storage.deleteValue("navText");
            Application.Storage.deleteValue("distText");
            Application.Storage.deleteValue("etaText");
        } catch (e) {}
    }

    function _extractNextStreet(text as String) as String {
        if (text.length() == 0) {
            return "";
        }
        var lower = text.toLower();
        var markers = ["onto ", "vào ", "lên ", "toward ", "sang ", "hướng ", "on ", "at ", "tại "];
        for (var i = 0; i < markers.size(); i++) {
            var marker = markers[i];
            var idx = lower.find(marker);
            if (idx != null) {
                var candidate = text.substring(idx + marker.length(), text.length());
                if (candidate.length() > 0) {
                    return candidate;
                }
            }
        }
        return "";
    }

    function _inferDirectionAndExit(text as String) as Void {
        var lower = text.toLower();
        exitNumber = 0;

        // 0. Check Arrival / Destination Reached first
        if (lower.find("arrived at") != null || lower.find("you have arrived") != null ||
            lower.equals("arrived") || lower.find("arrived ·") != null ||
            lower.find("bạn đã đến") != null || lower.find("đã đến nơi") != null ||
            lower.find("đã tới nơi") != null || lower.find("đã đến điểm đến") != null ||
            lower.find("arriving") != null || lower.find("sắp đến") != null ||
            lower.find("sắp tới") != null || lower.find("đang đến") != null ||
            lower.find("đang tới") != null) {
            direction = DIR_ARRIVED;
            isArrived = true;
            arrivedTimestamp = System.getTimer();
            // If text contains separator (· or -), extract the destination address into nextStreet
            var dotIdx = text.find("·");
            if (dotIdx != null && dotIdx + 1 < text.length()) {
                var cand = text.substring(dotIdx + 1, text.length());
                while (cand.length() > 0 && cand.substring(0, 1).equals(" ")) {
                    cand = cand.substring(1, cand.length());
                }
                if (cand.length() > 0) {
                    nextStreet = cand;
                }
            } else {
                var dashIdx = text.find(" - ");
                if (dashIdx != null && dashIdx + 3 < text.length()) {
                    var cand = text.substring(dashIdx + 3, text.length());
                    if (cand.length() > 0) {
                        nextStreet = cand;
                    }
                }
            }
            // Strip leading "at " or "tại " from nextStreet if present
            if (nextStreet.length() > 3 && nextStreet.toLower().substring(0, 3).equals("at ")) {
                nextStreet = nextStreet.substring(3, nextStreet.length());
            } else if (nextStreet.length() > 4 && nextStreet.toLower().substring(0, 4).equals("tại ")) {
                nextStreet = nextStreet.substring(4, nextStreet.length());
            }
            return;
        }

        // 1. Check Roundabout & Multi-way intersections first
        if (lower.find("roundabout") != null || lower.find("vòng xoay") != null || 
            lower.find("vòng xuyến") != null || lower.find("ngã sáu") != null || 
            lower.find("ngã năm") != null || lower.find("ngã bảy") != null || 
            lower.find("ngã tám") != null || lower.find("bùng binh") != null || 
            lower.find("exit") != null || lower.find("lối ra") != null) {
            
            if (lower.find("1st") != null || lower.find("first") != null || lower.find("thứ 1") != null || lower.find("thứ nhất") != null || lower.find(" 1") != null) {
                direction = DIR_ROUNDABOUT_1;
                exitNumber = 1;
                return;
            } else if (lower.find("2nd") != null || lower.find("second") != null || lower.find("thứ 2") != null || lower.find("thứ hai") != null || lower.find(" 2") != null) {
                direction = DIR_ROUNDABOUT_2;
                exitNumber = 2;
                return;
            } else if (lower.find("3rd") != null || lower.find("third") != null || lower.find("thứ 3") != null || lower.find("thứ ba") != null || lower.find(" 3") != null) {
                direction = DIR_ROUNDABOUT_3;
                exitNumber = 3;
                return;
            } else if (lower.find("4th") != null || lower.find("fourth") != null || lower.find("thứ 4") != null || lower.find("thứ tư") != null || lower.find(" 4") != null) {
                direction = DIR_ROUNDABOUT_4;
                exitNumber = 4;
                return;
            } else if (lower.find("5th") != null || lower.find("fifth") != null || lower.find("thứ 5") != null || lower.find("thứ năm") != null || lower.find(" 5") != null) {
                direction = DIR_ROUNDABOUT_5;
                exitNumber = 5;
                return;
            } else {
                direction = DIR_ROUNDABOUT_2;
                exitNumber = 2;
                return;
            }
        }

        // 2. U-Turn
        if (lower.find("u-turn") != null || lower.find("quay đầu") != null) {
            direction = DIR_UTURN;
            return;
        }

        // 3. Bear / Slight turns
        if (lower.find("chếch sang trái") != null || lower.find("slight left") != null || lower.find("bear left") != null) {
            direction = DIR_SLIGHT_LEFT;
            return;
        }
        if (lower.find("chếch sang phải") != null || lower.find("slight right") != null || lower.find("bear right") != null) {
            direction = DIR_SLIGHT_RIGHT;
            return;
        }

        // 4. Sharp turns
        if (lower.find("quẹo gắt trái") != null || lower.find("sharp left") != null) {
            direction = DIR_SHARP_LEFT;
            return;
        }
        if (lower.find("quẹo gắt phải") != null || lower.find("sharp right") != null) {
            direction = DIR_SHARP_RIGHT;
            return;
        }

        // 5. Standard turns
        if (lower.find("trái") != null || lower.find("left") != null) {
            direction = DIR_LEFT;
            return;
        }
        if (lower.find("phải") != null || lower.find("right") != null) {
            direction = DIR_RIGHT;
            return;
        }

        // 6. Straight
        direction = DIR_STRAIGHT;
    }

    function _checkHaptic() as Void {
        if (!isActive || direction == DIR_UNKNOWN || direction == DIR_STRAIGHT) {
            return;
        }

        var meters = _parseMeters(distText);
        if (meters < 0) {
            return;
        }

        // Near alert: <= 30m  -> urgent pattern
        if (meters <= HAPTIC_ALERT_NEAR && !_alertedNear) {
            _alertedNear = true;
            _alertedFar  = true;
            _vibrateForDirection(direction, true);
        }
        // Far alert: <= 100m -> first warning
        else if (meters <= HAPTIC_ALERT_FAR && !_alertedFar) {
            _alertedFar = true;
            _vibrateForDirection(direction, false);
        }

        // Reset thresholds when distance rises again (new turn segment)
        if (meters > HAPTIC_ALERT_FAR + 20) {
            _alertedFar  = false;
            _alertedNear = false;
        }
    }

    function _vibrateForDirection(dir as Number, isUrgent as Boolean) as Void {
        if (!(Attention has :vibrate)) {
            return;
        }

        var vibeData;

        if (dir == DIR_LEFT || dir == DIR_SHARP_LEFT || dir == DIR_ROUNDABOUT_4 || dir == DIR_ROUNDABOUT_5) {
            // Left: 1 pulse
            if (isUrgent) {
                vibeData = [
                    new Attention.VibeProfile(100, 600)
                ];
            } else {
                vibeData = [
                    new Attention.VibeProfile(100, 400)
                ];
            }
        } else if (dir == DIR_RIGHT || dir == DIR_SHARP_RIGHT || dir == DIR_ROUNDABOUT_1 || dir == DIR_ROUNDABOUT_2) {
            // Right: 2 pulses
            if (isUrgent) {
                vibeData = [
                    new Attention.VibeProfile(100, 250),
                    new Attention.VibeProfile(0,   80),
                    new Attention.VibeProfile(100, 250)
                ];
            } else {
                vibeData = [
                    new Attention.VibeProfile(100, 180),
                    new Attention.VibeProfile(0,   100),
                    new Attention.VibeProfile(100, 180)
                ];
            }
        } else if (dir == DIR_UTURN) {
            // U-Turn: 3 rapid pulses
            if (isUrgent) {
                vibeData = [
                    new Attention.VibeProfile(100, 200),
                    new Attention.VibeProfile(0,   60),
                    new Attention.VibeProfile(100, 200),
                    new Attention.VibeProfile(0,   60),
                    new Attention.VibeProfile(100, 200)
                ];
            } else {
                vibeData = [
                    new Attention.VibeProfile(100, 150),
                    new Attention.VibeProfile(0,   80),
                    new Attention.VibeProfile(100, 150),
                    new Attention.VibeProfile(0,   80),
                    new Attention.VibeProfile(100, 150)
                ];
            }
        } else {
            vibeData = [
                new Attention.VibeProfile(80, 250)
            ];
        }

        try {
            Attention.vibrate(vibeData);
        } catch (e) {}
    }

    function _parseMeters(distStr as String) as Number {
        if (distStr.length() == 0) {
            return -1;
        }

        var lower = distStr.toLower();

        if (lower.find("km") != null) {
            var idx = lower.find("km");
            var numStr = distStr.substring(0, idx);
            var commaIdx = numStr.find(",");
            if (commaIdx != null) {
                numStr = numStr.substring(0, commaIdx) + "." + numStr.substring(commaIdx + 1, numStr.length());
            }
            var val = numStr.toFloat();
            if (val != null) {
                return (val * 1000).toNumber();
            }
        } else if (lower.find(" m") != null || lower.find("m") != null) {
            var idx = lower.find("m");
            var numStr = distStr.substring(0, idx);
            var val = numStr.toNumber();
            if (val != null) {
                return val;
            }
        }

        return -1;
    }

    function _decodeHexRle(hex as String) as Array<Number> {
        var chars = hex.toCharArray();
        var len = chars.size();
        var res = new [len / 2] as Array<Number>;
        var outIdx = 0;
        var i = 0;
        while (i < len - 1) {
            var c1 = chars[i].toNumber();
            var c2 = chars[i + 1].toNumber();
            // '0'=48, '9'=57, 'A'=65, 'F'=70, 'a'=97, 'f'=102
            var v1 = (c1 >= 48 && c1 <= 57) ? (c1 - 48) : ((c1 >= 65 && c1 <= 70) ? (c1 - 55) : ((c1 >= 97 && c1 <= 102) ? (c1 - 87) : 0));
            var v2 = (c2 >= 48 && c2 <= 57) ? (c2 - 48) : ((c2 >= 65 && c2 <= 70) ? (c2 - 55) : ((c2 >= 97 && c2 <= 102) ? (c2 - 87) : 0));
            res[outIdx] = (v1 * 16) + v2;
            outIdx++;
            i += 2;
        }
        return res;
    }
}

class PhoneCommListener extends Communications.ConnectionListener {
    function initialize() {
        ConnectionListener.initialize();
    }
    function onComplete() as Void {
    }
    function onError() as Void {
    }
}
