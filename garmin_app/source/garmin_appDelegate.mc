import Toybox.Lang;
import Toybox.WatchUi;

class NavigationIQDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Back button -> return to HUD from map tab, or exit preview mode, or dismiss arrived screen, or exit app
    function onBack() as Boolean {
        if (CommManager.isArrived || CommManager.direction == DIR_ARRIVED) {
            CommManager.dismissArrived();
            return true;
        }
        if (_view != null) {
            if (_view.isMapTabActive()) {
                _view.switchToHudTab();
                return true;
            }
            if (_view.isPreviewModeActive()) {
                _view.stopPreviewMode();
                return true;
            }
        }
        CommManager.stopActivitySession();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // Single press on Select / Action button (Top button) -> Toggle Arrived Detail or Recenter map or Open Settings
    function onSelect() as Boolean {
        if (CommManager.isArrived) {
            CommManager.toggleArrivedDetail();
            return true;
        }
        if (_view != null) {
            if (_view.isMapTabActive()) {
                _view.recenterMap();
                return true;
            }
            if (_view.isPreviewModeActive()) {
                _view.stopPreviewMode();
                return true;
            }
            WatchUi.pushView(new NavigationIQSettingsMenu(), new NavigationIQSettingsDelegate(_view), WatchUi.SLIDE_UP);
            return true;
        }
        return false;
    }

    function onNextPage() as Boolean {
        if (_view != null) {
            if (_view.isMapTabActive()) {
                _view.zoomIn();
                return true;
            }
            _view.toggleTab();
            return true;
        }
        return false;
    }

    function onPreviousPage() as Boolean {
        if (_view != null) {
            if (_view.isMapTabActive()) {
                _view.zoomOut();
                return true;
            }
            _view.toggleTab();
            return true;
        }
        return false;
    }

    // Swipe gestures: When on Map tab, swiping ONLY pans the map and NEVER exits to HUD or settings
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (_view != null) {
            if (_view.isMapTabActive()) {
                var dir = swipeEvent.getDirection();
                var panStep = 55;
                if (dir == WatchUi.SWIPE_LEFT) {
                    _view.panMapBy(-panStep, 0);
                } else if (dir == WatchUi.SWIPE_RIGHT) {
                    _view.panMapBy(panStep, 0);
                } else if (dir == WatchUi.SWIPE_UP) {
                    _view.panMapBy(0, -panStep);
                } else if (dir == WatchUi.SWIPE_DOWN) {
                    _view.panMapBy(0, panStep);
                }
                return true;
            }

            var dir = swipeEvent.getDirection();
            if (dir == WatchUi.SWIPE_UP) {
                WatchUi.pushView(new NavigationIQSettingsMenu(), new NavigationIQSettingsDelegate(_view), WatchUi.SLIDE_UP);
                return true;
            } else if (dir == WatchUi.SWIPE_DOWN) {
                if (_view.isPreviewModeActive()) {
                    _view.stopPreviewMode();
                    return true;
                }
            } else if (dir == WatchUi.SWIPE_LEFT || dir == WatchUi.SWIPE_RIGHT) {
                _view.toggleTab();
                return true;
            }
        }
        return false;
    }

    // Drag / Pan Map with 1 finger on touchscreen
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        if (_view != null && _view.isMapTabActive()) {
            return _view.onMapDrag(dragEvent);
        }
        return false;
    }

    // Tap screen -> Handle Map zoom/recenter/orientation buttons on Map tab, or toggle rotation on HUD
    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        if (_view != null) {
            var coords = clickEvent.getCoordinates();
            if (_view.isMapTabActive()) {
                if (_view.handleMapTap(coords[0], coords[1])) {
                    return true;
                }
                return true; // Consume taps in map mode to avoid unintended HUD rotation
            }
            _view.onScreenTap(coords[0], coords[1]);
        }
        return true;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            if (CommManager.isArrived) {
                CommManager.toggleArrivedDetail();
                return true;
            }
            if (_view != null) {
                if (_view.isMapTabActive()) {
                    _view.recenterMap();
                    return true;
                }
                if (_view.isPreviewModeActive()) {
                    _view.stopPreviewMode();
                    return true;
                }
                WatchUi.pushView(new NavigationIQSettingsMenu(), new NavigationIQSettingsDelegate(_view), WatchUi.SLIDE_UP);
                return true;
            }
        }
        return false;
    }

    function onMenu() as Boolean {
        if (_view != null) {
            if (_view.isMapTabActive()) {
                _view.recenterMap();
                return true;
            }
            WatchUi.pushView(new NavigationIQSettingsMenu(), new NavigationIQSettingsDelegate(_view), WatchUi.SLIDE_UP);
        }
        return true;
    }

}