import Toybox.Lang;
import Toybox.WatchUi;

class NavigationIQDelegate extends WatchUi.BehaviorDelegate {

    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // Back button -> exit arrived screen, exit preview mode, or exit app
    function onBack() as Boolean {
        if (CommManager.direction == DIR_ARRIVED) {
            CommManager._resetNav();
            WatchUi.requestUpdate();
            return true;
        }
        if (_view != null) {
            if (_view.isPreviewModeActive()) {
                _view.stopPreviewMode();
                return true;
            }
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    // Single press on Select / Action button (Top button) -> Open Settings directly
    function onSelect() as Boolean {
        if (_view != null) {
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
        // Map page switching disabled by user request
        // if (_view != null) {
        //     if (_view.isMapTabActive()) {
        //         _view.switchToHudTab();
        //     } else {
        //         _view.switchToMapTab();
        //     }
        //     return true;
        // }
        return false;
    }

    function onPreviousPage() as Boolean {
        // Map page switching disabled by user request
        // if (_view != null) {
        //     if (_view.isMapTabActive()) {
        //         _view.switchToHudTab();
        //     } else {
        //         _view.switchToMapTab();
        //     }
        //     return true;
        // }
        return false;
    }

    // Swipe Up -> Settings Menu | Swipe Down -> HUD Tab / Dismiss
    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (_view != null) {
            var dir = swipeEvent.getDirection();
            if (dir == WatchUi.SWIPE_UP) {
                WatchUi.pushView(new NavigationIQSettingsMenu(), new NavigationIQSettingsDelegate(_view), WatchUi.SLIDE_UP);
                return true;
            } else if (dir == WatchUi.SWIPE_DOWN) {
                if (_view.isPreviewModeActive()) {
                    _view.stopPreviewMode();
                    return true;
                }
                // if (_view.isMapTabActive()) {
                //     _view.switchToHudTab();
                //     return true;
                // }
            }
        }
        return false;
    }

    // Drag / Pan Map with 1 finger
    function onDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        // Map drag disabled by user request
        // if (_view != null && _view.isMapTabActive()) {
        //     return _view.onMapDrag(dragEvent);
        // }
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
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            if (_view != null) {
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
            WatchUi.pushView(new NavigationIQSettingsMenu(), new NavigationIQSettingsDelegate(_view), WatchUi.SLIDE_UP);
        }
        return true;
    }

}