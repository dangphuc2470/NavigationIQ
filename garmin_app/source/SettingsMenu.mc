import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.Lang;
import Toybox.System;

class SettingsProfileMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Watch Layout" });
        var curProfile = Storage.getValue("layout_profile");
        if (curProfile == null) {
            curProfile = 0; // 0 = Auto
        }
        
        addItem(new WatchUi.MenuItem("Auto Detect", "Detect from device", "prof_0", {}));
        addItem(new WatchUi.MenuItem("Square Watch", "Venu Sq, Venu 2 sq, Venu X1", "prof_1", {}));
        addItem(new WatchUi.MenuItem("Round Watch", "Fenix / FR / Venu", "prof_2", {}));
        addItem(new WatchUi.MenuItem("Instinct Crossover", "Dual-Zone Center Clear", "prof_3", {}));
    }
}

class SettingsProfileDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("prof_0")) {
            Storage.setValue("layout_profile", 0);
        } else if (id.equals("prof_1")) {
            Storage.setValue("layout_profile", 1);
        } else if (id.equals("prof_2")) {
            Storage.setValue("layout_profile", 2);
        } else if (id.equals("prof_3")) {
            Storage.setValue("layout_profile", 3);
        }
        if (_view != null) {
            _view.reloadSettings();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class SettingsFontMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Font" });
        addItem(new WatchUi.MenuItem("Auto Detect", "Based on device RAM", "font_auto", {}));
        addItem(new WatchUi.MenuItem("Apple SF Pro", "Full Apple UI style", "font_sf", {}));
        addItem(new WatchUi.MenuItem("Garmin Native", "Built-in, zero font RAM", "font_garmin", {}));
    }
}

class SettingsFontDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("font_auto")) {
            Storage.setValue("app_font", 0);
        } else if (id.equals("font_sf")) {
            Storage.setValue("app_font", 1);
        } else if (id.equals("font_garmin")) {
            Storage.setValue("app_font", 2);
        }
        if (_view != null) {
            _view.reloadSettings();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class SettingsTextPresetMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Text Size" });
        addItem(new WatchUi.MenuItem("Balanced", "Default balanced HUD", "preset_0", {}));
        addItem(new WatchUi.MenuItem("Street Focus", "Larger street name", "preset_1", {}));
        addItem(new WatchUi.MenuItem("Distance Focus", "Huge distance number", "preset_2", {}));
        addItem(new WatchUi.MenuItem("Large Text", "Maximum visibility", "preset_3", {}));
    }
}

class SettingsTextPresetDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("preset_0")) {
            Storage.setValue("text_preset", 0);
            CommManager.textPreset = 0;
        } else if (id.equals("preset_1")) {
            Storage.setValue("text_preset", 1);
            CommManager.textPreset = 1;
        } else if (id.equals("preset_2")) {
            Storage.setValue("text_preset", 2);
            CommManager.textPreset = 2;
        } else if (id.equals("preset_3")) {
            Storage.setValue("text_preset", 3);
            CommManager.textPreset = 3;
        }
        if (_view != null) {
            _view.reloadSettings();
        }
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class NavigationIQSettingsMenu extends WatchUi.Menu2 {
    function initialize() {
        Menu2.initialize({ :title => "Settings" });
        _buildItems();
    }

    private function _buildItems() as Void {
        var profileNames = ["Auto Detect", "Square Watch", "Round Watch", "Instinct Crossover"];
        var curProf = Storage.getValue("layout_profile");
        if (curProf == null || curProf < 0 || curProf > 3) {
            curProf = 0;
        }
        var profSub = profileNames[curProf as Number];
        addItem(new WatchUi.MenuItem("Watch Layout", profSub, "menu_layout", {}));

        var fontChoice = Storage.getValue("app_font");
        if (fontChoice == null) {
            fontChoice = Storage.getValue("dist_font");
        }
        if (fontChoice == null || fontChoice < 0 || fontChoice > 2) {
            fontChoice = 0;
        }
        var fontNames = ["Auto Detect", "Apple SF Pro", "Garmin Native"];
        var fontSub = fontNames[fontChoice as Number];
        addItem(new WatchUi.MenuItem("Font", fontSub, "menu_font", {}));

        var presetChoice = Storage.getValue("text_preset");
        if (presetChoice == null || presetChoice < 0 || presetChoice > 3) {
            presetChoice = 0;
        }
        var presetNames = ["Balanced", "Street Focus", "Distance Focus", "Large Text"];
        var presetSub = presetNames[presetChoice as Number];
        addItem(new WatchUi.MenuItem("Text Size", presetSub, "menu_text_preset", {}));

        addItem(new WatchUi.MenuItem("Preview Mode", "Demo turn navigation (4s)", "menu_preview", {}));

        var curRot = Storage.getValue("screen_rot");
        if (curRot == null) {
            curRot = 0;
        }
        var rotSub = (curRot == 1) ? "90° Moto Mount" : "0° Portrait";
        addItem(new WatchUi.MenuItem("Rotation", rotSub, "menu_rotation", {}));

        var hapticOn = Storage.getValue("haptic_enabled");
        if (hapticOn == null) {
            hapticOn = true;
        }
        addItem(new WatchUi.ToggleMenuItem("Vibration Alert", { :enabled => "On", :disabled => "Off" }, "menu_haptic", hapticOn as Boolean, {}));
    }
}

class NavigationIQSettingsDelegate extends WatchUi.Menu2InputDelegate {
    private var _view as NavigationIQView?;

    function initialize(view as NavigationIQView?) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as String;
        if (id.equals("menu_layout")) {
            WatchUi.pushView(new SettingsProfileMenu(), new SettingsProfileDelegate(_view), WatchUi.SLIDE_LEFT);
        } else if (id.equals("menu_font")) {
            WatchUi.pushView(new SettingsFontMenu(), new SettingsFontDelegate(_view), WatchUi.SLIDE_LEFT);
        } else if (id.equals("menu_text_preset")) {
            WatchUi.pushView(new SettingsTextPresetMenu(), new SettingsTextPresetDelegate(_view), WatchUi.SLIDE_LEFT);
        } else if (id.equals("menu_preview")) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            if (_view != null) {
                _view.startPreviewMode();
            }
        } else if (id.equals("menu_rotation")) {
            var curRot = Storage.getValue("screen_rot");
            if (curRot == null) {
                curRot = 0;
            }
            var nextRot = (curRot == 0) ? 1 : 0;
            Storage.setValue("screen_rot", nextRot);
            item.setSubLabel((nextRot == 1) ? "90° Moto Mount" : "0° Portrait");
            if (_view != null) {
                _view.setRotation(nextRot);
            }
        } else if (id.equals("menu_haptic")) {
            var toggleItem = item as WatchUi.ToggleMenuItem;
            var isEnabled = toggleItem.isEnabled();
            Storage.setValue("haptic_enabled", isEnabled);
        }
    }

    function onBack() as Void {
        if (_view != null) {
            _view.reloadSettings();
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
