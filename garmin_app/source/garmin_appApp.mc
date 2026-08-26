import Toybox.Application;
import Toybox.Communications;
import Toybox.Attention;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class NavigationIQApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
        if (Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
        }
    }

    function onStart(state as Dictionary?) as Void {
        if (Communications has :registerForPhoneAppMessages) {
            Communications.registerForPhoneAppMessages(method(:onPhoneMessage));
        }
        CommManager.start();
    }

    function onStop(state as Dictionary?) as Void {
    }

    function onPhoneMessage(msg as Communications.PhoneAppMessage) as Void {
        System.println(">>> IQ App received msg.data: " + msg.data);
        CommManager.onPhoneMessageRaw(msg.data);
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new NavigationIQView(), new NavigationIQDelegate() ];
    }

}

function getApp() as NavigationIQApp {
    return Application.getApp() as NavigationIQApp;
}