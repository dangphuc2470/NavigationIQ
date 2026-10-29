import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class FontLoader {
    public static function loadSfFonts(view as NavigationIQView) as Void {
        view._fontSfStreetBold = _load(Rez.Fonts.SfStreetBold);
        view._fontSfStreet = _load(Rez.Fonts.SfStreet);
        view._fontSfCompactBold = _load(Rez.Fonts.SfCompactBold);
        view._fontSfCompact = _load(Rez.Fonts.SfCompact);
        view._fontSfMicro = _load(Rez.Fonts.SfMicro);
        view._fontSfStreetBoldRot90 = _load(Rez.Fonts.SfStreetBoldRot90);
        view._fontSfStreetRot90 = _load(Rez.Fonts.SfStreetRot90);
        view._fontSfMicroRot90 = _load(Rez.Fonts.SfMicroRot90);
        view._fontSfUnit = _load(Rez.Fonts.SfUnit);
        view._fontSfLargeBold = _load(Rez.Fonts.SfLargeBold);
        view._fontSfLarge = _load(Rez.Fonts.SfLarge);
        view._fontSfLabel = _load(Rez.Fonts.SfLabel);
    }

    public static function ensureNumberFonts(view as NavigationIQView) as Void {
        if (view._fontSfNumberHot == null) {
            view._fontSfNumberHot = _load(Rez.Fonts.SfNumberHot);
        }
        if (view._fontSfNumberMild == null) {
            view._fontSfNumberMild = _load(Rez.Fonts.SfNumberMild);
        }
    }

    private static function _load(resId as ResourceId) as Graphics.FontDefinition? {
        try {
            return WatchUi.loadResource(resId) as Graphics.FontDefinition;
        } catch (e) {
            return null;
        }
    }
}

