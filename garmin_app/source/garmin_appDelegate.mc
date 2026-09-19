import Toybox.Lang;
import Toybox.WatchUi;

class NavigationIQDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Long press UP / Back -> back to HUD or exit app
    function onBack() as Boolean {
        if (_view != null && _view.isMapTabActive()) {
            _view.switchToHudTab();
            return true;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onNextPage() as Boolean {
        if (_view != null) {
            if (_view.isMapTabActive()) {
                _view.switchToHudTab();
            } else {
                _view.switchToMapTab();
            }
            return true;
        }
        return false;
    }

    function onPreviousPage() as Boolean {
        if (_view != null) {
            if (_view.isMapTabActive()) {
                _view.switchToHudTab();
            } else {
                _view.switchToMapTab();
            }
            return true;
        }
        return false;
    }

    // Swipe Down -> Map Tab | Swipe Up -> HUD Tab
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (_view != null) {
            var dir = swipeEvent.getDirection();
            if (dir == WatchUi.SWIPE_DOWN || dir == WatchUi.SWIPE_UP) {
                if (_view.isMapTabActive()) {
                    _view.switchToHudTab();
                } else {
                    _view.switchToMapTab();
                }
                return true;
            }
        }
        return false;
    }

    // Drag / Pan Map with 1 finger
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        if (_view != null && _view.isMapTabActive()) {
            return _view.onMapDrag(dragEvent);
        }
        return false;
    }

    // Tap screen -> Toggle 90° Clockwise Rotation (or tap buttons on map)
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