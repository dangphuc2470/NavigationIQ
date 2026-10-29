import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Application.Storage;

class NavigationIQView extends WatchUi.View {

    private var _pageTimer as Timer.Timer?;
    var _animTick as Number = 0;
    private var _pageIndex as Number = 0;
    var _needsAnimRedraw as Boolean = false;
    var _wasToastActive as Boolean = false;
    var _lastDrawnMin as Number = -1;
    var _rotation as Number = 0; // 0 = Portrait (0°), 1 = Landscape (90° Clockwise for Left-Wrist Motorbike)
    public var _fontSfStreetBold as Graphics.FontDefinition?;
    public var _fontSfStreet as Graphics.FontDefinition?;
    public var _fontSfCompactBold as Graphics.FontDefinition?;
    public var _fontSfCompact as Graphics.FontDefinition?;
    public var _fontSfMicro as Graphics.FontDefinition?;
    public var _fontSfStreetBoldRot90 as Graphics.FontDefinition?;
    public var _fontSfStreetRot90 as Graphics.FontDefinition?;
    public var _fontSfMicroRot90 as Graphics.FontDefinition?;
    public var _fontSfNumberHot as Graphics.FontDefinition?;
    public var _fontSfNumberMild as Graphics.FontDefinition?;
    public var _fontSfUnit as Graphics.FontDefinition?;
    public var _fontSfLargeBold as Graphics.FontDefinition?;
    public var _fontSfLarge as Graphics.FontDefinition?;
    public var _fontSfLabel as Graphics.FontDefinition?;

    var _layoutProfile as Number = 0; // 0 = Auto, 1 = Rect (Venu Sq), 2 = Round, 3 = Instinct Crossover
    var _appFontSetting as Number = 0; // 0 = Auto, 1 = Apple SF Pro, 2 = Garmin Native
    var _textPreset as Number = 0;     // 0 = Balanced, 1 = Street Focus, 2 = Distance Focus, 3 = Large Text

    // Preview / Demo Mode State
    var _isPreviewMode as Boolean = false;
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
    var _currentTab as Number = 0;
    const TAB_HUD = 0;
    const TAB_MAP = 1;

    // Map Pan & Drag State
    var _panX as Number = 0;
    var _panY as Number = 0;
    var _dragStartX as Number = 0;
    var _dragStartY as Number = 0;
    var _isDragging as Boolean = false;
    var _mapZoomStep as Number = 0; // -2, -1, 0, 1, 2

    function initialize() {
        View.initialize();
        _pageTimer = new Timer.Timer();
        reloadSettings();
        if (isSfFontActive()) {
            FontLoader.loadSfFonts(self);
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

    function _ensureSfNumberFontsLoaded() as Void {
        FontLoader.ensureNumberFonts(self);
    }

    function _getDistanceFont(distNum as String, distUnit as String) as Graphics.FontDefinition {
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
    public function isHardwareInstinct(dc as Dc) as Boolean {
        var w = dc.getWidth();
        var h = dc.getHeight();
        return (w <= 176 && h <= 176);
    }

    public function isHardwareRound(dc as Dc) as Boolean {
        if (isHardwareInstinct(dc)) {
            return false;
        }
        var devSettings = System.getDeviceSettings();
        if (devSettings has :screenShape) {
            return (devSettings.screenShape == System.SCREEN_SHAPE_ROUND || devSettings.screenShape == System.SCREEN_SHAPE_SEMI_ROUND);
        }
        return (dc.getWidth() == dc.getHeight() && dc.getWidth() > 200);
    }

    public function getEffectiveProfile(dc as Dc) as Number {
        if (_layoutProfile > 0) {
            return _layoutProfile;
        }
        if (isHardwareInstinct(dc)) {
            return 3;
        }
        if (isHardwareRound(dc)) {
            return 2;
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
            WatchUi.requestUpdate();
            return;
        }
        if (_isPreviewMode && !CommManager.isArrived) {
            _previewTimerTicks++;
            if (_previewTimerTicks % 36 == 0) { // 36 ticks * 200ms = 7200ms (7.2s)
                _previewIndex++;
                PreviewManager.applyStep(_previewIndex);
            }
            WatchUi.requestUpdate();
            return;
        }

        // Power-Save Smart Redraw: Only trigger GPU/CPU screen redraw when active animation/scroll/toast/clock change occurs
        var toastNow = CommManager.isToastActive();
        var clockMin = System.getClockTime().min;
        if (_needsAnimRedraw || toastNow || _wasToastActive || clockMin != _lastDrawnMin) {
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        _needsAnimRedraw = false;
        _wasToastActive = CommManager.isToastActive();
        _lastDrawnMin = System.getClockTime().min;

        if (_isPreviewMode) {
            CommManager.checkHapticUpdate();
        }

        dc.setColor(COLOR_BG_AMOLED, COLOR_BG_AMOLED);
        dc.clear();

        if (CommManager.isArrived || CommManager.direction == DIR_ARRIVED) {
            _drawInstinctArrivedScreen(dc);
            return;
        }

        if (!CommManager.isActive && !_isPreviewMode) {
            _drawInstinctIdleScreen(dc);
            return;
        }

        _drawInstinctCrossoverHUD(dc);
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
    function _drawMarqueeText(dc as Dc, text as String, x as Number, y as Number, width as Number, font as Graphics.FontDefinition, color as Number, isCenter as Boolean) as Void {
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

        _needsAnimRedraw = true;
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
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, Graphics.COLOR_WHITE, _animTick);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            VectorArrowRenderer.drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, Graphics.COLOR_WHITE);
        } else {
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, Graphics.COLOR_WHITE, _animTick);
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

                _needsAnimRedraw = true;
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
