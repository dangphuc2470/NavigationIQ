import Toybox.Lang;
import Toybox.System;

// =============================================================================
// PREVIEW MANAGER & SCENARIO ENGINE
// =============================================================================

class PreviewManager {

    public static function getStepCount() as Number {
        return 3;
    }

    public static var enableToast as Boolean = false;

    public static function applyStep(stepIndex as Number) as Void {
        var idx = stepIndex % 3;

        CommManager.isActive = true;
        CommManager.isWaitingImage = false;
        CommManager.rleBitmap = null;

        if (idx == 0) {
            CommManager.direction = DIR_STRAIGHT;
            CommManager.distText = "2.8 km";
            CommManager.navText = "Continue straight on Highway 1";
            CommManager.etaText = "17:48";
            CommManager.exitNumber = 0;
        } else if (idx == 1) {
            CommManager.direction = DIR_RIGHT;
            CommManager.distText = "1.4 km";
            CommManager.navText = "Turn right onto Main Street";
            CommManager.etaText = "17:44";
            CommManager.exitNumber = 0;
        } else {
            CommManager.direction = DIR_ARRIVED;
            CommManager.distText = "22 m";
            CommManager.navText = "123 Main Street";
            CommManager.etaText = "Arrived";
            CommManager.exitNumber = 0;
        }

        if (enableToast) {
            CommManager.showToastNotification("Zalo", "Mẹ", "Nhớ mua đồ ăn nha con", 60);
        } else {
            CommManager.dismissToastNotification();
        }
    }
}
