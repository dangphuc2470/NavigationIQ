import Toybox.Application;
import Toybox.Communications;
import Toybox.Attention;
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

    function start() as Void {
        navText     = "";
        distText    = "";
        etaText     = "";
        nextStreet  = "";
        direction   = DIR_UNKNOWN;
        rleBitmap   = null;
        isActive    = false;
    }

    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        onPhoneMessageRaw(msg.data);
    }

    function onPhoneMessageRaw(data as Object?) as Void {
        if (data == null) {
            return;
        }
        rxCount++;
        System.println(">>> CommManager parsed data: " + data);

        // End-of-navigation signal
        if (data instanceof Lang.Array && data.size() == 1) {
            if (data[0] instanceof Lang.String && data[0].equals("naviend")) {
                _resetNav();
                WatchUi.requestUpdate();
                return;
            }
        }
        if (data instanceof Lang.String && data.equals("naviend")) {
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
                try { Application.Storage.setValue("etaText", etaText); } catch (e) {}
            }
            // Index 4: distance
            if (navData[4] != null && navData[4] instanceof Lang.String) {
                distText = navData[4] as String;
                try { Application.Storage.setValue("distText", distText); } catch (e) {}
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
                    try { Application.Storage.setValue("navText", navText); } catch (e) {}
                }
            }

            if (navText.length() > 0 || distText.length() > 0) {
                isActive = true;
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

    // -------------------------------------------------------------------------
    // Private helpers
    // -------------------------------------------------------------------------

    function _resetNav() as Void {
        navText     = "";
        distText    = "";
        etaText     = "";
        nextStreet  = "";
        direction   = DIR_UNKNOWN;
        exitNumber  = 0;
        rleBitmap   = null;
        isActive    = false;
        _alertedFar  = false;
        _alertedNear = false;
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
        var markers = ["onto ", "vào ", "lên ", "toward ", "sang ", "hướng ", "on "];
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

        Attention.vibrate(vibeData);
    }

    function _parseMeters(distStr as String) as Number {
        if (distStr.length() == 0) {
            return -1;
        }

        var lower = distStr.toLower();

        if (lower.find("km") != null) {
            var idx = lower.find("km");
            var numStr = distStr.substring(0, idx);
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
