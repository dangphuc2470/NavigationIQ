import Toybox.Lang;
import Toybox.System;

// =============================================================================
// PREVIEW MANAGER & SCENARIO ENGINE
// =============================================================================

class PreviewManager {

    private static var _previewSteps as Array<Array<Object>> = [
        // 0. Straight Ahead - Long highway run
        [
            DIR_STRAIGHT,
            "2.8 km",
            "Continue straight on Highway 1 towards City Center",
            "17:48",
            0
        ],
        // 1. Turn Right - Approaching junction
        [
            DIR_RIGHT,
            "1.4 km",
            "Turn right onto Main Street",
            "17:44",
            0
        ],
        // 2. Roundabout 2nd Exit
        [
            DIR_ROUNDABOUT_2,
            "450 m",
            "At the roundabout, take the 2nd exit onto Broadway",
            "17:41",
            2
        ],
        // 3. Turn Left - Immediate turn
        [
            DIR_LEFT,
            "80 m",
            "Turn left onto Market Street",
            "17:38",
            0
        ],
        // 4. U-Turn
        [
            DIR_UTURN,
            "30 m",
            "Make a U-turn at the median opening",
            "17:35",
            0
        ],
        // 5. Slight Right - Highway exit ramp
        [
            DIR_SLIGHT_RIGHT,
            "3.5 km",
            "Keep right to take exit 42B towards Airport Expressway",
            "17:31",
            0
        ],
        // 6. Roundabout 4th Exit
        [
            DIR_ROUNDABOUT_4,
            "250 m",
            "At the roundabout, take the 4th exit onto Grand Avenue",
            "17:27",
            4
        ],
        // 7. Slight Left - Overpass / flyover
        [
            DIR_SLIGHT_LEFT,
            "1.2 km",
            "Keep left onto the Downtown Overpass",
            "17:23",
            0
        ],
        // 8. Sharp Right - Alleyway
        [
            DIR_SHARP_RIGHT,
            "60 m",
            "Make a sharp right onto Pine Alley",
            "17:20",
            0
        ],
        // 9. Roundabout 1st Exit
        [
            DIR_ROUNDABOUT_1,
            "5.6 km",
            "At the roundabout, take the 1st exit onto Coast Highway",
            "17:16",
            1
        ]
    ];

    public static function getStepCount() as Number {
        return _previewSteps.size();
    }

    public static var enableToast as Boolean = false;

    public static function applyStep(stepIndex as Number) as Void {
        var idx = stepIndex % _previewSteps.size();
        var step = _previewSteps[idx];

        CommManager.isActive = true;
        CommManager.direction = step[0] as Number;
        CommManager.distText = step[1] as String;
        CommManager.navText = step[2] as String;
        CommManager.etaText = step[3] as String;
        CommManager.exitNumber = step[4] as Number;
        CommManager.isWaitingImage = false;
        CommManager.rleBitmap = null;
        if (enableToast) {
            CommManager.showToastNotification("Zalo", "Mẹ", "Nhớ mua đồ ăn nha con", 60);
        } else {
            CommManager.dismissToastNotification();
        }
    }
}
