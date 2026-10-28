import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Application.Storage;

class NavigationIQView extends WatchUi.View {

    private var _pageTimer as Timer.Timer?;
    private var _animTick as Number = 0;
    private var _pageIndex as Number = 0;
    private var _rotation as Number = 0; // 0 = Portrait (0°), 1 = Landscape (90° Clockwise for Left-Wrist Motorbike)
    private var _fontSfStreetBold as Graphics.FontDefinition?;
    private var _fontSfStreet as Graphics.FontDefinition?;
    private var _fontSfCompactBold as Graphics.FontDefinition?;
    private var _fontSfCompact as Graphics.FontDefinition?;
    private var _fontSfMicro as Graphics.FontDefinition?;
    private var _fontSfStreetBoldRot90 as Graphics.FontDefinition?;
    private var _fontSfStreetRot90 as Graphics.FontDefinition?;
    private var _fontSfMicroRot90 as Graphics.FontDefinition?;
    private var _fontSfNumberHot as Graphics.FontDefinition?;
    private var _fontSfNumberMild as Graphics.FontDefinition?;
    private var _fontSfUnit as Graphics.FontDefinition?;
    private var _fontSfLargeBold as Graphics.FontDefinition?;
    private var _fontSfLarge as Graphics.FontDefinition?;
    private var _fontSfLabel as Graphics.FontDefinition?;

    private var _layoutProfile as Number = 0; // 0 = Auto, 1 = Rect (Venu Sq), 2 = Round, 3 = Instinct Crossover
    private var _appFontSetting as Number = 0; // 0 = Auto, 1 = Apple SF Pro, 2 = Garmin Native
    private var _textPreset as Number = 0;     // 0 = Balanced, 1 = Street Focus, 2 = Distance Focus, 3 = Large Text

    // Preview / Demo Mode State
    private var _isPreviewMode as Boolean = false;
    private var _previewIndex as Number = 0;
    private var _previewTimerTicks as Number = 0;
    private var _savedActive as Boolean = false;
    private var _savedDir as Number = 0;
    private var _savedDist as String = "";
    private var _savedNav as String = "";
    private var _savedEta as String = "";
    private var _savedExit as Number = 0;
    private var _simTimelineTicks as Number = 0;

    // Tabs: 0 = Navigation HUD, 1 = Map Screen
    private var _currentTab as Number = 0;
    const TAB_HUD = 0;
    const TAB_MAP = 1;

    // Map Pan & Drag State
    private var _panX as Number = 0;
    private var _panY as Number = 0;
    private var _dragStartX as Number = 0;
    private var _dragStartY as Number = 0;
    private var _isDragging as Boolean = false;
    private var _mapZoom as Number = 16;
    private var _mapZoomStep as Number = 0; // -2, -1, 0, 1, 2

    function initialize() {
        View.initialize();
        _pageTimer = new Timer.Timer();
        reloadSettings();
        if (isSfFontActive()) {
            try { _fontSfStreetBold = WatchUi.loadResource(Rez.Fonts.SfStreetBold) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreetBold: " + e.getErrorMessage()); }
            try { _fontSfStreet = WatchUi.loadResource(Rez.Fonts.SfStreet) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreet: " + e.getErrorMessage()); }
            try { _fontSfCompactBold = WatchUi.loadResource(Rez.Fonts.SfCompactBold) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfCompactBold: " + e.getErrorMessage()); }
            try { _fontSfCompact = WatchUi.loadResource(Rez.Fonts.SfCompact) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfCompact: " + e.getErrorMessage()); }
            try { _fontSfMicro = WatchUi.loadResource(Rez.Fonts.SfMicro) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfMicro: " + e.getErrorMessage()); }
            try { _fontSfStreetBoldRot90 = WatchUi.loadResource(Rez.Fonts.SfStreetBoldRot90) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreetBoldRot90: " + e.getErrorMessage()); }
            try { _fontSfStreetRot90 = WatchUi.loadResource(Rez.Fonts.SfStreetRot90) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreetRot90: " + e.getErrorMessage()); }
            try { _fontSfMicroRot90 = WatchUi.loadResource(Rez.Fonts.SfMicroRot90) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfMicroRot90: " + e.getErrorMessage()); }
            try { _fontSfUnit = WatchUi.loadResource(Rez.Fonts.SfUnit) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfUnit: " + e.getErrorMessage()); }
            try { _fontSfLargeBold = WatchUi.loadResource(Rez.Fonts.SfLargeBold) as Graphics.FontDefinition; } catch (e) { _fontSfLargeBold = null; }
            try { _fontSfLarge = WatchUi.loadResource(Rez.Fonts.SfLarge) as Graphics.FontDefinition; } catch (e) { _fontSfLarge = null; }
            try { _fontSfLabel = WatchUi.loadResource(Rez.Fonts.SfLabel) as Graphics.FontDefinition; } catch (e) { _fontSfLabel = null; }
        }
    }

    public function reloadSettings() as Void {
        var p = Storage.getValue("layout_profile");
        if (p != null) {
            _layoutProfile = p as Number;
        } else {
            _layoutProfile = 0;
        }
        var r = Storage.getValue("screen_rot");
        if (r != null) {
            _rotation = r as Number;
        } else {
            _rotation = 0;
        }
        var af = Storage.getValue("app_font");
        if (af == null) {
            af = Storage.getValue("dist_font");
        }
        if (af != null) {
            _appFontSetting = af as Number;
        }
        var tp = Storage.getValue("text_preset");
        if (tp != null) {
            _textPreset = tp as Number;
        } else {
            _textPreset = 0;
        }
    }

    public function isSfFontActive() as Boolean {
        var devSettings = System.getDeviceSettings();
        if (devSettings has :screenWidth && devSettings.screenWidth <= 280) {
            if (_appFontSetting == 1) {
                return true;
            }
            return false;
        }
        var sysStats = System.getSystemStats();
        if (sysStats.totalMemory < 128 * 1024) {
            return false;
        }
        if (_appFontSetting == 1) {
            return true;
        } else if (_appFontSetting == 2) {
            return false;
        }
        return (sysStats.totalMemory >= 128 * 1024);
    }

    public function isSfNumberFontActive() as Boolean {
        return isSfFontActive();
    }

    private function _ensureSfNumberFontsLoaded() as Void {
        if (_fontSfNumberHot == null) {
            try {
                _fontSfNumberHot = WatchUi.loadResource(Rez.Fonts.SfNumberHot) as Graphics.FontDefinition;
            } catch (e) {
                _fontSfNumberHot = null;
            }
        }
        if (_fontSfNumberMild == null) {
            try {
                _fontSfNumberMild = WatchUi.loadResource(Rez.Fonts.SfNumberMild) as Graphics.FontDefinition;
            } catch (e) {
                _fontSfNumberMild = null;
            }
        }
    }

    private function _getDistanceFont(distNum as String, distUnit as String) as Graphics.FontDefinition {
        if (TextRenderer.hasAlpha(distNum)) {
            return isSfFontActive() ? ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE) : Graphics.FONT_LARGE;
        }
        if (isSfFontActive()) {
            _ensureSfNumberFontsLoaded();
            if (_textPreset == 2 || _textPreset == 3) {
                if (_fontSfNumberHot != null) {
                    return _fontSfNumberHot;
                }
            }
            if (distNum.length() >= 5 && _fontSfNumberMild != null) {
                return _fontSfNumberMild;
            }
            if (_fontSfNumberHot != null) {
                return _fontSfNumberHot;
            }
        }
        if (_textPreset == 2 || _textPreset == 3) {
            return Graphics.FONT_NUMBER_HOT;
        }
        if (distNum.length() >= 5) {
            return Graphics.FONT_NUMBER_MILD;
        }
        return Graphics.FONT_NUMBER_HOT;
    }

    // -------------------------------------------------------------------------
    // Preview Mode Control (4s Turn Navigation Cycle)
    // -------------------------------------------------------------------------
    public function isPreviewModeActive() as Boolean {
        return _isPreviewMode;
    }

    public function startPreviewMode() as Void {
        _simTimelineTicks = 0;
        _isPreviewMode = false;
        CommManager.isArrived = false;
        WatchUi.requestUpdate();
    }

    public function startNavPreview() as Void {
        _savedActive = CommManager.isActive;
        _savedDir = CommManager.direction;
        _savedDist = CommManager.distText;
        _savedNav = CommManager.navText;
        _savedEta = CommManager.etaText;
        _savedExit = CommManager.exitNumber;

        _isPreviewMode = true;
        CommManager.isArrived = false;
        _previewIndex = 1;
        _previewTimerTicks = 0;
        PreviewManager.applyStep(_previewIndex);
        WatchUi.requestUpdate();
    }

    public function startArrivedPreview() as Void {
        _savedActive = CommManager.isActive;
        _savedDir = CommManager.direction;
        _savedDist = CommManager.distText;
        _savedNav = CommManager.navText;
        _savedEta = CommManager.etaText;
        _savedExit = CommManager.exitNumber;

        _isPreviewMode = false;
        CommManager.isArrived = true;
        CommManager.arrivedDest = "123 Nguyen Thi Minh Khai, Q.1";
        CommManager.arrivedDuration = "22m";
        CommManager.arrivedDistance = "8.4 km";
        CommManager.arrivedAvgSpeed = "26 km/h";
        CommManager.arrivedStartTime = "17:23";
        CommManager.arrivedEndTime = "17:45";
        CommManager.arrivedTimestamp = System.getTimer();

        WatchUi.requestUpdate();
    }

    public function stopPreviewMode() as Void {
        _isPreviewMode = false;
        CommManager.isArrived = false;
        CommManager.isActive = _savedActive;
        CommManager.direction = _savedDir;
        CommManager.distText = _savedDist;
        CommManager.navText = _savedNav;
        CommManager.etaText = _savedEta;
        CommManager.exitNumber = _savedExit;
        WatchUi.requestUpdate();
    }

    public function togglePreviewMode() as Void {
        if (_isPreviewMode) {
            stopPreviewMode();
        } else {
            startPreviewMode();
        }
    }

    // -------------------------------------------------------------------------
    // Device Profile Resolution
    // -------------------------------------------------------------------------
    public function isHardwareRound(dc as Dc) as Boolean {
        var devSettings = System.getDeviceSettings();
        if (devSettings has :screenShape) {
            return (devSettings.screenShape == System.SCREEN_SHAPE_ROUND || devSettings.screenShape == System.SCREEN_SHAPE_SEMI_ROUND);
        }
        return (dc.getWidth() == dc.getHeight() && dc.getWidth() > 200);
    }

    public function isHardwareInstinct(dc as Dc) as Boolean {
        var w = dc.getWidth();
        var h = dc.getHeight();
        return (w <= 176 && h <= 176);
    }

    public function getEffectiveProfile(dc as Dc) as Number {
        if (_layoutProfile > 0) {
            return _layoutProfile;
        }
        if (isHardwareRound(dc)) {
            return 2;
        }
        if (isHardwareInstinct(dc)) {
            return 3;
        }
        return 1;
    }

    public function setRotation(rot as Number) as Void {
        _rotation = rot;
        Storage.setValue("screen_rot", _rotation);
        WatchUi.requestUpdate();
    }

    public function toggleRotation() as Void {
        _rotation = (_rotation == 0) ? 1 : 0;
        Storage.setValue("screen_rot", _rotation);
        WatchUi.requestUpdate();
    }

    public function isMapTabActive() as Boolean {
        return _currentTab == TAB_MAP;
    }

    public function switchToMapTab() as Void {
        _currentTab = TAB_MAP;
        _panX = 0;
        _panY = 0;
        _mapZoomStep = 0;
        CommManager.setMapMode(true);
        WatchUi.requestUpdate();
    }

    public function switchToHudTab() as Void {
        _currentTab = TAB_HUD;
        CommManager.setMapMode(false);
        WatchUi.requestUpdate();
    }

    public function toggleTab() as Void {
        _currentTab = (_currentTab == TAB_HUD) ? TAB_MAP : TAB_HUD;
        WatchUi.requestUpdate();
    }

    public function zoomIn() as Void {
        if (_mapZoomStep < 2) {
            _mapZoomStep++;
            WatchUi.requestUpdate();
        }
    }

    public function zoomOut() as Void {
        if (_mapZoomStep > -2) {
            _mapZoomStep--;
            WatchUi.requestUpdate();
        }
    }

    public function recenterMap() as Void {
        _panX = 0;
        _panY = 0;
        _mapZoomStep = 0;
        WatchUi.requestUpdate();
    }

    public function panMapBy(dx as Number, dy as Number) as Void {
        _panX += dx;
        _panY += dy;
        WatchUi.requestUpdate();
    }

    public function getZoomMultiplier() as Float {
        if (_mapZoomStep == -2) { return 0.55; }
        if (_mapZoomStep == -1) { return 0.75; }
        if (_mapZoomStep == 1) { return 1.35; }
        if (_mapZoomStep == 2) { return 1.85; }
        return 1.0;
    }

    public function handleMapTap(tx as Number, ty as Number) as Boolean {
        var devSettings = System.getDeviceSettings();
        var w = devSettings.screenWidth;
        var h = devSettings.screenHeight;

        // Top right orientation pill [ HDG ] / [ N-UP ]:
        var badgeX = w - 68;
        var badgeY = 23;
        if (tx >= badgeX - 10 && tx <= badgeX + 48 + 10 && ty >= badgeY - 10 && ty <= badgeY + 24 + 10) {
            CommManager.toggleMapOrientation();
            WatchUi.requestUpdate();
            return true;
        }

        // Floating Control buttons on the right edge
        var btnX = w - 24;
        var btnInY = (h / 2) - 22;
        var btnOutY = (h / 2) + 16;
        var btnRecenterY = (h / 2) + 54;

        // Check Zoom In button (+)
        var dInSq = (tx - btnX) * (tx - btnX) + (ty - btnInY) * (ty - btnInY);
        if (dInSq <= 22 * 22) {
            zoomIn();
            return true;
        }

        // Check Zoom Out button (-)
        var dOutSq = (tx - btnX) * (tx - btnX) + (ty - btnOutY) * (ty - btnOutY);
        if (dOutSq <= 22 * 22) {
            zoomOut();
            return true;
        }

        // Check Recenter button (only active when panned or zoomed)
        if (_panX != 0 || _panY != 0 || _mapZoomStep != 0) {
            var dRecenterSq = (tx - btnX) * (tx - btnX) + (ty - btnRecenterY) * (ty - btnRecenterY);
            if (dRecenterSq <= 22 * 22) {
                recenterMap();
                return true;
            }
        }

        return false;
    }

    public function onMapDrag(dragEvent as WatchUi.DragEvent) as Boolean {
        var type = dragEvent.getType();
        var coords = dragEvent.getCoordinates();
        if (type == WatchUi.DRAG_TYPE_START) {
            _dragStartX = coords[0];
            _dragStartY = coords[1];
            _isDragging = true;
            return true;
        } else if (type == WatchUi.DRAG_TYPE_CONTINUE) {
            var dx = coords[0] - _dragStartX;
            var dy = coords[1] - _dragStartY;
            _panX += dx;
            _panY += dy;
            _dragStartX = coords[0];
            _dragStartY = coords[1];
            WatchUi.requestUpdate();
            return true;
        } else if (type == WatchUi.DRAG_TYPE_STOP) {
            _isDragging = false;
            WatchUi.requestUpdate();
            return true;
        }
        return false;
    }

    public function onScreenTap(x as Number, y as Number) as Void {
        if (CommManager.isArrived) {
            CommManager.toggleArrivedDetail();
            return;
        }
        // Map tap logic disabled by user request
        // if (_currentTab == TAB_MAP) { ... }
        toggleRotation();
    }

    function onLayout(dc as Dc) as Void {
    }

    (:debug)
    public function isRunningInSimulator() as Boolean {
        return true;
    }

    (:release)
    public function isRunningInSimulator() as Boolean {
        return false;
    }

    function onShow() as Void {
        CommManager.start();
        if (WatchUi.View has :setClockHandPosition) {
            try {
                setClockHandPosition({
                    :clockState => WatchUi.ANALOG_CLOCK_STATE_HOLDING,
                    :hour => 270,
                    :minute => 90
                });
            } catch (e) {
                try {
                    setClockHandPosition({ :clockState => WatchUi.ANALOG_CLOCK_STATE_RESTING });
                } catch (ex) {
                }
            }
        }
        if (isRunningInSimulator()) {
            startPreviewMode();
        }
        if (_pageTimer != null) {
            _pageTimer.start(method(:onTimerTick), 200, true);
        }
    }

    function onTimerTick() as Void {
        _animTick++;
        if (_animTick % 12 == 0) {
            _pageIndex++;
        }
        if (isRunningInSimulator()) {
            _simTimelineTicks++;
            if (_simTimelineTicks == 20) { // 20 * 200ms = 4.0s: Switch to Navigation HUD
                startNavPreview();
            } else if (_simTimelineTicks == 55) { // 55 * 200ms = 11.0s: Switch to Arrived
                startArrivedPreview();
            }
        }
        if (_isPreviewMode && !CommManager.isArrived) {
            _previewTimerTicks++;
            if (_previewTimerTicks % 36 == 0) { // 36 ticks * 200ms = 7200ms (7.2s)
                _previewIndex++;
                PreviewManager.applyStep(_previewIndex);
            }
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        CommManager.checkHapticUpdate();

        var effectiveProfile = getEffectiveProfile(dc);

        dc.setColor(COLOR_BG_AMOLED, COLOR_BG_AMOLED);
        dc.clear();

        // Arrived at destination summary screen (always follows physical hardware watch model shape)
        if (CommManager.isArrived || CommManager.direction == DIR_ARRIVED) {
            if (isHardwareInstinct(dc)) {
                _drawInstinctArrivedScreen(dc);
            } else {
                _drawArrivedScreen(dc);
            }
            if (CommManager.isToastActive()) {
                _drawToastOverlay(dc, effectiveProfile);
            }
            return;
        }

        // Vector Radar Corridor Screen (Cách 1)
        if (_currentTab == TAB_MAP) {
            _drawVectorRadarScreen(dc);
            return;
        }

        if (!CommManager.isActive && !_isPreviewMode) {
            if (effectiveProfile == 3) {
                _drawInstinctIdleScreen(dc);
            } else {
                _drawIdleScreen(dc);
            }
            return;
        }

        if (effectiveProfile == 3) {
            _drawInstinctCrossoverHUD(dc);
        } else if (effectiveProfile == 2) {
            _drawRoundHUD(dc);
        } else {
            if (_rotation == 1) {
                _drawLandscapeHUD(dc);
            } else {
                _drawUnifiedAppleHUD(dc);
            }
        }

        if (CommManager.isToastActive()) {
            _drawToastOverlay(dc, effectiveProfile);
        }
    }

    function onHide() as Void {
        if (_pageTimer != null) {
            _pageTimer.stop();
        }
        if (WatchUi.View has :setClockHandPosition) {
            try {
                setClockHandPosition({ :clockState => WatchUi.ANALOG_CLOCK_STATE_SYSTEM_TIME });
            } catch (e) {
            }
        }
    }

    // -------------------------------------------------------------------------
    // Idle Standby Screen
    // -------------------------------------------------------------------------
    private function _drawIdleScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var isRound = isHardwareRound(dc);
        var isSmall = (w <= 280);

        var fontMicro;
        var fontBold;
        var fontStreet;

        if (isSmall) {
            fontMicro = Graphics.FONT_XTINY;
            fontBold = Graphics.FONT_SMALL;
            fontStreet = Graphics.FONT_XTINY;
        } else {
            fontMicro = isSfFontActive() ? ((_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY) : Graphics.FONT_XTINY;
            fontBold = isSfFontActive() ? ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE) : Graphics.FONT_LARGE;
            fontStreet = isSfFontActive() ? ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL) : Graphics.FONT_SMALL;
        }

        var cx = w / 2;
        var cy = (h * (isSmall ? 0.35 : 0.38)).toNumber();
        var r = (w * (isSmall ? 0.11 : 0.13)).toNumber();
        if (r < 22) { r = 22; }
        if (r > 50) { r = 50; }

        VectorArrowRenderer.drawAmbientGlow(dc, cx, cy, GLOW_RGB_GREEN);

        var isConnected = CommManager.isConnected() || (CommManager.rxCount > 0);
        var statusStr = isConnected ? "Connected" : "Ready";
        var strW = dc.getTextWidthInPixels(statusStr, fontMicro);
        var pillW = strW + (isSmall ? 22 : 28);
        var pillX = (w - pillW) / 2;
        var pillH = (h * 0.082).toNumber();
        if (pillH < 20) { pillH = 20; }
        if (pillH > 32) { pillH = 32; }
        var pillY = isRound ? (h * (isSmall ? 0.06 : 0.08)).toNumber() : (h * 0.05).toNumber();

        var bgCardColor = isSmall ? 0x1A1F29 : COLOR_BG_CARD;
        var borderCardColor = isSmall ? 0x667085 : COLOR_BORDER_CARD;

        dc.setColor(bgCardColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
        dc.setColor(borderCardColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);

        var dotColor = isConnected ? COLOR_THEME_GREEN_ACCENT : COLOR_TEXT_MUTED;
        dc.setColor(dotColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(pillX + (isSmall ? 10 : 13), pillY + (pillH / 2), isSmall ? 2.5 : 3.5);

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pillX + (isSmall ? 18 : 22), pillY + (pillH / 2), fontMicro, statusStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(bgCardColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        dc.setColor(borderCardColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, r);

        var arrowScale = r.toFloat() / 46.0;
        var aY1 = (26 * arrowScale).toNumber();
        var aX2 = (20 * arrowScale).toNumber();
        var aY2 = (20 * arrowScale).toNumber();
        var aY3 = (10 * arrowScale).toNumber();

        // Original Arrowhead with Green Accent & Ambient Glow
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx, cy - aY1],
            [cx + aX2, cy + aY2],
            [cx, cy + aY3],
            [cx - aX2, cy + aY2]
        ]);

        var hBold = dc.getFontHeight(fontBold);
        var hStreet = dc.getFontHeight(fontStreet);
        var textGap = isSmall ? 4 : (isRound ? 10 : 14);
        var titleY = cy + r + (h * (isSmall ? 0.05 : (isRound ? 0.07 : 0.08))).toNumber();
        var subTitleY = titleY + ((hBold + hStreet) / 2) + textGap;

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, titleY, fontBold, "Navigation IQ", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, subTitleY, fontStreet, "Waiting for navigation", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);

        var bottomStr = timeStr;
        var bottomW = dc.getTextWidthInPixels(bottomStr, fontMicro) + (isSmall ? 28 : 46);
        var bottomH = pillH;
        var bottomX = (w - bottomW) / 2;
        var bottomY;
        if (isSmall) {
            bottomY = (h * 0.77).toNumber();
        } else if (isRound) {
            bottomY = (h * 0.77).toNumber();
        } else {
            // Square AMOLED (Venu Sq 2): Lift clock pill slightly to balance spacing
            bottomY = h - bottomH - 44;
        }

        dc.setColor(bgCardColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(bottomX, bottomY, bottomW, bottomH, bottomH / 2);
        dc.setColor(borderCardColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(bottomX, bottomY, bottomW, bottomH, bottomH / 2);
        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, bottomY + (bottomH / 2), fontMicro, bottomStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // System Footer: Version string centered cleanly with dedicated padding from bottom
        var fontVersion = isSfFontActive() ? ((_fontSfLabel != null) ? _fontSfLabel : Graphics.FONT_XTINY) : Graphics.FONT_XTINY;
        var versionY;
        if (isSmall) {
            versionY = (h * 0.90).toNumber();
        } else if (isRound) {
            versionY = (h * 0.91).toNumber();
        } else {
            // Square AMOLED (Venu Sq 2): 22px padding from bottom, beautifully balanced
            versionY = h - 22;
        }
        dc.setColor(isSmall ? 0x8892B0 : 0x556275, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, versionY, fontVersion, APP_VERSION_STR, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // -------------------------------------------------------------------------
    // Luxury Arrived / Destination Reached Screen (Round & Square)
    // Always strictly follows physical watch model hardware shape, immune to HUD setting
    // -------------------------------------------------------------------------
    private function _drawArrivedScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var isRound = isHardwareRound(dc);
        var cx = w / 2;

        var isSmall = (w <= 280);

        // Typography Hierarchy: Adaptive scaling for AMOLED vs small MIP screens (Fenix 7, FR255)
        var fontDestTitle;
        var fontDestSub;
        var fontCardVal;
        var fontPill;
        var fontColLabel;

        if (isSmall) {
            fontDestTitle = Graphics.FONT_SMALL;
            fontDestSub = Graphics.FONT_XTINY;
            fontCardVal = Graphics.FONT_XTINY;
            fontPill = Graphics.FONT_XTINY;
            fontColLabel = Graphics.FONT_XTINY;
        } else {
            fontDestTitle = isSfFontActive() ? ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE) : Graphics.FONT_LARGE;
            fontDestSub = isSfFontActive() ? ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL) : Graphics.FONT_SMALL;
            fontCardVal = isSfFontActive() ? ((_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_MEDIUM) : Graphics.FONT_MEDIUM;
            fontPill = isSfFontActive() ? ((_fontSfMicro != null) ? _fontSfMicro : ((_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_MEDIUM)) : Graphics.FONT_MEDIUM;
            fontColLabel = isSfFontActive() ? ((_fontSfLabel != null) ? _fontSfLabel : Graphics.FONT_XTINY) : Graphics.FONT_XTINY;
        }

        var pillW, pillH, pillX, pillY;
        var podY, podR;
        var titleY, addrY;
        var cardW, cardH, cardX, cardY, cardRx;

        var arrivedStr = "Arrived";
        var strW = dc.getTextWidthInPixels(arrivedStr, fontPill);
        pillW = strW + (isSmall ? 22 : 36);
        pillX = (w - pillW) / 2;
        pillH = (h * 0.082).toNumber();
        if (pillH < 22) { pillH = 22; }
        if (pillH > 32) { pillH = 32; }
        pillY = isRound ? (h * (isSmall ? 0.06 : 0.08)).toNumber() : (h * 0.05).toNumber();

        if (isRound) {
            if (isSmall) {
                // --- Fenix 7 (260x260), FR255, Small MIP Round ---
                podY = (h * 0.27).toNumber(); // ~70px
                podR = 20;

                titleY = (h * 0.43).toNumber(); // ~112px: "Destination Reached"
                addrY = (h * 0.57).toNumber();  // ~148px: Street address

                cardW = (w * 0.88).toNumber();  // 228px (Broad card so 3 columns have 76px each!)
                cardH = 48;
                cardX = (w - cardW) / 2;
                cardY = (h * 0.72).toNumber();  // ~187px
                cardRx = 14;
            } else {
                // --- Venu 2, Round AMOLED (416x416 / 454x454) ---
                var scale = w.toFloat() / 416.0;
                podY = (114 * scale).toNumber();
                podR = (32 * scale).toNumber();

                titleY = (188 * scale).toNumber();
                addrY = (245 * scale).toNumber();

                cardW = (w * 0.76).toNumber();
                cardH = (72 * scale).toNumber();
                if (cardH < 56) { cardH = 56; }
                cardX = (w - cardW) / 2;
                cardY = (298 * scale).toNumber();
                cardRx = cardH / 2;
            }
        } else {
            // --- Venu Sq 2 & Square AMOLED (320x360) Perfectly Balanced Layout ---
            podY = (h * 0.267).toNumber(); // ~96px
            podR = 28;

            titleY = (h * 0.458).toNumber(); // ~165px
            addrY = (h * 0.617).toNumber();  // ~222px

            cardW = (w * 0.92).toNumber(); // 294px
            cardH = 74;
            cardX = (w - cardW) / 2;
            cardY = h - cardH - 12; // 274px
            cardRx = 20;
        }

        // 1. Ambient Mint Glow behind the central disc
        VectorArrowRenderer.drawAmbientGlow(dc, cx, podY, GLOW_RGB_GREEN);

        // 2. Top Status Pill: Identical sizing & style with Init screen
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);

        // Mint Checkmark Icon
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var chkX = pillX + 14;
        var chkY = pillY + (pillH / 2);
        dc.drawLine(chkX - 5, chkY, chkX - 1, chkY + 4);
        dc.drawLine(chkX - 1, chkY + 4, chkX + 6, chkY - 4);

        // Status Text (Prominent & matched with Init pill)
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(chkX + 12, pillY + (pillH / 2), fontPill, arrivedStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Central Disc (Matched with Init screen disc)
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, podY, podR);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, podY, podR);

        // Checkmark inside Pod
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        var cScale = podR.toFloat() / 32.0;
        var cMidX = cx - (2 * cScale).toNumber();
        var cMidY = podY + (8 * cScale).toNumber();
        dc.drawLine(cMidX - (9 * cScale).toNumber(), cMidY - (9 * cScale).toNumber(), cMidX, cMidY);
        dc.drawLine(cMidX, cMidY, cMidX + (15 * cScale).toNumber(), cMidY - (16 * cScale).toNumber());

        // 4. Headline & High-Glance Street Address
        // Subtitle: "Destination Reached" in crisp readable silver (matches Init "Waiting for navigation")
        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, titleY, fontDestSub, "Destination Reached", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var streetStr = "";
        if (CommManager.arrivedDest.length() > 0 && !CommManager.arrivedDest.equals("Destination")) {
            streetStr = CommManager.arrivedDest;
        } else if (CommManager.nextStreet.length() > 0) {
            streetStr = CommManager.nextStreet;
        } else if (CommManager.navText.length() > 0) {
            streetStr = CommManager.navText;
        } else {
            streetStr = "Destination";
        }

        // Clean out arrival prefixes and special bullet characters that cause tofu '[]'
        var prefixes = [
            "Arriving at ", "arriving at ", "Arrived at ", "arrived at ",
            "Arriving · ", "Arrived · ", "Arriving - ", "Arrived - ",
            "Arriving ", "arriving ", "Arrived ", "arrived ",
            "Bạn đã đến ", "bạn đã đến ", "Đã đến ", "đã đến "
        ];
        for (var p = 0; p < prefixes.size(); p++) {
            var pfx = prefixes[p];
            var pIdx = streetStr.find(pfx);
            if (pIdx != null && pIdx == 0) {
                streetStr = streetStr.substring(pfx.length(), streetStr.length());
                break;
            }
        }
        while (streetStr.length() > 0) {
            var fc = streetStr.substring(0, 1);
            if (fc.equals(" ") || fc.equals("-") || fc.equals(":") || fc.equals("·")) {
                streetStr = streetStr.substring(1, streetStr.length());
            } else if (streetStr.length() >= 3 && streetStr.substring(0, 3).toLower().equals("at ")) {
                streetStr = streetStr.substring(3, streetStr.length());
            } else {
                break;
            }
        }
        var dotPos = streetStr.find("·");
        while (dotPos != null) {
            streetStr = streetStr.substring(0, dotPos) + " " + streetStr.substring(dotPos + 1, streetStr.length());
            dotPos = streetStr.find("·");
        }

        // Smart Adaptive Address Layout (Balanced 2-line split if long)
        var maxCharsPerLine = (w <= 280) ? 13 : (isRound ? 15 : 17);
        var line1 = "";
        var line2 = "";

        if (streetStr.length() > maxCharsPerLine) {
            var targetIdx = streetStr.length() / 2;
            var bestSpace = -1;
            var minDist = 999;
            for (var s = 3; s < streetStr.length() - 3; s++) {
                if (streetStr.substring(s, s + 1).equals(" ")) {
                    var diff = s - targetIdx;
                    if (diff < 0) { diff = 0 - diff; }
                    var curL1Len = s;
                    var curL2Len = streetStr.length() - s - 1;
                    var penalty = 0;
                    if (curL1Len > maxCharsPerLine) { penalty += (curL1Len - maxCharsPerLine) * 15; }
                    if (curL2Len > maxCharsPerLine) { penalty += (curL2Len - maxCharsPerLine) * 15; }
                    var score = diff + penalty;
                    if (score < minDist) {
                        minDist = score;
                        bestSpace = s;
                    }
                }
            }
            if (bestSpace != -1) {
                line1 = streetStr.substring(0, bestSpace);
                line2 = streetStr.substring(bestSpace + 1, streetStr.length());
            } else {
                line1 = streetStr;
            }
            while (line2.length() > 0 && line2.substring(0, 1).equals(" ")) {
                line2 = line2.substring(1, line2.length());
            }
        } else {
            line1 = streetStr;
        }

        var maxTextW = isRound ? (w * 0.82).toNumber() : (w * 0.90).toNumber();
        var textX = (w - maxTextW) / 2;

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        if (line2.length() > 0) {
            var splitFont = isSmall 
                ? Graphics.FONT_XTINY
                : (isSfFontActive() ? ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_MEDIUM) : Graphics.FONT_MEDIUM);
            var hSplit = dc.getFontHeight(splitFont);
            var lineOffset = isSmall ? 8 : (isRound ? (18 * (w.toFloat() / 416.0)).toNumber() : 18);
            if (lineOffset < 8) { lineOffset = 8; }
            var curY1 = addrY - lineOffset - (hSplit / 2);
            var curY2 = addrY + lineOffset - (hSplit / 2);
            _drawMarqueeText(dc, line1, textX, curY1, maxTextW, splitFont, COLOR_TEXT_WHITE, true);
            _drawMarqueeText(dc, line2, textX, curY2, maxTextW, splitFont, COLOR_TEXT_WHITE, true);
        } else {
            // Single short line uses big bold font matching Init "Navigation IQ"
            var singleFont = isSmall ? fontDestTitle : ((streetStr.length() <= 14) ? fontDestTitle : fontDestSub);
            var hSingle = dc.getFontHeight(singleFont);
            var curY = addrY - (hSingle / 2);
            _drawMarqueeText(dc, line1, textX, curY, maxTextW, singleFont, COLOR_TEXT_WHITE, true);
        }

        // 5. Apple Watch Workout 3-Column Telemetry Card
        var bgCardCol = isSmall ? 0x1A1F29 : COLOR_BG_CARD;
        var borderCardCol = isSmall ? 0x667085 : COLOR_BORDER_CARD;
        var divLineCol = isSmall ? 0x444D5C : 0x222C3A;

        dc.setColor(bgCardCol, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cardX, cardY, cardW, cardH, cardRx);
        dc.setColor(borderCardCol, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(cardX, cardY, cardW, cardH, cardRx);

        // Hairline Vertical Dividers
        var colW = cardW / 3;
        var div1X = cardX + colW;
        var div2X = cardX + (colW * 2);
        dc.setColor(divLineCol, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(div1X, cardY + (isSmall ? 6 : 10), div1X, cardY + cardH - (isSmall ? 6 : 10));
        dc.drawLine(div2X, cardY + (isSmall ? 6 : 10), div2X, cardY + cardH - (isSmall ? 6 : 10));

        var valY = isSmall ? (cardY + 14) : (cardY + (cardH * 0.32).toNumber());
        var lblY = isSmall ? (cardY + 34) : (cardY + (cardH * 0.74).toNumber());

        var durStr = (CommManager.arrivedDuration.length() > 0 && !CommManager.arrivedDuration.equals("--")) 
                     ? CommManager.arrivedDuration 
                     : ((CommManager.etaText.length() > 0) ? CommManager.etaText : "--");

        var distStr = (CommManager.arrivedDistance.length() > 0 && !CommManager.arrivedDistance.equals("--")) 
                      ? CommManager.arrivedDistance 
                      : ((CommManager.distText.length() > 0) ? CommManager.distText : "--");

        var spdStr = (CommManager.arrivedAvgSpeed.length() > 0 && !CommManager.arrivedAvgSpeed.equals("--")) 
                     ? CommManager.arrivedAvgSpeed 
                     : "--";

        // Col 1: TIME
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cardX + (colW / 2), valY, fontCardVal, durStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cardX + (colW / 2), lblY, fontColLabel, "TIME", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Col 2: DISTANCE
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(div1X + (colW / 2), valY, fontCardVal, distStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(div1X + (colW / 2), lblY, fontColLabel, "DIST", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Col 3: SPEED
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(div2X + (colW / 2), valY, fontCardVal, spdStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(div2X + (colW / 2), lblY, fontColLabel, "SPEED", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // -------------------------------------------------------------------------
    // Unified Apple Watch Style Aero HUD with Ambient Glow Gradient
    // -------------------------------------------------------------------------
    private function _drawUnifiedAppleHUD(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var isLargeSquircle = (w >= 400);

        var barH = (h * 0.145).toNumber();
        if (barH < 36) { barH = 36; }
        if (isLargeSquircle) {
            if (barH > 58) { barH = 58; }
        } else {
            if (barH > 52) { barH = 52; }
        }

        var gap = (h > 300) ? 8 : 4;
        var barBottomGap = isLargeSquircle ? (h * 0.042).toNumber() : 0;
        var barSidePad = isLargeSquircle ? (w * 0.055).toNumber() : 0;
        var cardW = w;
        var cardH = h - barH - gap - barBottomGap;
        var cardX = 0;
        var cardY = 0;
        var barY = cardH + gap;


        var theme = getNavTheme(CommManager.direction);
        var accentColor = theme[0] as Number;
        var badgeBgColor = theme[1] as Number;
        var glowRGB = theme[2] as Array<Number>;
        var etaBgColor = theme[3] as Number;

        var badgeRadius = (cardW * 0.11).toNumber();
        if (isLargeSquircle) {
            if (badgeRadius > 42) { badgeRadius = 42; }
            if (badgeRadius < 32) { badgeRadius = 32; }
        } else {
            if (badgeRadius > 36) { badgeRadius = 36; }
            if (badgeRadius < 24) { badgeRadius = 24; }
        }

        var badgeCx = isLargeSquircle ? (cardW * 0.19).toNumber() : (cardX + (cardW * 0.16).toNumber());
        var badgeCy = isLargeSquircle ? (cardH * 0.17).toNumber() : (cardY + (cardH * 0.18).toNumber());

        VectorArrowRenderer.drawAmbientGlow(dc, badgeCx, badgeCy, glowRGB);

        dc.setColor(badgeBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(badgeCx, badgeCy, badgeRadius);

        if (CommManager.isWaitingImage) {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeRadius, accentColor, _animTick);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            VectorArrowRenderer.drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeRadius, accentColor, _animTick);
        }

        var distFull = CommManager.distText;
        if (distFull.length() > 0) {
            var parts = TextRenderer.splitDist(distFull, isSfNumberFontActive());
            var distNum = parts[0];
            var distUnit = parts[1];

            var numX = badgeCx + badgeRadius + (cardW * 0.05).toNumber();
            var numY = badgeCy;
            var numFont = _getDistanceFont(distNum, distUnit);

            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                numX, numY,
                numFont,
                distNum,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // Bold Silver Unit (km / m / mi / ft) prominently aligned to baseline
            var numWidth = dc.getTextWidthInPixels(distNum, numFont);
            if (distUnit.length() > 0) {
                var unitFont = isSfFontActive() ? ((_fontSfUnit != null) ? _fontSfUnit : Graphics.FONT_LARGE) : Graphics.FONT_LARGE;
                var numH = dc.getFontHeight(numFont);
                var unitH = dc.getFontHeight(unitFont);
                var unitOffsetY = ((numH - unitH) / 2) - 3;
                if (unitOffsetY < 0) { unitOffsetY = 0; }
                dc.setColor(COLOR_TEXT_UNIT, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    numX + numWidth + DIST_UNIT_GAP,
                    badgeCy + unitOffsetY,
                    unitFont,
                    distUnit,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }

        var divY = badgeCy + badgeRadius + (cardH * 0.06).toNumber();
        var divPaddingX = isLargeSquircle ? (cardW * 0.07).toNumber() : (cardW * 0.045).toNumber();
        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(cardX + divPaddingX, divY, cardX + cardW - divPaddingX, divY);

        var streetText = CommManager.navText;
        var navPadX = isLargeSquircle ? (cardW * 0.075).toNumber() : (cardW * 0.055).toNumber();
        if (navPadX < 18) { navPadX = 18; }
        var availTextH = cardH - (divY - cardY) - (cardH * 0.05).toNumber();
        if (availTextH < 20) { availTextH = 20; }

        if (streetText.length() > 0) {
            if (!isSfFontActive()) {
                streetText = TextRenderer.stripAccents(streetText);
            }
            _drawDynamicWrappedText(dc, cardX + navPadX, divY + 6, cardW - (navPadX * 2), availTextH, streetText, accentColor, false);
        }

        // Bottom bar: ETA + Live Clock (Floating Island Capsule for curved squircle)
        if (!CommManager.isToastActive()) {
            var barX = barSidePad;
            var barW = cardW - (barSidePad * 2);
            var barRadius = barH / 2;
            dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, barY, barW, barH, barRadius);
            if (!isLargeSquircle) {
                VectorArrowRenderer.maskCardCorners(dc, barX, barY, barW, barH, barRadius);
            }

            dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawRoundedRectangle(barX, barY, barW, barH, barRadius);

            var etaBadgePadX = (barW * 0.032).toNumber();
            if (etaBadgePadX < 6) { etaBadgePadX = 6; }
            var etaBadgeW = (barW * 0.44).toNumber();
            var etaBadgeH = (barH * 0.74).toNumber();
            var etaBadgeRadius = etaBadgeH / 2;
            var etaBadgeX = barX + etaBadgePadX;
            var etaBadgeY = barY + ((barH - etaBadgeH) / 2);

            dc.setColor(etaBgColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(etaBadgeX, etaBadgeY, etaBadgeW, etaBadgeH, etaBadgeRadius);

            dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawRoundedRectangle(etaBadgeX, etaBadgeY, etaBadgeW, etaBadgeH, etaBadgeRadius);

            var barCenterY = barY + (barH / 2);
            var microFont = isSfFontActive() ? (isLargeSquircle ? ((_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_TINY) : ((_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY)) : (isLargeSquircle ? Graphics.FONT_TINY : Graphics.FONT_XTINY);

            var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                etaBadgeX + (etaBadgeW / 2),
                barCenterY,
                microFont,
                etaStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // Center Bullet Dot: Exactly at the horizontal center of the card
            var dotX = barX + (barW / 2);
            dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dotX, barCenterY, 2.5);

            // Right Column: Live Clock centered in the right half of the card
            var clockTime = System.getClockTime();
            var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
            dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                dotX + ((barX + barW - dotX) / 2),
                barCenterY,
                microFont,
                timeStr,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    // -------------------------------------------------------------------------
    // Dynamic Font Scaling + Multi-Weight Typography
    // -------------------------------------------------------------------------
    private function _renderScrollingBlock(
        dc as Dc,
        block1 as Array,
        block2 as Array?,
        bounds as Array,
        accentColor as Number
    ) as Void {
        var lines1 = block1[0] as Array<String>;
        var font1 = block1[1] as Graphics.FontDefinition;
        var color1 = block1[2] as Number;
        var h1 = block1[3] as Number;

        var lines2 = (block2 != null) ? (block2[0] as Array<String>) : null;
        var font2 = (block2 != null) ? (block2[1] as Graphics.FontDefinition) : null;
        var color2 = (block2 != null) ? (block2[2] as Number) : null;
        var h2 = (block2 != null) ? (block2[3] as Number) : null;

        var startX = bounds[0] as Number;
        var startY = bounds[1] as Number;
        var maxWidth = bounds[2] as Number;
        var maxHeight = bounds[3] as Number;
        var isCenter = (bounds.size() > 4) ? (bounds[4] as Boolean) : false;

        var drawX = isCenter ? (startX + (maxWidth / 2)) : startX;
        var textJustify = isCenter ? (Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER) : (Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var count1 = lines1.size();
        var count2 = (lines2 != null) ? lines2.size() : 0;
        var totalH = (count1 * h1) + (count2 * ((h2 != null) ? h2 : 0));

        if (totalH <= maxHeight) {
            var curY = startY + (maxHeight - totalH) / 2 - 4;
            dc.setColor(color1, Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < count1; i++) {
                dc.drawText(drawX, curY + (h1 / 2), font1, lines1[i], textJustify);
                curY += h1;
            }
            if (lines2 != null && font2 != null && color2 != null && h2 != null) {
                dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
                for (var j = 0; j < count2; j++) {
                    dc.drawText(drawX, curY + (h2 / 2), font2, lines2[j], textJustify);
                    curY += h2;
                }
            }
            return;
        }

        if (dc has :setClip) {
            dc.setClip(startX - 2, startY, maxWidth + 4, maxHeight);
        }

        var overflow = totalH - maxHeight + 12;
        var cycle = _animTick % 70;
        var scrollOffset = 0;

        if (cycle < 15) {
            scrollOffset = 0;
        } else if (cycle < 35) {
            var progress = (cycle - 15).toFloat() / 20.0;
            scrollOffset = (progress * overflow).toNumber();
        } else if (cycle < 50) {
            scrollOffset = overflow;
        } else {
            var progress = (cycle - 50).toFloat() / 20.0;
            scrollOffset = ((1.0 - progress) * overflow).toNumber();
        }

        var curY = startY + 4 - scrollOffset;
        dc.setColor(color1, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < count1; i++) {
            dc.drawText(drawX, curY + (h1 / 2), font1, lines1[i], textJustify);
            curY += h1;
        }
        if (lines2 != null && font2 != null && color2 != null && h2 != null) {
            dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
            for (var j = 0; j < count2; j++) {
                dc.drawText(drawX, curY + (h2 / 2), font2, lines2[j], textJustify);
                curY += h2;
            }
        }

        if (dc has :clearClip) {
            dc.clearClip();
        }

        if (!CommManager.isToastActive()) {
            var barX = startX + maxWidth - 3;
            var barTrackH = maxHeight - 16;
            var thumbH = (maxHeight.toFloat() / totalH.toFloat() * barTrackH).toNumber();
            if (thumbH < 10) { thumbH = 10; }
            var thumbY = startY + 8 + ((scrollOffset.toFloat() / overflow.toFloat()) * (barTrackH - thumbH)).toNumber();
            dc.setColor(0x27272A, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, startY + 8, 2, barTrackH, 1);
            dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, thumbY, 2, thumbH, 1);
        }
    }

    private function _drawDynamicWrappedText(dc as Dc, startX as Number, startY as Number, maxWidth as Number, maxHeight as Number, text as String, accentColor as Number, isCenter as Boolean) as Void {
        var parts = TextRenderer.splitActionAndStreet(text);
        var actionText = parts[0];
        var streetText = parts[1];

        var fontActionBold;
        var fontStreetReg;
        var fontCompactBold;
        var fontCompactReg;
        var isLargeSquircle = (dc.getWidth() >= 400);
        if (isSfFontActive()) {
            if (isLargeSquircle) {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontActionBold = (_fontSfLargeBold != null) ? _fontSfLargeBold : Graphics.FONT_LARGE;
                    fontStreetReg = (_fontSfLarge != null) ? _fontSfLarge : ((_fontSfLargeBold != null) ? _fontSfLargeBold : Graphics.FONT_LARGE);
                    fontCompactBold = (_fontSfLargeBold != null) ? _fontSfLargeBold : Graphics.FONT_LARGE;
                    fontCompactReg = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                } else if (_textPreset == 2) {
                    fontActionBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                    fontStreetReg = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL;
                    fontCompactBold = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL;
                    fontCompactReg = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_TINY;
                } else {
                    fontActionBold = (_fontSfLargeBold != null) ? _fontSfLargeBold : Graphics.FONT_LARGE;
                    fontStreetReg = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                    fontCompactBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                    fontCompactReg = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL;
                }
            } else {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontActionBold = (_fontSfLargeBold != null) ? _fontSfLargeBold : ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM);
                    fontStreetReg = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                    fontCompactBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                    fontCompactReg = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL;
                } else if (_textPreset == 2) {
                    fontActionBold = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_TINY;
                    fontStreetReg = (_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY;
                    fontCompactBold = (_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY;
                    fontCompactReg = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_XTINY;
                } else {
                    fontActionBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_SMALL;
                    fontStreetReg = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_TINY;
                    fontCompactBold = (_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY;
                    fontCompactReg = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_XTINY;
                }
            }
        } else {
            if (isLargeSquircle) {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontActionBold = Graphics.FONT_LARGE;
                    fontStreetReg = Graphics.FONT_LARGE;
                    fontCompactBold = Graphics.FONT_LARGE;
                    fontCompactReg = Graphics.FONT_MEDIUM;
                } else if (_textPreset == 2) {
                    fontActionBold = Graphics.FONT_MEDIUM;
                    fontStreetReg = Graphics.FONT_SMALL;
                    fontCompactBold = Graphics.FONT_SMALL;
                    fontCompactReg = Graphics.FONT_TINY;
                } else {
                    fontActionBold = Graphics.FONT_LARGE;
                    fontStreetReg = Graphics.FONT_MEDIUM;
                    fontCompactBold = Graphics.FONT_MEDIUM;
                    fontCompactReg = Graphics.FONT_SMALL;
                }
            } else {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontActionBold = Graphics.FONT_LARGE;
                    fontStreetReg = Graphics.FONT_MEDIUM;
                    fontCompactBold = Graphics.FONT_MEDIUM;
                    fontCompactReg = Graphics.FONT_SMALL;
                } else if (_textPreset == 2) {
                    fontActionBold = Graphics.FONT_SMALL;
                    fontStreetReg = Graphics.FONT_TINY;
                    fontCompactBold = Graphics.FONT_TINY;
                    fontCompactReg = Graphics.FONT_XTINY;
                } else {
                    fontActionBold = Graphics.FONT_MEDIUM;
                    fontStreetReg = Graphics.FONT_SMALL;
                    fontCompactBold = Graphics.FONT_SMALL;
                    fontCompactReg = Graphics.FONT_TINY;
                }
            }
        }

        var bounds = [startX, startY, maxWidth, maxHeight, isCenter] as Array;

        if (streetText.length() == 0) {
            var linesStreet = TextRenderer.wrapWithFont(dc, actionText, fontActionBold, maxWidth);
            var fontHStreet = dc.getFontHeight(fontActionBold) + 2;
            if (linesStreet.size() <= 2 && (linesStreet.size() * fontHStreet) <= maxHeight) {
                _renderScrollingBlock(dc, [linesStreet, fontActionBold, Graphics.COLOR_WHITE, fontHStreet], null, bounds, accentColor);
                return;
            }

            var linesCompact = TextRenderer.wrapWithFont(dc, actionText, fontCompactBold, maxWidth);
            var fontHCompact = dc.getFontHeight(fontCompactBold) + 2;
            _renderScrollingBlock(dc, [linesCompact, fontCompactBold, Graphics.COLOR_WHITE, fontHCompact], null, bounds, accentColor);
            return;
        }

        var linesAct = TextRenderer.wrapWithFont(dc, actionText, fontActionBold, maxWidth);
        var linesStr = TextRenderer.wrapWithFont(dc, streetText, fontStreetReg, maxWidth);
        var hAct = dc.getFontHeight(fontActionBold) + 2;
        var hStr = dc.getFontHeight(fontStreetReg) + 2;
        var totalH = (linesAct.size() * hAct) + (linesStr.size() * hStr);

        if (totalH <= maxHeight) {
            _renderScrollingBlock(dc, [linesAct, fontActionBold, Graphics.COLOR_WHITE, hAct], [linesStr, fontStreetReg, 0xE4E4E7, hStr], bounds, accentColor);
            return;
        }

        linesAct = TextRenderer.wrapWithFont(dc, actionText, fontCompactBold, maxWidth);
        linesStr = TextRenderer.wrapWithFont(dc, streetText, fontCompactReg, maxWidth);
        hAct = dc.getFontHeight(fontCompactBold) + 2;
        hStr = dc.getFontHeight(fontCompactReg) + 2;

        _renderScrollingBlock(dc, [linesAct, fontCompactBold, Graphics.COLOR_WHITE, hAct], [linesStr, fontCompactReg, 0xE4E4E7, hStr], bounds, accentColor);
    }

    // -------------------------------------------------------------------------
    // Global In-App Notification Toast Overlay (Top-level Layer)
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // Horizontal Marquee Text Renderer (Auto-scrolls when text overflows)
    // -------------------------------------------------------------------------
    private function _drawMarqueeText(dc as Dc, text as String, x as Number, y as Number, width as Number, font as Graphics.FontDefinition, color as Number, isCenter as Boolean) as Void {
        var textW = dc.getTextWidthInPixels(text, font);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (textW <= width) {
            if (isCenter) {
                dc.drawText(x + (width / 2), y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
            } else {
                dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);
            }
            return;
        }

        // Horizontal Marquee Scrolling when text exceeds available width
        var fontH = dc.getFontHeight(font);
        if (dc has :setClip) {
            dc.setClip(x, y - 1, width, fontH + 2);
        }

        var overflow = textW - width;
        var cycle = _animTick % 45; // 45 ticks * 200ms = 9.0s cycle
        var scrollOffset = 0;

        if (cycle < 10) {
            // Pause 2.0s at start for clear initial reading
            scrollOffset = 0;
        } else if (cycle < 32) {
            // Smoothly scroll across 4.4s
            var progress = (cycle - 10).toFloat() / 22.0;
            scrollOffset = (progress * overflow).toNumber();
        } else if (cycle < 38) {
            // Pause 1.2s at end of text
            scrollOffset = overflow;
        } else {
            // Smooth return to start across 1.4s
            var progress = (cycle - 38).toFloat() / 7.0;
            scrollOffset = ((1.0 - progress) * overflow).toNumber();
        }

        dc.drawText(x - scrollOffset, y, font, text, Graphics.TEXT_JUSTIFY_LEFT);

        if (dc has :clearClip) {
            dc.clearClip();
        }
    }

    // -------------------------------------------------------------------------
    // Global In-App Notification Toast Overlay (Top-level Layer)
    // -------------------------------------------------------------------------
    private function _drawToastOverlay(dc as Dc, effectiveProfile as Number) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var appName = CommManager.toastAppName;
        var sender = CommManager.toastSender;
        var message = CommManager.toastMessage;

        var headerText = (appName.length() > 0 && sender.length() > 0) ? (appName + " - " + sender) : (appName.length() > 0 ? appName : sender);
        if (!isSfFontActive()) {
            headerText = TextRenderer.stripAccents(headerText);
            message = TextRenderer.stripAccents(message);
        }

        var isMono = (effectiveProfile == 3);
        var isRound = (effectiveProfile == 2);
        var isAmoled = (w > 280) && !isMono;

        var accentBorder = isMono ? Graphics.COLOR_WHITE : 0x38BDF8;
        var headerColor = isMono ? Graphics.COLOR_WHITE : 0x38BDF8;
        var cardBg = isAmoled ? 0x24252B : Graphics.COLOR_BLACK;

        var isLargeSquircle = (w >= 400);
        var fontHeader = isMono ? Graphics.FONT_XTINY : (isSfFontActive() ? (isLargeSquircle ? ((_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY) : ((_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY)) : (isLargeSquircle ? Graphics.FONT_TINY : Graphics.FONT_XTINY));
        var fontBody = isMono ? Graphics.FONT_XTINY : (isSfFontActive() ? (isLargeSquircle ? ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL) : ((_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_TINY)) : (isLargeSquircle ? Graphics.FONT_SMALL : Graphics.FONT_XTINY));

        var hHeader = dc.getFontHeight(fontHeader);
        var hBody = dc.getFontHeight(fontBody);

        var toastW;
        var toastH;
        var toastX;
        var toastY;
        var contentW;
        var padY;
        var cornerR;

        if (isRound) {
            // Round screen: Overlay across lower-mid area (covers lower street text, perfectly preserves action text above)
            toastW = (w * 0.83).toNumber();
            toastX = (w - toastW) / 2;
            toastY = (h * 0.51).toNumber();
            contentW = toastW - 16;

            var msgLines = TextRenderer.wrapWithFont(dc, message, fontBody, contentW);
            var numLines = (msgLines.size() > 2) ? 2 : (msgLines.size() > 0 ? msgLines.size() : 1);
            var minRoundH = (h * 0.245).toNumber();
            toastH = hHeader + (numLines * (hBody + 2)) + 18;
            if (toastH < minRoundH) {
                toastH = minRoundH;
            }
            cornerR = 12;
            padY = (toastH - (hHeader + (numLines * (hBody + 2)))) / 2;
            if (padY < 5) { padY = 5; }

            // Background card & modern border
            dc.setColor(cardBg, Graphics.COLOR_TRANSPARENT);
            if (dc has :fillRoundedRectangle) {
                dc.fillRoundedRectangle(toastX, toastY, toastW, toastH, cornerR);
            } else {
                dc.fillRectangle(toastX, toastY, toastW, toastH);
            }

            // Draw border only on MIP/Mono screens where card background matches screen black
            if (!isAmoled) {
                dc.setColor(accentBorder, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                if (dc has :drawRoundedRectangle) {
                    dc.drawRoundedRectangle(toastX, toastY, toastW, toastH, cornerR);
                } else {
                    dc.drawRectangle(toastX, toastY, toastW, toastH);
                }
            }

            var contentX = toastX + ((toastW - contentW) / 2);

            // Header (App - Sender) with marquee support
            _drawMarqueeText(dc, headerText, contentX, toastY + padY, contentW, fontHeader, headerColor, true);

            // Body message with auto-marquee when overflowing
            var curTextY = toastY + padY + hHeader + 2;
            if (msgLines.size() <= 1) {
                var singleLine = (msgLines.size() == 1) ? msgLines[0] : message;
                _drawMarqueeText(dc, singleLine, contentX, curTextY, contentW, fontBody, COLOR_TEXT_WHITE, true);
            } else if (msgLines.size() == 2) {
                _drawMarqueeText(dc, msgLines[0], contentX, curTextY, contentW, fontBody, COLOR_TEXT_WHITE, true);
                _drawMarqueeText(dc, msgLines[1], contentX, curTextY + (hBody + 2), contentW, fontBody, COLOR_TEXT_WHITE, true);
            } else {
                var line0 = msgLines[0];
                var rest = "";
                if (message.length() > line0.length()) {
                    rest = message.substring(line0.length(), message.length());
                    while (rest.length() > 0 && rest.substring(0, 1).equals(" ")) {
                        rest = rest.substring(1, rest.length());
                    }
                }
                _drawMarqueeText(dc, line0, contentX, curTextY, contentW, fontBody, COLOR_TEXT_WHITE, true);
                _drawMarqueeText(dc, rest, contentX, curTextY + (hBody + 2), contentW, fontBody, COLOR_TEXT_WHITE, true);
            }
            return;
        }

        if (isMono) {
            // Instinct Mono: Overlay at lower portion of text zone
            toastW = w - 30;
            toastX = (w - toastW) / 2;
            contentW = toastW - 12;

            var msgLines = TextRenderer.wrapWithFont(dc, message, fontBody, contentW);
            var numLines = (msgLines.size() > 2) ? 2 : (msgLines.size() > 0 ? msgLines.size() : 1);
            toastH = hHeader + (numLines * (hBody + 1)) + 16;
            if (toastH < 46) { toastH = 46; }
            toastY = h - toastH - 8;
            padY = (toastH - (hHeader + (numLines * (hBody + 1)))) / 2;
            if (padY < 3) { padY = 3; }

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(toastX, toastY, toastW, toastH);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawRectangle(toastX, toastY, toastW, toastH);

            var contentX = toastX + ((toastW - contentW) / 2);
            _drawMarqueeText(dc, headerText, contentX, toastY + padY, contentW, fontHeader, headerColor, true);

            var curTextY = toastY + padY + hHeader + 1;
            if (msgLines.size() <= 1) {
                var singleLine = (msgLines.size() == 1) ? msgLines[0] : message;
                _drawMarqueeText(dc, singleLine, contentX, curTextY, contentW, fontBody, Graphics.COLOR_WHITE, true);
            } else if (msgLines.size() == 2) {
                _drawMarqueeText(dc, msgLines[0], contentX, curTextY, contentW, fontBody, Graphics.COLOR_WHITE, true);
                _drawMarqueeText(dc, msgLines[1], contentX, curTextY + (hBody + 1), contentW, fontBody, Graphics.COLOR_WHITE, true);
            } else {
                var line0 = msgLines[0];
                var rest = "";
                if (message.length() > line0.length()) {
                    rest = message.substring(line0.length(), message.length());
                    while (rest.length() > 0 && rest.substring(0, 1).equals(" ")) {
                        rest = rest.substring(1, rest.length());
                    }
                }
                _drawMarqueeText(dc, line0, contentX, curTextY, contentW, fontBody, Graphics.COLOR_WHITE, true);
                _drawMarqueeText(dc, rest, contentX, curTextY + (hBody + 1), contentW, fontBody, Graphics.COLOR_WHITE, true);
            }
            return;
        }

        // Rectangular Screen (Venu Sq 2, Venu X1): Overlay with Squircle Safe Inset
        toastW = isLargeSquircle ? (w * 0.88).toNumber() : (w * 0.98).toNumber();
        toastX = (w - toastW) / 2;
        contentW = toastW - (isLargeSquircle ? 24 : 16);
        var msgLines = TextRenderer.wrapWithFont(dc, message, fontBody, contentW);
        var numLines = (msgLines.size() > 2) ? 2 : (msgLines.size() > 0 ? msgLines.size() : 1);
        toastH = hHeader + (numLines * (hBody + 2)) + (isLargeSquircle ? 26 : 22);
        var minToastH = isLargeSquircle ? 76 : 64;
        if (toastH < minToastH) { toastH = minToastH; }
        var bottomInset = isLargeSquircle ? (h * 0.045).toNumber() : 2;
        toastY = h - toastH - bottomInset;
        cornerR = isLargeSquircle ? 20 : 12;
        padY = (toastH - (hHeader + (numLines * (hBody + 2)))) / 2;
        if (padY < 4) { padY = 4; }

        dc.setColor(cardBg, Graphics.COLOR_TRANSPARENT);
        if (dc has :fillRoundedRectangle) {
            dc.fillRoundedRectangle(toastX, toastY, toastW, toastH, cornerR);
        } else {
            dc.fillRectangle(toastX, toastY, toastW, toastH);
        }

        // Draw border only on MIP/Mono screens where card background matches screen black
        if (!isAmoled) {
            dc.setColor(accentBorder, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            if (dc has :drawRoundedRectangle) {
                dc.drawRoundedRectangle(toastX, toastY, toastW, toastH, cornerR);
            } else {
                dc.drawRectangle(toastX, toastY, toastW, toastH);
            }
        }

        var contentX = toastX + ((toastW - contentW) / 2);
        _drawMarqueeText(dc, headerText, contentX, toastY + padY, contentW, fontHeader, headerColor, true);

        var curTextY = toastY + padY + hHeader + 2;
        if (msgLines.size() <= 1) {
            var singleLine = (msgLines.size() == 1) ? msgLines[0] : message;
            _drawMarqueeText(dc, singleLine, contentX, curTextY, contentW, fontBody, COLOR_TEXT_WHITE, true);
        } else if (msgLines.size() == 2) {
            _drawMarqueeText(dc, msgLines[0], contentX, curTextY, contentW, fontBody, COLOR_TEXT_WHITE, true);
            _drawMarqueeText(dc, msgLines[1], contentX, curTextY + (hBody + 2), contentW, fontBody, COLOR_TEXT_WHITE, true);
        } else {
            var line0 = msgLines[0];
            var rest = "";
            if (message.length() > line0.length()) {
                rest = message.substring(line0.length(), message.length());
                while (rest.length() > 0 && rest.substring(0, 1).equals(" ")) {
                    rest = rest.substring(1, rest.length());
                }
            }
            _drawMarqueeText(dc, line0, contentX, curTextY, contentW, fontBody, COLOR_TEXT_WHITE, true);
            _drawMarqueeText(dc, rest, contentX, curTextY + (hBody + 2), contentW, fontBody, COLOR_TEXT_WHITE, true);
        }
    }

    // -------------------------------------------------------------------------
    // Landscape Mode HUD (90° Clockwise)
    // -------------------------------------------------------------------------
    private function _drawLandscapeHUD(dc as Dc) as Void {
        var theme = getNavTheme(CommManager.direction);
        var accentColor = theme[0] as Number;
        var badgeBgColor = theme[1] as Number;
        var glowRGB = theme[2] as Array<Number>;
        var etaBgColor = theme[3] as Number;

        var cardPx = 68;
        var cardPy = 0;
        var cardPw = 252;
        var cardPh = 360;
        var cardR = 26;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cardPx, cardPy, cardPw, cardPh, cardR);

        var badgeVx = 48;
        var badgeVy = 48;
        var badgeR = 34;
        var badgePx = 360 - badgeVy - 24;
        var badgePy = badgeVx;

        VectorArrowRenderer.drawAmbientGlow(dc, badgePx, badgePy, glowRGB);
        VectorArrowRenderer.maskCardCorners(dc, cardPx, cardPy, cardPw, cardPh, cardR);

        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(cardPx, cardPy, cardPw, cardPh, cardR);

        dc.setColor(badgeBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(badgePx, badgePy, badgeR);

        if (CommManager.isWaitingImage) {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgePx, badgePy, badgeR, accentColor, _animTick);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrowRot90(dc, badgePx, badgePy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgePx, badgePy, badgeR, accentColor, _animTick);
        }

        var distFull = CommManager.distText;
        if (distFull.length() > 0) {
            var parts = TextRenderer.splitDist(distFull, isSfNumberFontActive());
            var distNum = parts[0];
            var distUnit = parts[1];

            var numFontRot = (_fontSfStreetBoldRot90 != null) ? _fontSfStreetBoldRot90 : _fontSfStreetBold;
            var numFontUp = (_fontSfStreetBold != null) ? _fontSfStreetBold : numFontRot;
            var numX = 98;
            var numY = 48;

            TextRenderer.drawRot90String(dc, numX, numY, numFontRot, numFontUp, distNum, COLOR_TEXT_WHITE);

            var numW = TextRenderer.measureRot90String(dc, numFontUp, distNum);
            if (distUnit.length() > 0) {
                var unitFontRot = (_fontSfStreetRot90 != null) ? _fontSfStreetRot90 : _fontSfStreet;
                var unitFontUp = (_fontSfStreet != null) ? _fontSfStreet : unitFontRot;
                TextRenderer.drawRot90String(dc, numX + numW + 4, numY, unitFontRot, unitFontUp, distUnit, COLOR_TEXT_UNIT);
            }
        }

        var fontActionRot = (_fontSfStreetBoldRot90 != null) ? _fontSfStreetBoldRot90 : _fontSfStreetBold;
        var fontActionUp = (_fontSfStreetBold != null) ? _fontSfStreetBold : fontActionRot;
        var fontStreetRot = (_fontSfStreetRot90 != null) ? _fontSfStreetRot90 : _fontSfStreet;
        var fontStreetUp = (_fontSfStreet != null) ? _fontSfStreet : fontStreetRot;

        var fullText = CommManager.navText;
        if (fullText.length() > 0) {
            var parts = TextRenderer.splitActionAndStreet(fullText);
            var actionStr = parts[0];
            var streetStr = parts[1];

            var actionLines = (actionStr.length() > 0) ? TextRenderer.wrapWithRot90Font(dc, actionStr, fontActionUp, 332) : [] as Array<String>;
            var streetLines = (streetStr.length() > 0) ? TextRenderer.wrapWithRot90Font(dc, streetStr, fontStreetUp, 332) : [] as Array<String>;
            var hAct = 28;
            var hStr = 24;
            var totalH = (actionLines.size() * hAct) + (streetLines.size() * hStr);
            var maxHeight = 124;

            if (totalH <= maxHeight) {
                var curVy = 120 + (maxHeight - totalH) / 2 + 10;
                for (var al = 0; al < actionLines.size(); al++) {
                    TextRenderer.drawRot90String(dc, 14, curVy, fontActionRot, fontActionUp, actionLines[al], COLOR_TEXT_WHITE);
                    curVy += hAct;
                }
                for (var sl = 0; sl < streetLines.size(); sl++) {
                    TextRenderer.drawRot90String(dc, 14, curVy, fontStreetRot, fontStreetUp, streetLines[sl], COLOR_TEXT_SILVER);
                    curVy += hStr;
                }
            } else {
                if (dc has :setClip) {
                    dc.setClip(75, 0, 124, 360);
                }

                var overflow = totalH - maxHeight + 12;
                var cycle = _animTick % 70;
                var scrollOffset = 0;

                if (cycle < 15) {
                    scrollOffset = 0;
                } else if (cycle < 35) {
                    var progress = (cycle - 15).toFloat() / 20.0;
                    scrollOffset = (progress * overflow).toNumber();
                } else if (cycle < 50) {
                    scrollOffset = overflow;
                } else {
                    var progress = (cycle - 50).toFloat() / 20.0;
                    scrollOffset = ((1.0 - progress) * overflow).toNumber();
                }

                var curVy = 124 + 10 - scrollOffset;
                for (var al = 0; al < actionLines.size(); al++) {
                    TextRenderer.drawRot90String(dc, 14, curVy, fontActionRot, fontActionUp, actionLines[al], COLOR_TEXT_WHITE);
                    curVy += hAct;
                }
                for (var sl = 0; sl < streetLines.size(); sl++) {
                    TextRenderer.drawRot90String(dc, 14, curVy, fontStreetRot, fontStreetUp, streetLines[sl], COLOR_TEXT_SILVER);
                    curVy += hStr;
                }

                if (dc has :clearClip) {
                    dc.clearClip();
                }
            }
        }

        var barPx = 0;
        var barPy = 0;
        var barPw = 68;
        var barPh = 360;
        var barR = 26;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barPx, barPy, barPw, barPh, barR);
        VectorArrowRenderer.maskCardCorners(dc, barPx, barPy, barPw, barPh, barR);

        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(barPx, barPy, barPw, barPh, barR);

        var etaCapsulePx = 11;
        var etaCapsulePy = 12;
        var etaCapsulePw = 44;
        var etaCapsulePh = 146;
        var etaCapsuleR = 22;

        dc.setColor(etaBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(etaCapsulePx, etaCapsulePy, etaCapsulePw, etaCapsulePh, etaCapsuleR);
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(etaCapsulePx, etaCapsulePy, etaCapsulePw, etaCapsulePh, etaCapsuleR);

        var fontMicroRot = (_fontSfMicroRot90 != null) ? _fontSfMicroRot90 : _fontSfMicro;
        var fontMicroUp = (_fontSfMicro != null) ? _fontSfMicro : fontMicroRot;
        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
        var etaW = TextRenderer.measureRot90String(dc, fontMicroUp, etaStr);
        var etaVx = 12 + (146 - etaW) / 2;
        TextRenderer.drawRot90String(dc, etaVx, 296, fontMicroRot, fontMicroUp, etaStr, COLOR_TEXT_WHITE);

        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(33, 200, 2);

        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        var clockW = TextRenderer.measureRot90String(dc, fontMicroUp, timeStr);
        var clockVx = 346 - clockW;
        TextRenderer.drawRot90String(dc, clockVx, 296, fontMicroRot, fontMicroUp, timeStr, COLOR_TEXT_SILVER);
    }

    // -------------------------------------------------------------------------
    // Instinct Crossover HUD
    // -------------------------------------------------------------------------
    private function _drawInstinctCrossoverHUD(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // 1. Badge (turn arrow) - precisely placed inside device sub-window
        var isCrossover = (WatchUi.View has :setClockHandPosition);
        var badgeCx = isCrossover ? 138 : 144;
        var badgeCy = isCrossover ? 33 : 31;
        var badgeR = isCrossover ? 23 : 26;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(badgeCx, badgeCy, badgeR);

        if (CommManager.isWaitingImage) {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, Graphics.COLOR_WHITE, _animTick);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            VectorArrowRenderer.drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, Graphics.COLOR_WHITE);
        } else {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, Graphics.COLOR_WHITE, _animTick);
        }

        // 2. Top Left Area: Distance (Row 1) & ETA (Row 2) with safe left padding
        var leftMargin = isCrossover ? 16 : 20;
        var distFull = CommManager.distText;
        var distNum = "";
        var distUnit = "";
        if (distFull.length() > 0) {
            var parts = TextRenderer.splitDist(distFull, false);
            distNum = parts[0];
            distUnit = parts[1];
        }

        var numFont = Graphics.FONT_NUMBER_MILD;
        if (_textPreset == 2 || _textPreset == 3) {
            numFont = (distNum.length() <= 3) ? Graphics.FONT_NUMBER_HOT : Graphics.FONT_NUMBER_MILD;
        } else if (distNum.length() > 3) {
            numFont = Graphics.FONT_LARGE;
        }

        // Row 1: Distance
        if (distNum.length() > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(leftMargin, 24, numFont, distNum, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var numWidth = dc.getTextWidthInPixels(distNum, numFont);
            if (distUnit.length() > 0) {
                dc.drawText(leftMargin + numWidth + 3, 26, Graphics.FONT_SMALL, distUnit, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // Row 2: ETA (Compact display cleanly avoiding sub-window bounding box)
        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
        dc.setColor(0xE4E4E7, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftMargin, 50, Graphics.FONT_XTINY, etaStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Divider line(s) - Instinct Crossover has physical watch hands zone, Instinct 2 has none!
        var textZoneTop;
        var textZoneH;

        if (isCrossover) {
            var divY1 = 70;
            var divY2 = 102;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(8, divY1, w - 8, divY1);
            dc.drawLine(8, divY2, w - 8, divY2);
            textZoneTop = divY2 + 3;
            textZoneH = h - textZoneTop - 3;
        } else {
            // Instinct 2: No analog hands! Single clean divider at Y=64, dedicating 105px to navigation text!
            var divY = 64;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawLine(8, divY, w - 8, divY);
            textZoneTop = divY + 3;
            textZoneH = h - textZoneTop - 3;
        }

        // 4. Bottom Navigation Text Zone (100% dedicated to instructions or incoming message)
        var rawNavText = CommManager.navText;
        if (rawNavText.length() > 0) {
            // Strip accents so Vietnamese renders cleanly on Instinct system fonts
            var streetText = TextRenderer.stripAccents(rawNavText);

            var fontBold = Graphics.FONT_SMALL;
            var fontStreet = Graphics.FONT_TINY;
            if (_textPreset == 1 || _textPreset == 3) {
                fontBold = Graphics.FONT_MEDIUM;
                fontStreet = Graphics.FONT_SMALL;
            } else if (_textPreset == 2) {
                fontBold = Graphics.FONT_TINY;
                fontStreet = Graphics.FONT_XTINY;
            }
            var maxW = w - 30;

            var parts = TextRenderer.splitActionAndStreet(streetText);
            var actionText = parts[0];
            var street = parts[1];

            var linesAct = TextRenderer.wrapWithFont(dc, actionText, fontBold, maxW);
            var linesStr = (street.length() > 0) ? TextRenderer.wrapWithFont(dc, street, fontStreet, maxW) : [] as Array<String>;

            var hAct = dc.getFontHeight(fontBold) + 1;
            var hStr = dc.getFontHeight(fontStreet) + 1;
            var totalTextH = (linesAct.size() * hAct) + (linesStr.size() * hStr);

            if (totalTextH <= textZoneH) {
                var curY = textZoneTop + (textZoneH - totalTextH) / 2;
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                for (var i = 0; i < linesAct.size(); i++) {
                    dc.drawText(w / 2, curY, fontBold, linesAct[i], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hAct;
                }

                dc.setColor(0xE4E4E7, Graphics.COLOR_TRANSPARENT);
                for (var j = 0; j < linesStr.size(); j++) {
                    dc.drawText(w / 2, curY, fontStreet, linesStr[j], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hStr;
                }
            } else {
                // Smooth vertical auto-scroll when text is long
                if (dc has :setClip) {
                    dc.setClip(2, textZoneTop, w - 4, textZoneH);
                }

                var overflow = totalTextH - textZoneH + 6;
                var cycle = _animTick % 36;
                var scrollOffset = 0;

                if (cycle < 10) {
                    scrollOffset = 0;
                } else if (cycle < 24) {
                    var progress = (cycle - 10).toFloat() / 14.0;
                    scrollOffset = (progress * overflow).toNumber();
                } else if (cycle < 30) {
                    scrollOffset = overflow;
                } else {
                    var progress = (cycle - 30).toFloat() / 6.0;
                    scrollOffset = ((1.0 - progress) * overflow).toNumber();
                }

                var curY = textZoneTop + 2 - scrollOffset;

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                for (var i = 0; i < linesAct.size(); i++) {
                    dc.drawText(w / 2, curY, fontBold, linesAct[i], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hAct;
                }

                dc.setColor(0xE4E4E7, Graphics.COLOR_TRANSPARENT);
                for (var j = 0; j < linesStr.size(); j++) {
                    dc.drawText(w / 2, curY, fontStreet, linesStr[j], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hStr;
                }

                if (dc has :clearClip) {
                    dc.clearClip();
                }

                // Vertical scrollbar indicator on right edge
                var barTrackH = textZoneH - 12;
                var thumbH = (textZoneH.toFloat() / totalTextH.toFloat() * barTrackH).toNumber();
                if (thumbH < 6) { thumbH = 6; }
                var thumbY = textZoneTop + 6 + ((scrollOffset.toFloat() / overflow.toFloat()) * (barTrackH - thumbH)).toNumber();

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawLine(w - 4, thumbY, w - 4, thumbY + thumbH);
            }
        }
    }

    private function _drawInstinctIdleScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var isConnected = CommManager.isConnected() || (CommManager.rxCount > 0);
        var statusStr = isConnected ? "Connected" : "Ready";

        // Right sub-window circle (status icon, Crossover: 138, 33, 23; Instinct 2: 144, 31, 26)
        var isCrossover = (WatchUi.View has :setClockHandPosition);
        var subCx = isCrossover ? 138 : 144;
        var subCy = isCrossover ? 33 : 31;
        var subR = isCrossover ? 23 : 26;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(subCx, subCy, subR);

        // Navigation arrow icon inside sub-window
        dc.fillPolygon([
            [subCx, subCy - 12],
            [subCx + 9, subCy + 8],
            [subCx, subCy + 3],
            [subCx - 9, subCy + 8]
        ]);

        var leftMargin = isCrossover ? 16 : 20;
        // Left area: App Title & Connection status
        dc.drawText(leftMargin, 22, Graphics.FONT_TINY, "Navigation IQ", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(leftMargin, 46, Graphics.FONT_XTINY, statusStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        if (isCrossover) {
            dc.drawLine(8, 70, w - 8, 70);
            dc.drawLine(8, 102, w - 8, 102);
            var clock = System.getClockTime();
            var timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);
            dc.drawText(w / 2, 116, Graphics.FONT_SMALL, "Waiting Nav...", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, 146, Graphics.FONT_TINY, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawLine(8, 64, w - 8, 64);
            var clock = System.getClockTime();
            var timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);
            dc.drawText(w / 2, 88, Graphics.FONT_MEDIUM, "Waiting Nav...", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(w / 2, 128, Graphics.FONT_SMALL, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        }

        var h = dc.getHeight();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - 14, Graphics.FONT_XTINY, APP_VERSION_STR, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // -------------------------------------------------------------------------
    // Round Screen Responsive HUD
    // -------------------------------------------------------------------------
    private function _drawRoundHUD(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var theme = getNavTheme(CommManager.direction);
        var accentColor = theme[0] as Number;
        var badgeBgColor = theme[1] as Number;
        var glowRGB = theme[2] as Array<Number>;

        var isTiny = (w <= 218);
        var isMid = (w > 218 && w <= 280);
        var isLarge = (w >= 400);

        var fontMicro;
        var fontBold;
        var fontStreet;

        if (isTiny) {
            if (_textPreset == 1 || _textPreset == 3) {
                fontBold = Graphics.FONT_SMALL;
                fontStreet = Graphics.FONT_TINY;
            } else if (_textPreset == 2) {
                fontBold = Graphics.FONT_XTINY;
                fontStreet = Graphics.FONT_XTINY;
            } else {
                fontBold = Graphics.FONT_TINY;
                fontStreet = Graphics.FONT_XTINY;
            }
            fontMicro = Graphics.FONT_XTINY;
        } else if (isMid) {
            fontMicro = Graphics.FONT_XTINY;
            if (isSfFontActive()) {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                    fontStreet = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL;
                } else if (_textPreset == 2) {
                    fontBold = (_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_XTINY;
                    fontStreet = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_XTINY;
                } else {
                    fontBold = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_SMALL;
                    fontStreet = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;
                }
            } else {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontBold = Graphics.FONT_MEDIUM;
                    fontStreet = Graphics.FONT_SMALL;
                } else if (_textPreset == 2) {
                    fontBold = Graphics.FONT_XTINY;
                    fontStreet = Graphics.FONT_XTINY;
                } else {
                    fontBold = Graphics.FONT_SMALL;
                    fontStreet = Graphics.FONT_XTINY;
                }
            }
        } else if (isLarge) {
            fontMicro = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;
            if (isSfFontActive()) {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontBold = (_fontSfLargeBold != null) ? _fontSfLargeBold : Graphics.FONT_LARGE;
                    fontStreet = (_fontSfLarge != null) ? _fontSfLarge : ((_fontSfLargeBold != null) ? _fontSfLargeBold : Graphics.FONT_LARGE);
                } else if (_textPreset == 2) {
                    fontBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;
                    fontStreet = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL;
                } else {
                    fontBold = (_fontSfLargeBold != null) ? _fontSfLargeBold : ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE);
                    fontStreet = (_fontSfLarge != null) ? _fontSfLarge : ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_MEDIUM);
                }
            } else {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontBold = Graphics.FONT_LARGE;
                    fontStreet = Graphics.FONT_LARGE;
                } else if (_textPreset == 2) {
                    fontBold = Graphics.FONT_MEDIUM;
                    fontStreet = Graphics.FONT_SMALL;
                } else {
                    fontBold = Graphics.FONT_LARGE;
                    fontStreet = Graphics.FONT_MEDIUM;
                }
            }
        } else {
            fontMicro = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;
            if (isSfFontActive()) {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontBold = (_fontSfLargeBold != null) ? _fontSfLargeBold : ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE);
                    fontStreet = (_fontSfStreetBold != null) ? _fontSfStreetBold : ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_MEDIUM);
                } else if (_textPreset == 2) {
                    fontBold = (_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_SMALL;
                    fontStreet = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_XTINY;
                } else {
                    fontBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_SMALL;
                    fontStreet = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_TINY;
                }
            } else {
                if (_textPreset == 1 || _textPreset == 3) {
                    fontBold = Graphics.FONT_LARGE;
                    fontStreet = Graphics.FONT_MEDIUM;
                } else if (_textPreset == 2) {
                    fontBold = Graphics.FONT_TINY;
                    fontStreet = Graphics.FONT_XTINY;
                } else {
                    fontBold = Graphics.FONT_SMALL;
                    fontStreet = Graphics.FONT_TINY;
                }
            }
        }

        var pillH;
        var pillY;
        var badgeR;
        var badgeCy;

        if (isTiny) {
            pillH = 22;
            pillY = (h * 0.77).toNumber();
            badgeR = 17;
            badgeCy = 23;
        } else if (isMid) {
            pillH = 24;
            pillY = (h * 0.76).toNumber();
            badgeR = (h * 0.082).toNumber();
            if (badgeR < 20) { badgeR = 20; }
            badgeCy = (h * 0.125).toNumber();
        } else {
            pillH = (h * 0.082).toNumber();
            if (pillH < 26) { pillH = 26; }
            if (pillH > 36) { pillH = 36; }
            pillY = (h * 0.81).toNumber();

            badgeR = (h * 0.082).toNumber();
            if (badgeR < 20) { badgeR = 20; }
            if (badgeR > 36) { badgeR = 36; }
            badgeCy = (h * 0.125).toNumber();
            if (badgeCy < 28) { badgeCy = 28; }
        }

        var badgeCx = w / 2;

        VectorArrowRenderer.drawAmbientGlow(dc, badgeCx, badgeCy, glowRGB);

        dc.setColor(badgeBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(badgeCx, badgeCy, badgeR);

        if (CommManager.isWaitingImage) {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, accentColor, _animTick);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            VectorArrowRenderer.drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, accentColor, _animTick);
        }

        var distFull = CommManager.distText;
        var distYVal = 0;
        if (distFull.length() > 0) {
            var parts = TextRenderer.splitDist(distFull, isSfNumberFontActive());
            var distNum = parts[0];
            var distUnit = parts[1];

            var numFont = isTiny ? Graphics.FONT_MEDIUM : (TextRenderer.hasAlpha(distNum) ? Graphics.FONT_LARGE : (isMid ? ((_textPreset == 2 || _textPreset == 3) ? Graphics.FONT_NUMBER_HOT : Graphics.FONT_NUMBER_MILD) : _getDistanceFont(distNum, distUnit)));
            if (!isSfFontActive() || isMid || isTiny) {
                var commaIdx = distNum.find(",");
                if (commaIdx != null) {
                    distNum = distNum.substring(0, commaIdx) + "." + distNum.substring(commaIdx + 1, distNum.length());
                }
            }
            var numW = dc.getTextWidthInPixels(distNum, numFont);
            var unitFont = isTiny ? Graphics.FONT_XTINY : (isSfFontActive() ? ((_fontSfUnit != null) ? _fontSfUnit : fontStreet) : (isMid ? Graphics.FONT_MEDIUM : Graphics.FONT_LARGE));
            var unitW = (distUnit.length() > 0) ? dc.getTextWidthInPixels(distUnit, unitFont) : 0;
            var gap = isTiny ? 3 : 5;
            var totalDistW = numW + gap + unitW;
            var startDistX = (w - totalDistW) / 2;

            distYVal = isTiny ? (badgeCy + badgeR + 13) : (badgeCy + badgeR + (h * 0.075).toNumber());
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(startDistX, distYVal, numFont, distNum, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            if (distUnit.length() > 0) {
                var numH = dc.getFontHeight(numFont);
                var unitH = dc.getFontHeight(unitFont);
                var unitOffsetY = ((numH - unitH) / 2) - ((isMid || isTiny) ? 5 : 3);
                if (unitOffsetY < 0) { unitOffsetY = 0; }
                dc.setColor(COLOR_TEXT_UNIT, Graphics.COLOR_TRANSPARENT);
                dc.drawText(startDistX + numW + gap, distYVal + unitOffsetY, unitFont, distUnit, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        var streetText = CommManager.navText;
        if (distYVal == 0) {
            distYVal = badgeCy + badgeR + (h * 0.075).toNumber();
        }
        var minTextY = isTiny ? (distYVal + 18) : (isMid ? (distYVal + (h * 0.095).toNumber()) : (distYVal + (h * 0.080).toNumber()));
        var maxTextH = pillY - (isTiny ? 4 : 6) - minTextY;
        if (maxTextH < 16) { maxTextH = 16; }

        if (streetText.length() > 0) {
            // Strip accents on devices with system fonts lacking Vietnamese Unicode
            if (!isSfFontActive()) {
                streetText = TextRenderer.stripAccents(streetText);
            }

            var parts = TextRenderer.splitActionAndStreet(streetText);
            var actionText = parts[0];
            var street = parts[1];
            var maxTextW = isTiny ? (w * 0.88).toNumber() : (w * 0.82).toNumber();

            var linesAct = TextRenderer.wrapWithFont(dc, actionText, fontBold, maxTextW);
            var linesStr = (street.length() > 0) ? TextRenderer.wrapWithFont(dc, street, fontStreet, maxTextW) : [] as Array<String>;

            var linePad = isLarge ? 5 : (isTiny ? 0 : 2);
            var hAct = dc.getFontHeight(fontBold) + linePad;
            var hStr = dc.getFontHeight(fontStreet) + linePad;
            var totalTextH = (linesAct.size() * hAct) + (linesStr.size() * hStr);

            if (totalTextH <= maxTextH) {
                var startTextY = minTextY + ((maxTextH - totalTextH) / 2);
                var curY = startTextY;
                dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
                for (var i = 0; i < linesAct.size(); i++) {
                    dc.drawText(w / 2, curY, fontBold, linesAct[i], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hAct;
                }

                dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
                for (var j = 0; j < linesStr.size(); j++) {
                    dc.drawText(w / 2, curY, fontStreet, linesStr[j], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hStr;
                }
            } else {
                // Smooth vertical auto-scroll when text is long
                if (dc has :setClip) {
                    dc.setClip((w * 0.06).toNumber(), minTextY, (w * 0.88).toNumber(), maxTextH);
                }

                var overflow = totalTextH - maxTextH + 8;
                var cycle = _animTick % 50;
                var scrollOffset = 0;

                if (cycle < 20) {
                    scrollOffset = 0;
                } else if (cycle < 36) {
                    var progress = (cycle - 20).toFloat() / 16.0;
                    scrollOffset = (progress * overflow).toNumber();
                } else if (cycle < 43) {
                    scrollOffset = overflow;
                } else {
                    var progress = (cycle - 43).toFloat() / 7.0;
                    scrollOffset = ((1.0 - progress) * overflow).toNumber();
                }

                var curY = minTextY + 2 - scrollOffset;

                dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
                for (var i = 0; i < linesAct.size(); i++) {
                    dc.drawText(w / 2, curY, fontBold, linesAct[i], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hAct;
                }

                dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
                for (var j = 0; j < linesStr.size(); j++) {
                    dc.drawText(w / 2, curY, fontStreet, linesStr[j], Graphics.TEXT_JUSTIFY_CENTER);
                    curY += hStr;
                }

                if (dc has :clearClip) {
                    dc.clearClip();
                }

                // Vertical scrollbar indicator on right side
                if (!CommManager.isToastActive()) {
                    var barTrackH = maxTextH - 12;
                    if (barTrackH < 8) { barTrackH = 8; }
                    var thumbH = (maxTextH.toFloat() / totalTextH.toFloat() * barTrackH).toNumber();
                    if (thumbH < 8) { thumbH = 8; }
                    var thumbY = minTextY + 6 + ((scrollOffset.toFloat() / overflow.toFloat()) * (barTrackH - thumbH)).toNumber();
                    var barX = (w * 0.93).toNumber();

                    dc.setColor(0x27272A, Graphics.COLOR_TRANSPARENT);
                    dc.fillRoundedRectangle(barX, minTextY + 6, 2, barTrackH, 1);
                    dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
                    dc.fillRoundedRectangle(barX, thumbY, 2, thumbH, 1);
                }
            }
        }

        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
        var clock = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);

        var etaW = dc.getTextWidthInPixels(etaStr, fontMicro);
        var timeW = dc.getTextWidthInPixels(timeStr, fontMicro);
        var centerGap = (w > 300) ? 20 : (isTiny ? 8 : 10);
        var padX = (w > 300) ? 14 : (isTiny ? 6 : 8);

        var contentW = etaW + centerGap + timeW;
        var pillW = contentW + (padX * 2);
        var pillX = (w - pillW) / 2;
        var pillCy = pillY + (pillH / 2);

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);

        var leftTextX = pillX + padX;
        var rightTextX = pillX + pillW - padX;
        var dotX = leftTextX + etaW + (centerGap / 2);

        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dotX, pillCy, isTiny ? 1.5 : 2.5);

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftTextX, pillCy, fontMicro, etaStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightTextX, pillCy, fontMicro, timeStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // -------------------------------------------------------------------------
    // OpenStreetMap (OSM) Live Mini-Map Screen (5s Update, AMOLED Dark-Mode)
    // -------------------------------------------------------------------------
    private function _getMapPaletteColor(idx as Number) as Number {
        if (CommManager.mapPalette != null && idx < CommManager.mapPalette.size()) {
            return CommManager.mapPalette[idx] as Number;
        }
        var fallback = [
            0x000000, 0x1C1C1E, 0x2C2C2E, 0x48484A,
            0x636366, 0x8E8E93, 0xFFFFFF, 0x0A84FF,
            0x30D158, 0xFFD60A, 0xFF9F0A, 0xFF453A,
            0xBF5AF2, 0x5AC8FA, 0x34C759, 0x1B382B
        ];
        if (idx < fallback.size()) {
            return fallback[idx];
        }
        return 0x000000;
    }

    // =========================================================================
    // VECTOR ROUTE RADAR & ALLEY NETWORK (Cách 1: Breadcrumbs & Radial Alley Fade)
    // =========================================================================
    private function _drawVectorRadarScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var isHdgUp = CommManager.isHeadingUp();

        var fontMicro = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;
        var fontBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM;

        // User center on screen (with pan offsets applied):
        // In Heading Up: vehicle is at 72% height facing UP to maximize view ahead
        // In North Up: vehicle is centered
        var cx = (w / 2) + _panX;
        var cy = (isHdgUp ? (h * 0.72).toNumber() : (h / 2)) + _panY;

        // Heading & Trigonometry
        var hdg = CommManager.vecHeading;

        // Path & Auto-snap / Auto-heading
        var path = CommManager.vecPathPoints;
        if (path == null || path.size() < 4) {
            path = [
                0, -30,
                0, 0,
                0, 45,
                15, 75,
                40, 95,
                70, 110,
                85, 140,
                85, 180,
                70, 220,
                60, 260
            ];
        }

        // User position relative to route origin
        var uDx = CommManager.vecUserDx;
        var uDy = CommManager.vecUserDy;

        // Auto-snap user to route start if GPS telemetry has not arrived yet
        if (uDx == 0 && uDy == 0 && path.size() >= 2) {
            uDx = path[0];
            uDy = path[1];
        }

        // Auto-calculate road heading from first road segment if heading is uninitialized
        if (hdg == 0 && path.size() >= 4) {
            var dxF = (path[2] - path[0]).toFloat();
            var dyF = (path[3] - path[1]).toFloat();
            if (dxF != 0.0 || dyF != 0.0) {
                hdg = (Math.toDegrees(Math.atan2(dxF, dyF)) + 360.0).toNumber() % 360;
            }
        }

        var rad = Math.toRadians(hdg);
        var cosH = Math.cos(rad);
        var sinH = Math.sin(rad);

        // Adaptive Scale (Auto-zoom based on distance to next maneuver + user zoom multiplier)
        var baseScale = 1.15;
        var nextDist = CommManager.vecNextTurnDist;
        if (nextDist > 250) {
            baseScale = 0.8;
        } else if (nextDist > 120) {
            baseScale = 1.0;
        } else if (nextDist > 0 && nextDist <= 50) {
            baseScale = 1.45;
        }
        var scale = baseScale * getZoomMultiplier();

        // 1. OLED Pure Black Background
        dc.setColor(COLOR_BG_AMOLED, COLOR_BG_AMOLED);
        dc.clear();

        // 2. Concentric Radar Distance Rings (50m and 100m)
        var r50 = (50 * scale).toNumber();
        var r100 = (100 * scale).toNumber();

        dc.setPenWidth(1);
        dc.setColor(0x181A20, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, r50);
        dc.drawCircle(cx, cy, r100);

        dc.setColor(0x383D48, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - r50 + 8, fontMicro, "50m", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(cx, cy - r100 + 8, fontMicro, "100m", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Side Alleys / Cross Streets ("Xương xương mờ dần đi cho nghệ")
        var alleys = CommManager.vecAlleySegments;
        if (alleys == null || alleys.size() < 4) {
            // Built-in demonstration alley segments rooted on demo corridor
            alleys = [
                0, 0, -35, 0,
                0, 0, 35, 0,
                0, 45, -30, 48,
                0, 45, 32, 40,
                15, 75, -20, 88,
                15, 75, 45, 62,
                40, 95, 28, 128,
                40, 95, 68, 72,
                70, 110, 52, 142,
                70, 110, 82, 82,
                85, 140, 52, 142,
                85, 140, 118, 138,
                85, 180, 52, 178,
                85, 180, 118, 182,
                70, 220, 38, 228,
                70, 220, 102, 212
            ];
        }

        var aCount = alleys.size();
        for (var i = 0; i < aCount - 3; i += 4) {
            var x1 = alleys[i] - uDx;
            var y1 = alleys[i + 1] - uDy;
            var x2 = alleys[i + 2] - uDx;
            var y2 = alleys[i + 3] - uDy;

            // Radial midpoint distance from user
            var mx = (x1 + x2) / 2.0;
            var my = (y1 + y2) / 2.0;
            var dist = Math.sqrt(mx * mx + my * my);
            if (dist > 145) {
                continue; // Faded into AMOLED black
            }

            // Radial color fading and pen thickness
            if (dist < 45) {
                dc.setColor(0x525660, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(2);
            } else if (dist < 85) {
                dc.setColor(0x30333C, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
            } else {
                dc.setColor(0x1C1E24, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
            }

            var rx1 = 0.0;
            var ry1 = 0.0;
            var rx2 = 0.0;
            var ry2 = 0.0;
            if (isHdgUp) {
                rx1 = (x1 * cosH - y1 * sinH);
                ry1 = (x1 * sinH + y1 * cosH);
                rx2 = (x2 * cosH - y2 * sinH);
                ry2 = (x2 * sinH + y2 * cosH);
            } else {
                rx1 = x1.toFloat();
                ry1 = y1.toFloat();
                rx2 = x2.toFloat();
                ry2 = y2.toFloat();
            }

            var sx1 = (cx + rx1 * scale).toNumber();
            var sy1 = (cy - ry1 * scale).toNumber();
            var sx2 = (cx + rx2 * scale).toNumber();
            var sy2 = (cy - ry2 * scale).toNumber();

            dc.drawLine(sx1, sy1, sx2, sy2);

            // Subtle junction dot at root
            if (dist < 65) {
                dc.setColor(0x656B77, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(sx1, sy1, 2);
            }
        }

        // 4. Main Breadcrumb Route Polyline
        dc.setPenWidth(5);
        var pCount = path.size();
        for (var j = 0; j < pCount - 3; j += 2) {
            var px1 = path[j] - uDx;
            var py1 = path[j + 1] - uDy;
            var px2 = path[j + 2] - uDx;
            var py2 = path[j + 3] - uDy;

            var rpx1 = 0.0;
            var rpy1 = 0.0;
            var rpx2 = 0.0;
            var rpy2 = 0.0;

            if (isHdgUp) {
                rpx1 = (px1 * cosH - py1 * sinH);
                rpy1 = (px1 * sinH + py1 * cosH);
                rpx2 = (px2 * cosH - py2 * sinH);
                rpy2 = (px2 * sinH + py2 * cosH);
            } else {
                rpx1 = px1.toFloat();
                rpy1 = py1.toFloat();
                rpx2 = px2.toFloat();
                rpy2 = py2.toFloat();
            }

            // Route color: Behind user = subdued dark teal; Ahead of user = Neon Cyan
            if (isHdgUp && rpy1 < -15 && rpy2 < -15) {
                dc.setColor(0x0C3038, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(COLOR_THEME_CYAN_ACCENT, Graphics.COLOR_TRANSPARENT);
            }

            var spx1 = (cx + rpx1 * scale).toNumber();
            var spy1 = (cy - rpy1 * scale).toNumber();
            var spx2 = (cx + rpx2 * scale).toNumber();
            var spy2 = (cy - rpy2 * scale).toNumber();

            dc.drawLine(spx1, spy1, spx2, spy2);
            dc.fillCircle(spx1, spy1, 3);
        }

        // 4b. Road & Intersection Street Name Labels
        if (CommManager.vecStreetLabels != null) {
            var labels = CommManager.vecStreetLabels;
            var lCount = labels.size();
            for (var k = 0; k < lCount - 2; k += 3) {
                var lName = labels[k] as String;
                var lx = (labels[k + 1] as Number) - uDx;
                var ly = (labels[k + 2] as Number) - uDy;

                var rlx = 0.0;
                var rly = 0.0;
                if (isHdgUp) {
                    rlx = (lx * cosH - ly * sinH);
                    rly = (lx * sinH + ly * cosH);
                } else {
                    rlx = lx.toFloat();
                    rly = ly.toFloat();
                }

                var dist = Math.sqrt(rlx * rlx + rly * rly);
                if (dist > 140 || dist < 14) {
                    continue;
                }

                var slx = (cx + rlx * scale).toNumber();
                var sly = (cy - rly * scale).toNumber();

                if (sly < 65 || sly > h - 45 || slx < 25 || slx > w - 25) {
                    continue;
                }

                var safeName = TextRenderer.stripAccents(lName);
                var tW = dc.getTextWidthInPixels(safeName, fontMicro);
                var pW = tW + 10;
                var pH = 16;
                var pX = slx - (pW / 2);
                var pY = sly - (pH / 2);

                dc.setColor(0x0C121A, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(pX, pY, pW, pH, 4);
                dc.setColor(0x3B4454, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(1);
                dc.drawRoundedRectangle(pX, pY, pW, pH, 4);

                dc.setColor(0xC8D4E6, Graphics.COLOR_TRANSPARENT);
                dc.drawText(slx, sly, fontMicro, safeName, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        // 5. User Vehicle Marker & Radar Pulse
        dc.setColor(0x0F323A, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, 14);

        if (isHdgUp) {
            // Straight up aerodynamic chevron in Neon Green (convex dual-triangle)
            var tri1 = [ [cx, cy - 11], [cx - 8, cy + 8], [cx, cy + 4] ];
            var tri2 = [ [cx, cy - 11], [cx, cy + 4], [cx + 8, cy + 8] ];
            dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon(tri1);
            dc.fillPolygon(tri2);
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, 2);
        } else {
            // Rotated chevron in North Up mode
            var hRad = Math.toRadians(hdg);
            var hCos = Math.cos(hRad);
            var hSin = Math.sin(hRad);

            var tipX = (cx + (0 * hCos - (-11) * hSin)).toNumber();
            var tipY = (cy - (0 * hSin + (-11) * hCos)).toNumber();
            var leftX = (cx + (-8 * hCos - 8 * hSin)).toNumber();
            var leftY = (cy - (-8 * hSin + 8 * hCos)).toNumber();
            var notchX = (cx + (0 * hCos - 4 * hSin)).toNumber();
            var notchY = (cy - (0 * hSin + 4 * hCos)).toNumber();
            var rightX = (cx + (8 * hCos - 8 * hSin)).toNumber();
            var rightY = (cy - (8 * hSin + 8 * hCos)).toNumber();

            dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([ [tipX, tipY], [leftX, leftY], [notchX, notchY] ]);
            dc.fillPolygon([ [tipX, tipY], [notchX, notchY], [rightX, rightY] ]);
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, 2);
        }

        // 6. Top HUD Banner (Turn instruction, Street name, Orientation Pill)
        var bannerW = w - 24;
        var bannerH = 46;
        var bannerX = 12;
        var bannerY = 12;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(bannerX, bannerY, bannerW, bannerH, 16);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(bannerX, bannerY, bannerW, bannerH, 16);

        // Turn distance & Street text
        var distLabel = (nextDist > 0) ? (nextDist.toString() + "m") : "65m";
        var streetLabel = CommManager.vecNextStreet;
        if (streetLabel.length() == 0) {
            streetLabel = (CommManager.vecDestName.length() > 0) ? CommManager.vecDestName : "Hẻm 207 Lê Văn Sỹ";
        }

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bannerX + 14, bannerY + 12, fontBold, distLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bannerX + 14, bannerY + 31, fontMicro, streetLabel, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Top Right Orientation Pill [ HDG ] or [ N-UP ]
        var badgeW = 48;
        var badgeH = 24;
        var badgeX = bannerX + bannerW - badgeW - 8;
        var badgeY = bannerY + 11;

        if (isHdgUp) {
            dc.setColor(0x0C2818, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 12);
            dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 12);
            dc.drawText(badgeX + (badgeW / 2), badgeY + (badgeH / 2) - 1, fontMicro, "HDG", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            dc.setColor(0x281600, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 12);
            dc.setColor(0xFFA500, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(badgeX, badgeY, badgeW, badgeH, 12);
            dc.drawText(badgeX + (badgeW / 2), badgeY + (badgeH / 2) - 1, fontMicro, "N-UP", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // 7. Bottom HUD Telemetry (Speed, ETA/Dist, Tab Dots)
        var footY = h - 34;

        // Speed pill (Bottom Left)
        var spd = CommManager.vecSpeedKmh;
        if (spd == 0 && CommManager.mapSpeed > 0) {
            spd = CommManager.mapSpeed;
        }
        var spdStr = (spd > 0) ? (spd.toString() + " km/h") : "28 km/h";
        var spdW = dc.getTextWidthInPixels(spdStr, fontMicro) + 16;
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(12, footY, spdW, 24, 12);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(12, footY, spdW, 24, 12);
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(12 + (spdW / 2), footY + 11, fontMicro, spdStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Radar Tab indicator (Bottom Center: 2 dots [ o  • ])
        dc.setColor(0x383D48, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(w / 2 - 6, footY + 12, 3);
        dc.setColor(COLOR_THEME_CYAN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(w / 2 + 6, footY + 12, 4);

        // Range / Status (Bottom Right)
        var rangeStr = "120m";
        var rangeW = dc.getTextWidthInPixels(rangeStr, fontMicro) + 16;
        var rangeX = w - 12 - rangeW;
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(rangeX, footY, rangeW, 24, 12);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(rangeX, footY, rangeW, 24, 12);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rangeX + (rangeW / 2), footY + 11, fontMicro, rangeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // 8. Floating Map Controls (Zoom In, Zoom Out, Recenter)
        var btnX = w - 24;
        var btnInY = (h / 2) - 22;
        var btnOutY = (h / 2) + 16;
        var rBtn = 13;

        // Zoom In Button (+)
        dc.setColor(0x161A22, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(btnX, btnInY, rBtn);
        dc.setColor(0x384050, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(btnX, btnInY, rBtn);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(btnX - 5, btnInY, btnX + 5, btnInY);
        dc.drawLine(btnX, btnInY - 5, btnX, btnInY + 5);

        // Zoom Out Button (-)
        dc.setColor(0x161A22, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(btnX, btnOutY, rBtn);
        dc.setColor(0x384050, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(btnX, btnOutY, rBtn);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(btnX - 5, btnOutY, btnX + 5, btnOutY);

        // Recenter Button (Target reticle - only when panned or zoomed)
        if (_panX != 0 || _panY != 0 || _mapZoomStep != 0) {
            var btnRecenterY = (h / 2) + 54;
            dc.setColor(0x161A22, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(btnX, btnRecenterY, rBtn);
            dc.setColor(COLOR_THEME_CYAN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(btnX, btnRecenterY, rBtn);
            dc.fillCircle(btnX, btnRecenterY, 3);
            dc.drawLine(btnX - 6, btnRecenterY, btnX - 3, btnRecenterY);
            dc.drawLine(btnX + 3, btnRecenterY, btnX + 6, btnRecenterY);
            dc.drawLine(btnX, btnRecenterY - 6, btnX, btnRecenterY - 3);
            dc.drawLine(btnX, btnRecenterY + 3, btnX, btnRecenterY + 6);
        }
    }

    // =========================================================================
    // ARRIVED AT DESTINATION SUMMARY & DETAIL SCREENS (Holds for 1 Minute)
    // =========================================================================

    // -------------------------------------------------------------------------
    // Signature NavigationIQ Arrival Emblem (Glowing Emerald Bloom & 2-Tone Destination Pin)
    // -------------------------------------------------------------------------
    private function _drawArrivalEmblem(dc as Dc, cx as Number, cy as Number, r as Number, accent as Number) as Void {
        // 1. Signature Ambient Green Bloom
        VectorArrowRenderer.drawAmbientGlow(dc, cx, cy, GLOW_RGB_GREEN);

        // 2. Emblem Badge Circle
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, r);

        // 3. Proportional 2-Tone Destination Pin with White Checkmark
        var scale = r.toFloat() / 38.0;
        var pinHeadY = cy - (5 * scale).toNumber();
        var pinHeadR = (13 * scale).toNumber();
        var pinTipY = cy + (18 * scale).toNumber();
        var needleW = (10 * scale).toNumber();

        // Pin body (Mint green accent)
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, pinHeadY, pinHeadR);
        dc.fillPolygon([
            [cx - needleW, pinHeadY + (3 * scale).toNumber()],
            [cx + needleW, pinHeadY + (3 * scale).toNumber()],
            [cx, pinTipY]
        ]);

        // Right-side 3D shadow (2-tone depth matching signature arrowhead)
        dc.setColor(COLOR_THEME_GREEN_BADGE, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx, pinHeadY - pinHeadR],
            [cx + pinHeadR, pinHeadY],
            [cx + needleW, pinHeadY + (3 * scale).toNumber()],
            [cx, pinTipY],
            [cx, pinHeadY]
        ]);

        // Center white checkmark
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        var cS = (5 * scale).toNumber();
        dc.drawLine(cx - cS, pinHeadY - 1, cx - 1, pinHeadY + cS - 1);
        dc.drawLine(cx - 1, pinHeadY + cS - 1, cx + cS + 1, pinHeadY - cS);
        dc.setPenWidth(1);
    }

    // -------------------------------------------------------------------------
    // Rect / Squircle Screen (Venu Sq, Venu Sq 2) - Cockpit Aero Design
    // -------------------------------------------------------------------------
    private function _drawRectArrivedScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();

        var fontMicro = isSfFontActive() ? ((_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY) : Graphics.FONT_XTINY;
        var fontCompactBold = isSfFontActive() ? ((_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY) : Graphics.FONT_TINY;
        var fontStreetBold = isSfFontActive() ? ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE) : Graphics.FONT_LARGE;
        var fontStreet = isSfFontActive() ? ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL) : Graphics.FONT_SMALL;

        if (CommManager.isArrivedDetail) {
            _drawRectArrivedDetail(dc, w, h, fontMicro, fontCompactBold, fontStreet);
        } else {
            _drawRectArrivedSummary(dc, w, h, fontMicro, fontCompactBold, fontStreetBold, fontStreet);
        }
    }

    private function _drawRectArrivedSummary(dc as Dc, w as Number, h as Number, fontMicro as Graphics.FontDefinition, fontCompactBold as Graphics.FontDefinition, fontStreetBold as Graphics.FontDefinition, fontStreet as Graphics.FontDefinition) as Void {
        var cx = w / 2;

        // 1. Hero Visual Emblem with Ambient Green Bloom (Drawn FIRST as background layer)
        var badgeCy = (h * 0.35).toNumber();
        var badgeR = 38;
        _drawArrivalEmblem(dc, cx, badgeCy, badgeR, COLOR_THEME_GREEN_ACCENT);

        // 2. Top Floating Status Capsule Pill (Drawn on top of glow)
        var remSec = CommManager.getArrivedRemainingSeconds();
        var statusStr = "Arrived  " + remSec.toString() + "s";
        var strW = dc.getTextWidthInPixels(statusStr, fontMicro);
        var pillW = strW + 30;
        var pillX = (w - pillW) / 2;
        var pillH = (h * 0.082).toNumber();
        if (pillH < 26) { pillH = 26; }
        if (pillH > 32) { pillH = 32; }
        var pillY = (h * 0.05).toNumber();

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);

        // Status green dot
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(pillX + 13, pillY + (pillH / 2), 3.5);

        // Status text
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pillX + 22, pillY + (pillH / 2), fontMicro, statusStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // 3. Typographic Hierarchy (Matches Init Screen: Bold Title + Silver Subtitle)
        var hBold = dc.getFontHeight(fontStreetBold);
        var hStreet = dc.getFontHeight(fontStreet);
        var titleY = badgeCy + badgeR + (h * 0.08).toNumber();
        var subTitleY = titleY + ((hBold + hStreet) / 2) + 6;

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, titleY, fontStreetBold, "Destination Reached", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var rawDest = CommManager.arrivedDest;
        var cleanDest = TextRenderer.stripAccents(rawDest);
        var destLines = TextRenderer.wrapWithFont(dc, cleanDest, fontStreet, w - 36);
        for (var i = 0; i < destLines.size() && i < 2; i++) {
            dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, subTitleY + (i * (hStreet + 2)), fontStreet, destLines[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // 4. Cockpit Telemetry Capsule Bar at Bottom (Signature Floating Island Capsule)
        var barW = w - 24;
        var barH = pillH;
        var barX = 12;
        var barY = h - barH - (h * 0.04).toNumber();
        var barRadius = barH / 2;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(barX, barY, barW, barH, barRadius);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(barX, barY, barW, barH, barRadius);

        var colW = barW / 3;
        var midY = barY + (barH / 2);

        // Col 1: TIME
        var c1X = barX + (colW / 2);
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(c1X, midY, fontCompactBold, CommManager.arrivedDuration, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Divider 1
        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(barX + colW, barY + 6, barX + colW, barY + barH - 6);

        // Col 2: DISTANCE
        var c2X = barX + colW + (colW / 2);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(c2X, midY, fontCompactBold, CommManager.arrivedDistance, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Divider 2
        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(barX + (colW * 2), barY + 6, barX + (colW * 2), barY + barH - 6);

        // Col 3: AVG SPEED
        var c3X = barX + (colW * 2) + (colW / 2);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(c3X, midY, fontCompactBold, CommManager.arrivedAvgSpeed, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _drawRectArrivedDetail(dc as Dc, w as Number, h as Number, fontMicro as Graphics.FontDefinition, fontCompactBold as Graphics.FontDefinition, fontStreet as Graphics.FontDefinition) as Void {
        var cx = w / 2;

        // Ambient glow background
        VectorArrowRenderer.drawAmbientGlow(dc, cx, 100, GLOW_RGB_GREEN);

        // Top Status Pill
        var remSec = CommManager.getArrivedRemainingSeconds();
        var statusStr = "Trip Details  " + remSec.toString() + "s";
        var strW = dc.getTextWidthInPixels(statusStr, fontMicro);
        var pillW = strW + 30;
        var pillX = (w - pillW) / 2;
        var pillH = (h * 0.082).toNumber();
        if (pillH < 26) { pillH = 26; }
        if (pillH > 32) { pillH = 32; }
        var pillY = (h * 0.05).toNumber();

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);

        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(pillX + 13, pillY + (pillH / 2), 3.5);

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pillX + 22, pillY + (pillH / 2), fontMicro, statusStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Capsule Detail Card
        var cardW = w - 24;
        var cardX = 12;
        var startY = pillY + pillH + 12;
        var cardH = h - startY - 14;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(cardX, startY, cardW, cardH, 20);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(cardX, startY, cardW, cardH, 20);

        var curY = startY + 14;

        // Destination title & wrapped address
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cardX + 16, curY, fontMicro, "Destination Address", Graphics.TEXT_JUSTIFY_LEFT);
        curY += 24;

        var rawDest = CommManager.arrivedDest;
        var cleanDest = TextRenderer.stripAccents(rawDest);
        var destLines = TextRenderer.wrapWithFont(dc, cleanDest, fontStreet, cardW - 32);
        var lineH = dc.getFontHeight(fontStreet) + 2;
        for (var i = 0; i < destLines.size() && i < 3; i++) {
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cardX + 16, curY, fontStreet, destLines[i], Graphics.TEXT_JUSTIFY_LEFT);
            curY += lineH;
        }

        curY += 8;
        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cardX + 14, curY, cardX + cardW - 14, curY);
        curY += 14;

        // Details list: Time span, Total Distance, Avg Speed
        var timeLabel = (CommManager.arrivedStartTime.length() > 0 && CommManager.arrivedEndTime.length() > 0)
            ? (CommManager.arrivedStartTime + " - " + CommManager.arrivedEndTime)
            : CommManager.arrivedDuration;

        _drawDetailRow(dc, cardX + 16, cardW - 32, curY, fontMicro, fontStreet, "Time Span", timeLabel);
        curY += 28;
        _drawDetailRow(dc, cardX + 16, cardW - 32, curY, fontMicro, fontStreet, "Total Distance", CommManager.arrivedDistance);
        curY += 28;
        _drawDetailRow(dc, cardX + 16, cardW - 32, curY, fontMicro, fontStreet, "Average Speed", CommManager.arrivedAvgSpeed);
    }

    private function _drawDetailRow(dc as Dc, x as Number, width as Number, y as Number, fontLabel as Graphics.FontDefinition, fontVal as Graphics.FontDefinition, label as String, val as String) as Void {
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, fontLabel, label, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + width, y, fontVal, val, Graphics.TEXT_JUSTIFY_RIGHT);
    }

    // -------------------------------------------------------------------------
    // Round AMOLED Screen (Fenix, Forerunner, Venu Round) - Cockpit Aero Design
    // -------------------------------------------------------------------------
    private function _drawRoundArrivedScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        var fontMicro = isSfFontActive() ? ((_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY) : Graphics.FONT_XTINY;
        var fontCompactBold = isSfFontActive() ? ((_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY) : Graphics.FONT_TINY;
        var fontStreetBold = isSfFontActive() ? ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_MEDIUM) : Graphics.FONT_MEDIUM;
        var fontStreet = isSfFontActive() ? ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL) : Graphics.FONT_SMALL;

        var remSec = CommManager.getArrivedRemainingSeconds();

        if (CommManager.isArrivedDetail) {
            // Ambient green bloom background
            VectorArrowRenderer.drawAmbientGlow(dc, cx, (h * 0.35).toNumber(), GLOW_RGB_GREEN);

            // Top Status Pill
            var statusStr = "Trip Details  " + remSec.toString() + "s";
            var strW = dc.getTextWidthInPixels(statusStr, fontMicro);
            var pillW = strW + 30;
            var pillX = (w - pillW) / 2;
            var pillH = (h * 0.082).toNumber();
            if (pillH < 26) { pillH = 26; }
            if (pillH > 32) { pillH = 32; }
            var pillY = (h * 0.08).toNumber();

            dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
            dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);

            dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(pillX + 13, pillY + (pillH / 2), 3.5);

            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(pillX + 22, pillY + (pillH / 2), fontMicro, statusStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            // Detailed Card for Round Screen
            var cardW = (w * 0.84).toNumber();
            var cardH = (h * 0.64).toNumber();
            var cardX = (w - cardW) / 2;
            var cardY = pillY + pillH + 12;

            dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(cardX, cardY, cardW, cardH, 22);
            dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(cardX, cardY, cardW, cardH, 22);

            var curY = cardY + 14;
            var cleanDest = TextRenderer.stripAccents(CommManager.arrivedDest);
            var destLines = TextRenderer.wrapWithFont(dc, cleanDest, fontStreet, cardW - 24);
            var lineH = dc.getFontHeight(fontStreet) + 2;
            for (var i = 0; i < destLines.size() && i < 2; i++) {
                dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, curY, fontStreet, destLines[i], Graphics.TEXT_JUSTIFY_CENTER);
                curY += lineH;
            }

            curY += 8;
            dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(cardX + 14, curY, cardX + cardW - 14, curY);
            curY += 14;

            var timeSpan = (CommManager.arrivedStartTime.length() > 0 && CommManager.arrivedEndTime.length() > 0)
                ? (CommManager.arrivedStartTime + " - " + CommManager.arrivedEndTime)
                : CommManager.arrivedDuration;

            dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, curY, fontMicro, "Time: " + timeSpan, Graphics.TEXT_JUSTIFY_CENTER);
            curY += 24;
            dc.drawText(cx, curY, fontMicro, "Dist: " + CommManager.arrivedDistance + " | Avg: " + CommManager.arrivedAvgSpeed, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            // Summary Hero View for Round Screen
            // 1. Hero Visual Emblem with Ambient Green Bloom (Drawn FIRST as background layer)
            var badgeCy = (h * 0.38).toNumber();
            var badgeR = 44;
            _drawArrivalEmblem(dc, cx, badgeCy, badgeR, COLOR_THEME_GREEN_ACCENT);

            // 2. Top Floating Status Capsule Pill (Drawn on top of glow)
            var statusStr = "Arrived  " + remSec.toString() + "s";
            var strW = dc.getTextWidthInPixels(statusStr, fontMicro);
            var pillW = strW + 30;
            var pillX = (w - pillW) / 2;
            var pillH = (h * 0.082).toNumber();
            if (pillH < 26) { pillH = 26; }
            if (pillH > 32) { pillH = 32; }
            var pillY = (h * 0.08).toNumber();

            dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);
            dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, pillH / 2);

            dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(pillX + 13, pillY + (pillH / 2), 3.5);

            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(pillX + 22, pillY + (pillH / 2), fontMicro, statusStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            // 3. Typographic Hierarchy (Matches Init Screen)
            var hBold = dc.getFontHeight(fontStreetBold);
            var hStreet = dc.getFontHeight(fontStreet);
            var titleY = badgeCy + badgeR + (h * 0.07).toNumber();
            var subTitleY = titleY + ((hBold + hStreet) / 2) + 6;

            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, titleY, fontStreetBold, "Destination Reached", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            var rawDest = CommManager.arrivedDest;
            var cleanDest = TextRenderer.stripAccents(rawDest);
            var destLines = TextRenderer.wrapWithFont(dc, cleanDest, fontStreet, (w * 0.76).toNumber());
            for (var i = 0; i < destLines.size() && i < 2; i++) {
                dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, subTitleY + (i * (hStreet + 2)), fontStreet, destLines[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }

            // 4. Cockpit Telemetry Capsule Bar at Bottom
            var barW = (w * 0.82).toNumber();
            var barH = pillH;
            var barX = (w - barW) / 2;
            var barY = (h * 0.82).toNumber();
            var barRadius = barH / 2;

            dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, barY, barW, barH, barRadius);
            dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(barX, barY, barW, barH, barRadius);

            var colW = barW / 3;
            var midY = barY + (barH / 2);

            // Col 1: TIME
            var c1X = barX + (colW / 2);
            dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(c1X, midY, fontCompactBold, CommManager.arrivedDuration, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Divider 1
            dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(barX + colW, barY + 6, barX + colW, barY + barH - 6);

            // Col 2: DIST
            var c2X = barX + colW + (colW / 2);
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(c2X, midY, fontCompactBold, CommManager.arrivedDistance, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            // Divider 2
            dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(barX + (colW * 2), barY + 6, barX + (colW * 2), barY + barH - 6);

            // Col 3: AVG
            var c3X = barX + (colW * 2) + (colW / 2);
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(c3X, midY, fontCompactBold, CommManager.arrivedAvgSpeed, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // -------------------------------------------------------------------------
    // Instinct Crossover Screen (High-Contrast Monochrome MIP)
    // -------------------------------------------------------------------------
    private function _drawInstinctArrivedScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var isCrossover = (WatchUi.View has :setClockHandPosition);

        // Sub-window circle with tick icon (Crossover: 138, 33, 23; Instinct 2: 144, 31, 26)
        var subCx = isCrossover ? 138 : 144;
        var subCy = isCrossover ? 33 : 31;
        var subR = isCrossover ? 23 : 26;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(subCx, subCy, subR);

        // Tick mark in sub-window
        var tickScale = subR.toFloat() / 24.0;
        var tMidX = subCx - (1 * tickScale).toNumber();
        var tMidY = subCy + (4 * tickScale).toNumber();
        dc.drawLine(tMidX - (6 * tickScale).toNumber(), tMidY - (6 * tickScale).toNumber(), tMidX, tMidY);
        dc.drawLine(tMidX, tMidY, tMidX + (10 * tickScale).toNumber(), tMidY - (11 * tickScale).toNumber());

        // Header: ARRIVED (25s) with safe left margin
        var leftMargin = isCrossover ? 12 : 16;
        dc.drawText(leftMargin, 16, Graphics.FONT_XTINY, "ARRIVED (" + CommManager.getArrivedRemainingSeconds() + "s)", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Upper Section: Destination address (safe zone: y = 28 to 68)
        var cleanDest = TextRenderer.stripAccents(CommManager.arrivedDest);
        if (cleanDest.length() == 0 || cleanDest.equals("Destination")) {
            if (CommManager.nextStreet.length() > 0) {
                cleanDest = TextRenderer.stripAccents(CommManager.nextStreet);
            }
        }
        var maxTextW = isCrossover ? (w - 56) : (w - 48); // Avoid sub-window overlap
        var textX = leftMargin;
        var fontDest = Graphics.FONT_SMALL;
        var hDest = dc.getFontHeight(fontDest);
        var destLines = TextRenderer.wrapWithFont(dc, cleanDest, fontDest, maxTextW);

        if (destLines.size() <= 1) {
            var singleLine = (destLines.size() == 1) ? destLines[0] : cleanDest;
            _drawMarqueeText(dc, singleLine, textX, 42, maxTextW, fontDest, Graphics.COLOR_WHITE, false);
        } else {
            var line0 = destLines[0];
            var rest = "";
            if (cleanDest.length() > line0.length()) {
                rest = cleanDest.substring(line0.length(), cleanDest.length());
                while (rest.length() > 0 && rest.substring(0, 1).equals(" ")) {
                    rest = rest.substring(1, rest.length());
                }
            }
            _drawMarqueeText(dc, line0, textX, 32, maxTextW, fontDest, Graphics.COLOR_WHITE, false);
            _drawMarqueeText(dc, rest, textX, 50, maxTextW, fontDest, Graphics.COLOR_WHITE, false);
        }

        // Crossover Physical Hands Clearance Channel (y = 70 to 102)
        // Two horizontal dividing lines framing the 9:15 parked analog hands
        dc.setPenWidth(1);
        dc.drawLine(8, 70, w - 8, 70);
        dc.drawLine(8, 102, w - 8, 102);

        // Lower Section: 3-Column Telemetry Card below physical hands (y = 106 to 150)
        var cardX = 8;
        var cardY = 106;
        var cardW = w - 16;
        var cardH = 44;
        dc.drawRectangle(cardX, cardY, cardW, cardH);

        var colW = cardW / 3;
        var div1X = cardX + colW;
        var div2X = cardX + (colW * 2);
        dc.drawLine(div1X, cardY + 4, div1X, cardY + cardH - 4);
        dc.drawLine(div2X, cardY + 4, div2X, cardY + cardH - 4);

        var vy = cardY + 4;
        var ly = cardY + 24;

        var durStr = (CommManager.arrivedDuration.length() > 0 && !CommManager.arrivedDuration.equals("--")) ? CommManager.arrivedDuration : "--";
        var distStr = (CommManager.arrivedDistance.length() > 0 && !CommManager.arrivedDistance.equals("--")) ? CommManager.arrivedDistance : "--";
        var spdStr = (CommManager.arrivedAvgSpeed.length() > 0 && !CommManager.arrivedAvgSpeed.equals("--")) ? CommManager.arrivedAvgSpeed : "--";

        // Col 1: TIME
        dc.drawText(cardX + (colW / 2), vy, Graphics.FONT_XTINY, durStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cardX + (colW / 2), ly, Graphics.FONT_XTINY, "TIME", Graphics.TEXT_JUSTIFY_CENTER);

        // Col 2: DIST
        dc.drawText(div1X + (colW / 2), vy, Graphics.FONT_XTINY, distStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(div1X + (colW / 2), ly, Graphics.FONT_XTINY, "DIST", Graphics.TEXT_JUSTIFY_CENTER);

        // Col 3: SPEED
        dc.drawText(div2X + (colW / 2), vy, Graphics.FONT_XTINY, spdStr, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(div2X + (colW / 2), ly, Graphics.FONT_XTINY, "SPD", Graphics.TEXT_JUSTIFY_CENTER);

        // Footer: Back to Exit
        dc.drawText(cx, h - 14, Graphics.FONT_XTINY, "Back to Exit", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
