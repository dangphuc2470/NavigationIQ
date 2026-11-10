import Toybox.Application;
import Toybox.Communications;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

(:glance, :typecheck(disableGlanceCheck))
class NavigationIQApp extends Application.AppBase {

    private var _isFullAppRunning as Lang.Boolean = false;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
        if (_isFullAppRunning) {
            CommManager.stopActivitySession();
        }
    }

    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        System.println(">>> IQ App received msg.data: " + msg.data);
        CommManager.onPhoneMessageRaw(msg.data);
    }

    private var _mainView as NavigationIQView? = null;

    function getInitialView() as [Views] or [Views, InputDelegates] {
        _isFullAppRunning = true;
        if (Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
        }
        CommManager.start();
        var stats = System.getSystemStats();
        System.println("=== NavigationIQ launched! Heap: " + stats.usedMemory + "/" + stats.totalMemory + " bytes ===");
        _mainView = ViewFactory.createView();
        return [ _mainView, new NavigationIQDelegate(_mainView) ];
    }

    function getMainView() as NavigationIQView? {
        return _mainView;
    }

    function getGlanceView() {
        return [ new NavigationIQGlanceView() ];
    }

}

(:glance)
function getApp() as NavigationIQApp {
    return Application.getApp() as NavigationIQApp;
}