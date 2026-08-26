import Toybox.Lang;
import Toybox.WatchUi;

class NavigationIQDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    // Long press UP -> exit app
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // Tap screen -> force screen refresh
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        WatchUi.requestUpdate();
        return true;
    }

    function onMenu() as Boolean {
        return true;
    }

}