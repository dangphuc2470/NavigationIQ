import Toybox.Lang;
import Toybox.WatchUi;

class NavigationIQDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Long press UP / Back -> exit app
    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // Tap screen -> Toggle 90° Clockwise Rotation
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (_view != null) {
            var coords = clickEvent.getCoordinates();
            _view.onScreenTap(coords[0], coords[1]);
        }
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        if (keyEvent.getKey() == WatchUi.KEY_ENTER) {
            if (_view != null) {
                _view.toggleRotation();
            }
            return true;
        }
        return false;
    }

    function onMenu() as Boolean {
        if (_view != null) {
            _view.toggleRotation();
        }
        return true;
    }

}