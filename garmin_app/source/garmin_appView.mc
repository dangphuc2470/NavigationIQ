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

    private var _layoutProfile as Number = 0; // 0 = Auto, 1 = Rect (Venu Sq), 2 = Round, 3 = Instinct Crossover
    private var _appFontSetting as Number = 0; // 0 = Auto, 1 = Apple SF Pro, 2 = Garmin Native

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

    function initialize() {
        View.initialize();
        _pageTimer = new Timer.Timer();
        try { _fontSfStreetBold = WatchUi.loadResource(Rez.Fonts.SfStreetBold) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreetBold: " + e.getErrorMessage()); }
        try { _fontSfStreet = WatchUi.loadResource(Rez.Fonts.SfStreet) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreet: " + e.getErrorMessage()); }
        try { _fontSfCompactBold = WatchUi.loadResource(Rez.Fonts.SfCompactBold) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfCompactBold: " + e.getErrorMessage()); }
        try { _fontSfCompact = WatchUi.loadResource(Rez.Fonts.SfCompact) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfCompact: " + e.getErrorMessage()); }
        try { _fontSfMicro = WatchUi.loadResource(Rez.Fonts.SfMicro) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfMicro: " + e.getErrorMessage()); }
        try { _fontSfStreetBoldRot90 = WatchUi.loadResource(Rez.Fonts.SfStreetBoldRot90) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreetBoldRot90: " + e.getErrorMessage()); }
        try { _fontSfStreetRot90 = WatchUi.loadResource(Rez.Fonts.SfStreetRot90) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfStreetRot90: " + e.getErrorMessage()); }
        try { _fontSfMicroRot90 = WatchUi.loadResource(Rez.Fonts.SfMicroRot90) as Graphics.FontDefinition; } catch (e) { System.println("ERR SfMicroRot90: " + e.getErrorMessage()); }
        reloadSettings();
    }

    public function reloadSettings() as Void {
        var p = Storage.getValue("layout_profile");
        if (p != null) {
            _layoutProfile = p as Number;
        }
        var r = Storage.getValue("screen_rot");
        if (r != null) {
            _rotation = r as Number;
        }
        var af = Storage.getValue("app_font");
        if (af == null) {
            af = Storage.getValue("dist_font");
        }
        if (af != null) {
            _appFontSetting = af as Number;
        }
    }

    public function isSfFontActive() as Boolean {
        if (_appFontSetting == 1) {
            return true;
        } else if (_appFontSetting == 2) {
            return false;
        }
        var sysStats = System.getSystemStats();
        return (sysStats.totalMemory >= 512 * 1024);
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
        if (isSfFontActive()) {
            _ensureSfNumberFontsLoaded();
            if (distNum.length() >= 5 && _fontSfNumberMild != null) {
                return _fontSfNumberMild;
            }
            if (_fontSfNumberHot != null) {
                return _fontSfNumberHot;
            }
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
        _savedActive = CommManager.isActive;
        _savedDir = CommManager.direction;
        _savedDist = CommManager.distText;
        _savedNav = CommManager.navText;
        _savedEta = CommManager.etaText;
        _savedExit = CommManager.exitNumber;

        _isPreviewMode = true;
        _previewIndex = 0;
        _previewTimerTicks = 0;
        PreviewManager.applyStep(_previewIndex);
        WatchUi.requestUpdate();
    }

    public function stopPreviewMode() as Void {
        _isPreviewMode = false;
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
    public function getEffectiveProfile(dc as Dc) as Number {
        if (_layoutProfile > 0) {
            return _layoutProfile;
        }
        var devSettings = System.getDeviceSettings();
        if (devSettings has :screenShape) {
            if (devSettings.screenShape == System.SCREEN_SHAPE_ROUND) {
                return 2;
            }
        }
        var w = dc.getWidth();
        var h = dc.getHeight();
        if (w == 176 && h == 176) {
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
            var distMovedX = coords[0] - _dragStartX;
            var distMovedY = coords[1] - _dragStartY;
            if (distMovedX < 0) { distMovedX = -distMovedX; }
            if (distMovedY < 0) { distMovedY = -distMovedY; }
            if (distMovedX < 8 && distMovedY < 8) {
                onScreenTap(coords[0], coords[1]);
            } else {
                CommManager.requestPan(_panX, _panY);
            }
            return true;
        }
        return false;
    }

    public function onScreenTap(x as Number, y as Number) as Void {
        if (_currentTab == TAB_MAP) {
            if (y >= 290) {
                switchToHudTab();
                return;
            }
            if (x >= 255 && y >= 85 && y <= 145) {
                _mapZoom = (_mapZoom < 18) ? _mapZoom + 1 : 18;
                CommManager.requestZoom(_mapZoom);
                WatchUi.requestUpdate();
                return;
            }
            if (x >= 255 && y >= 150 && y <= 210) {
                _mapZoom = (_mapZoom > 14) ? _mapZoom - 1 : 14;
                CommManager.requestZoom(_mapZoom);
                WatchUi.requestUpdate();
                return;
            }
            if (x <= 65 && y >= 115 && y <= 175) {
                _panX = 0;
                _panY = 0;
                CommManager.recenterMap();
                WatchUi.requestUpdate();
                return;
            }
            return;
        }
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
        if (_isPreviewMode) {
            _previewTimerTicks++;
            if (_previewTimerTicks % 20 == 0) { // 20 ticks * 200ms = 4000ms (4s)
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

        if (_currentTab == TAB_MAP && !_isPreviewMode) {
            _drawMapScreen(dc);
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
    }

    function onHide() as Void {
        if (_pageTimer != null) {
            _pageTimer.stop();
        }
    }

    // -------------------------------------------------------------------------
    // Idle Standby Screen
    // -------------------------------------------------------------------------
    private function _drawIdleScreen(dc as Dc) as Void {
        var fontMicro = isSfFontActive() ? ((_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY) : Graphics.FONT_XTINY;
        var fontBold = isSfFontActive() ? ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE) : Graphics.FONT_LARGE;
        var fontStreet = isSfFontActive() ? ((_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_SMALL) : Graphics.FONT_SMALL;

        var isConnected = CommManager.isConnected() || (CommManager.rxCount > 0);
        var statusStr = isConnected ? Lang.format("Connected ($1$)", [CommManager.rxCount]) : "Ready";
        var strW = dc.getTextWidthInPixels(statusStr, fontMicro);
        var pillW = strW + 28;
        var pillX = (320 - pillW) / 2;
        var pillY = 16;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, 30, 15);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(pillX, pillY, pillW, 30, 15);

        var dotColor = isConnected ? COLOR_THEME_GREEN_ACCENT : COLOR_TEXT_MUTED;
        dc.setColor(dotColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(pillX + 13, pillY + 15, 4);

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pillX + 22, pillY + 14, fontMicro, statusStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var cx = 160;
        var cy = 135;
        var r = 50;

        VectorArrowRenderer.drawAmbientGlow(dc, cx, cy, GLOW_RGB_CYAN);

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(cx, cy, r);

        dc.setColor(COLOR_THEME_CYAN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [cx, cy - 26],
            [cx + 20, cy + 20],
            [cx, cy + 10],
            [cx - 20, cy + 20]
        ]);

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(160, 215, fontBold, "Navigation IQ", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(160, 246, fontStreet, "Waiting for navigation", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);

        var bottomStr = timeStr;
        var bottomW = dc.getTextWidthInPixels(bottomStr, fontMicro) + 26;
        var bottomX = (320 - bottomW) / 2;
        var bottomY = 314;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(bottomX, bottomY, bottomW, 32, 16);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(bottomX, bottomY, bottomW, 32, 16);
        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(160, bottomY + 13, fontMicro, bottomStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // -------------------------------------------------------------------------
    // Unified Apple Watch Style Aero HUD with Ambient Glow Gradient
    // -------------------------------------------------------------------------
    private function _drawUnifiedAppleHUD(dc as Dc) as Void {
        var theme = getNavTheme(CommManager.direction);
        var accentColor = theme[0] as Number;
        var badgeBgColor = theme[1] as Number;
        var glowRGB = theme[2] as Array<Number>;
        var etaBgColor = theme[3] as Number;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, CARD_Y, CARD_W, CARD_H, CARD_RADIUS);

        var badgeCx = CARD_X + BADGE_OFFSET_X;
        var badgeCy = CARD_Y + BADGE_OFFSET_Y;

        VectorArrowRenderer.drawAmbientGlow(dc, badgeCx, badgeCy, glowRGB);
        VectorArrowRenderer.maskCardCorners(dc, CARD_X, CARD_Y, CARD_W, CARD_H, CARD_RADIUS);

        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(CARD_X, CARD_Y, CARD_W, CARD_H, CARD_RADIUS);

        dc.setColor(badgeBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(badgeCx, badgeCy, BADGE_RADIUS);

        if (CommManager.isWaitingImage) {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, BADGE_RADIUS, accentColor, _animTick);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            VectorArrowRenderer.drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, BADGE_RADIUS, accentColor, _animTick);
        }

        var distFull = CommManager.distText;
        if (distFull.length() > 0) {
            var parts = TextRenderer.splitDist(distFull, isSfNumberFontActive());
            var distNum = parts[0];
            var distUnit = parts[1];

            var numX = CARD_X + DIST_OFFSET_X;
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
                var unitFont = isSfFontActive() ? ((_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE) : Graphics.FONT_MEDIUM;
                dc.setColor(COLOR_TEXT_UNIT, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    numX + numWidth + DIST_UNIT_GAP,
                    badgeCy + 5,
                    unitFont,
                    distUnit,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }

        var divY = CARD_Y + DIVIDER_OFFSET_Y;
        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(CARD_X + DIVIDER_PADDING_X, divY, CARD_X + CARD_W - DIVIDER_PADDING_X, divY);

        var streetText = CommManager.navText;
        if (streetText.length() > 0) {
            _drawDynamicWrappedText(dc, CARD_X + NAV_TEXT_PADDING_X, divY + NAV_TEXT_OFFSET_Y, CARD_W - (NAV_TEXT_PADDING_X * 2), CARD_H - (divY - CARD_Y) - NAV_TEXT_BOTTOM_PADDING, streetText, accentColor);
        }

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, BAR_Y, CARD_W, BAR_H, BAR_RADIUS);
        VectorArrowRenderer.maskCardCorners(dc, CARD_X, BAR_Y, CARD_W, BAR_H, BAR_RADIUS);

        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(CARD_X, BAR_Y, CARD_W, BAR_H, BAR_RADIUS);

        var etaBadgeX = CARD_X + ETA_BADGE_PADDING_X;
        var etaBadgeY = BAR_Y + ((BAR_H - ETA_BADGE_H) / 2);

        dc.setColor(etaBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(etaBadgeX, etaBadgeY, ETA_BADGE_W, ETA_BADGE_H, ETA_BADGE_RADIUS);

        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(etaBadgeX, etaBadgeY, ETA_BADGE_W, ETA_BADGE_H, ETA_BADGE_RADIUS);

        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
        var etaCenterY = BAR_Y + (BAR_H / 2) - 1;
        TextRenderer.drawMicroText(dc, etaBadgeX + (ETA_BADGE_W / 2), etaCenterY, etaStr, COLOR_TEXT_WHITE, true);

        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(CARD_X + 178, etaCenterY, 2);

        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        TextRenderer.drawMicroText(dc, CARD_X + 276, etaCenterY, timeStr, COLOR_TEXT_SILVER, false);
    }

    // -------------------------------------------------------------------------
    // Dynamic Font Scaling + Multi-Weight Typography
    // -------------------------------------------------------------------------
    private function _renderScrollingBlock(
        dc as Dc,
        lines1 as Array<String>,
        font1 as Graphics.FontDefinition,
        color1 as Number,
        h1 as Number,
        lines2 as Array<String>?,
        font2 as Graphics.FontDefinition?,
        color2 as Number?,
        h2 as Number?,
        startX as Number,
        startY as Number,
        maxWidth as Number,
        maxHeight as Number,
        accentColor as Number
    ) as Void {
        var count1 = lines1.size();
        var count2 = (lines2 != null) ? lines2.size() : 0;
        var totalH = (count1 * h1) + (count2 * ((h2 != null) ? h2 : 0));

        if (totalH <= maxHeight) {
            var curY = startY + (maxHeight - totalH) / 2 - 4;
            dc.setColor(color1, Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < count1; i++) {
                dc.drawText(startX, curY + (h1 / 2), font1, lines1[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                curY += h1;
            }
            if (lines2 != null && font2 != null && color2 != null && h2 != null) {
                dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
                for (var j = 0; j < count2; j++) {
                    dc.drawText(startX, curY + (h2 / 2), font2, lines2[j], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
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
            dc.drawText(startX, curY + (h1 / 2), font1, lines1[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            curY += h1;
        }
        if (lines2 != null && font2 != null && color2 != null && h2 != null) {
            dc.setColor(color2, Graphics.COLOR_TRANSPARENT);
            for (var j = 0; j < count2; j++) {
                dc.drawText(startX, curY + (h2 / 2), font2, lines2[j], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                curY += h2;
            }
        }

        if (dc has :clearClip) {
            dc.clearClip();
        }

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

    private function _drawDynamicWrappedText(dc as Dc, startX as Number, startY as Number, maxWidth as Number, maxHeight as Number, text as String, accentColor as Number) as Void {
        var parts = TextRenderer.splitActionAndStreet(text);
        var actionText = parts[0];
        var streetText = parts[1];

        var fontActionBold;
        var fontStreetReg;
        var fontCompactBold;
        var fontCompactReg;
        if (isSfFontActive()) {
            fontActionBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_SMALL;
            fontStreetReg = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_TINY;
            fontCompactBold = (_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY;
            fontCompactReg = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_XTINY;
        } else {
            fontActionBold = Graphics.FONT_MEDIUM;
            fontStreetReg = Graphics.FONT_SMALL;
            fontCompactBold = Graphics.FONT_SMALL;
            fontCompactReg = Graphics.FONT_TINY;
        }

        if (streetText.length() == 0) {
            var linesStreet = TextRenderer.wrapWithFont(dc, actionText, fontActionBold, maxWidth);
            var fontHStreet = dc.getFontHeight(fontActionBold) + 2;
            if (linesStreet.size() <= 2 && (linesStreet.size() * fontHStreet) <= maxHeight) {
                _renderScrollingBlock(dc, linesStreet, fontActionBold, Graphics.COLOR_WHITE, fontHStreet, null, null, null, null, startX, startY, maxWidth, maxHeight, accentColor);
                return;
            }

            var linesCompact = TextRenderer.wrapWithFont(dc, actionText, fontCompactBold, maxWidth);
            var fontHCompact = dc.getFontHeight(fontCompactBold) + 2;
            _renderScrollingBlock(dc, linesCompact, fontCompactBold, Graphics.COLOR_WHITE, fontHCompact, null, null, null, null, startX, startY, maxWidth, maxHeight, accentColor);
            return;
        }

        var linesAct = TextRenderer.wrapWithFont(dc, actionText, fontActionBold, maxWidth);
        var linesStr = TextRenderer.wrapWithFont(dc, streetText, fontStreetReg, maxWidth);
        var hAct = dc.getFontHeight(fontActionBold) + 2;
        var hStr = dc.getFontHeight(fontStreetReg) + 2;
        var totalH = (linesAct.size() * hAct) + (linesStr.size() * hStr);

        if (totalH <= maxHeight) {
            _renderScrollingBlock(dc, linesAct, fontActionBold, Graphics.COLOR_WHITE, hAct, linesStr, fontStreetReg, 0xE4E4E7, hStr, startX, startY, maxWidth, maxHeight, accentColor);
            return;
        }

        linesAct = TextRenderer.wrapWithFont(dc, actionText, fontCompactBold, maxWidth);
        linesStr = TextRenderer.wrapWithFont(dc, streetText, fontCompactReg, maxWidth);
        hAct = dc.getFontHeight(fontCompactBold) + 2;
        hStr = dc.getFontHeight(fontCompactReg) + 2;

        _renderScrollingBlock(dc, linesAct, fontCompactBold, Graphics.COLOR_WHITE, hAct, linesStr, fontCompactReg, 0xE4E4E7, hStr, startX, startY, maxWidth, maxHeight, accentColor);
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

        var badgeCx = 34;
        var badgeCy = 36;
        var badgeR = 24;

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

        var distFull = CommManager.distText;
        if (distFull.length() > 0) {
            var parts = TextRenderer.splitDist(distFull, isSfNumberFontActive());
            var distNum = parts[0];
            var distUnit = parts[1];

            var numFont = Graphics.FONT_NUMBER_MILD;
            if (distNum.length() > 3) {
                numFont = Graphics.FONT_LARGE;
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(66, 36, numFont, distNum, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            var numW = dc.getTextWidthInPixels(distNum, numFont);
            if (distUnit.length() > 0) {
                dc.drawText(66 + numW + 4, 36, Graphics.FONT_SMALL, distUnit, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(8, 70, w - 8, 70);
        dc.drawLine(8, 102, w - 8, 102);

        var streetText = CommManager.navText;
        if (streetText.length() > 0) {
            var lines = TextRenderer.wrapWithFont(dc, streetText, Graphics.FONT_TINY, w - 16);
            var textY = 106;
            for (var i = 0; i < lines.size() && i < 2; i++) {
                dc.drawText(w / 2, textY, Graphics.FONT_TINY, lines[i], Graphics.TEXT_JUSTIFY_CENTER);
                textY += 16;
            }
        }

        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
        var clock = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(12, h - 14, Graphics.FONT_XTINY, etaStr, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(w - 12, h - 14, Graphics.FONT_XTINY, timeStr, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function _drawInstinctIdleScreen(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var isConnected = CommManager.isConnected() || (CommManager.rxCount > 0);
        var statusStr = isConnected ? "Connected" : "Ready";

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 24, Graphics.FONT_TINY, "Navigation IQ", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, 46, Graphics.FONT_XTINY, statusStr, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawLine(8, 70, w - 8, 70);
        dc.drawLine(8, 102, w - 8, 102);

        var clock = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);
        dc.drawText(w / 2, 116, Graphics.FONT_SMALL, "Waiting Nav...", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, 146, Graphics.FONT_TINY, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
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
        var etaBgColor = theme[3] as Number;

        var fontMicro = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;
        var fontBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_SMALL;
        var fontStreet = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_TINY;

        var badgeCx = w / 2;
        var badgeCy = 52;
        var badgeR = 36;

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
        if (distFull.length() > 0) {
            var parts = TextRenderer.splitDist(distFull, isSfNumberFontActive());
            var distNum = parts[0];
            var distUnit = parts[1];

            var numFont = _getDistanceFont(distNum, distUnit);
            var numW = dc.getTextWidthInPixels(distNum, numFont);
            var unitW = (distUnit.length() > 0) ? dc.getTextWidthInPixels(distUnit, fontStreet) : 0;
            var totalDistW = numW + 6 + unitW;
            var startDistX = (w - totalDistW) / 2;

            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(startDistX, 108, numFont, distNum, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

            if (distUnit.length() > 0) {
                dc.setColor(COLOR_TEXT_UNIT, Graphics.COLOR_TRANSPARENT);
                dc.drawText(startDistX + numW + 6, 114, fontStreet, distUnit, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        var streetText = CommManager.navText;
        if (streetText.length() > 0) {
            var parts = TextRenderer.splitActionAndStreet(streetText);
            var actionText = parts[0];
            var street = parts[1];

            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, 146, fontBold, actionText, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            if (street.length() > 0) {
                dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
                dc.drawText(w / 2, 172, fontStreet, street, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }

        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
        var clock = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clock.hour.format("%02d"), clock.min.format("%02d")]);

        var pillW = 180;
        var pillH = 34;
        var pillX = (w - pillW) / 2;
        var pillY = h - 46;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(pillX, pillY, pillW, pillH, 17);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(pillX, pillY, pillW, pillH, 17);

        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pillX + 46, pillY + 16, fontMicro, etaStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(w / 2, pillY + 16, 2);

        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(pillX + 134, pillY + 16, fontMicro, timeStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
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

    private function _drawMapScreen(dc as Dc) as Void {
        var fontMicro = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;
        var fontBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_LARGE;

        var mapW = CommManager.mapWidth;
        var mapH = CommManager.mapHeight;
        var scale = (mapW > 0) ? (320 / mapW) : 2;
        if (scale < 1) {
            scale = 1;
        }
        var totalDrawW = mapW * scale;
        var totalDrawH = mapH * scale;
        var baseStartX = (320 - totalDrawW) / 2;
        var baseStartY = (360 - totalDrawH) / 2;
        var startX = baseStartX + _panX;
        var startY = baseStartY + _panY;

        // 1. Render RLE Decompressed OSM Map Pixels Edge-to-Edge with Pan Offset
        var rle = CommManager.mapRleData;
        if (rle != null && rle.size() > 0) {
            var px = 0;
            var py = 0;
            var i = 0;
            var rleLen = rle.size();
            while (i < rleLen - 1 && py < mapH) {
                var runLen = (rle[i] as Number) & 0xFF;
                var colIdx = (rle[i + 1] as Number) & 0xFF;
                if (colIdx != 0) { // Skip pure black background pixels for AMOLED power efficiency
                    var colRgb = _getMapPaletteColor(colIdx);
                    dc.setColor(colRgb, Graphics.COLOR_TRANSPARENT);
                    while (runLen > 0 && py < mapH) {
                        var span = runLen;
                        if (px + span > mapW) {
                            span = mapW - px;
                        }
                        var drawX = startX + (px * scale);
                        var drawY = startY + (py * scale);
                        var drawW = span * scale;
                        
                        if (drawY >= 0 && drawY < 360) {
                            var clipX1 = (drawX < 0) ? 0 : drawX;
                            var clipX2 = (drawX + drawW > 320) ? 320 : drawX + drawW;
                            if (clipX2 > clipX1) {
                                dc.fillRectangle(clipX1, drawY, clipX2 - clipX1, scale);
                            }
                        }
                        px += span;
                        runLen -= span;
                        if (px >= mapW) {
                            px = 0;
                            py++;
                        }
                    }
                } else {
                    px += runLen;
                    while (px >= mapW) {
                        px -= mapW;
                        py++;
                    }
                }
                i += 2;
            }
        } else {
            var pulseR = 30 + ((_animTick * 2) % 45);
            dc.setColor(COLOR_THEME_CYAN_ACCENT, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(1);
            dc.drawCircle(160, 180, pulseR);

            dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
            dc.drawText(160, 222, fontMicro, "Loading OSM Map...", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var mapCenterX = startX + (totalDrawW / 2);
        var mapCenterY = startY + (totalDrawH / 2);

        if (mapCenterX >= 0 && mapCenterX <= 320 && mapCenterY >= 0 && mapCenterY <= 360) {
            dc.setColor(0x0A84FF, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(mapCenterX, mapCenterY, 9);
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(mapCenterX, mapCenterY, 4);

            if (CommManager.mapHeading > 0) {
                var rad = Math.toRadians(CommManager.mapHeading - 90);
                var tipX = mapCenterX + (22 * Math.cos(rad)).toNumber();
                var tipY = mapCenterY + (22 * Math.sin(rad)).toNumber();
                var base1X = mapCenterX + (9 * Math.cos(rad + 2.5)).toNumber();
                var base1Y = mapCenterY + (9 * Math.sin(rad + 2.5)).toNumber();
                var base2X = mapCenterX + (9 * Math.cos(rad - 2.5)).toNumber();
                var base2Y = mapCenterY + (9 * Math.sin(rad - 2.5)).toNumber();

                dc.setColor(COLOR_THEME_CYAN_ACCENT, Graphics.COLOR_TRANSPARENT);
                dc.fillPolygon([[tipX, tipY], [base1X, base1Y], [base2X, base2Y]]);
            }
        }

        // Floating Glassmorphism Overlay Controls
        // Zoom [+] Button (Right Top)
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(287, 115, 19);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(287, 115, 19);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(287, 111, fontBold, "+", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Zoom [-] Button (Right Bottom)
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(287, 175, 19);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(287, 175, 19);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(287, 171, fontBold, "-", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // GPS Recenter Button (Left Middle - highlighted in Cyan if panned away)
        var isPanned = (_panX != 0 || _panY != 0);
        dc.setColor(isPanned ? COLOR_THEME_CYAN_BADGE : COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(33, 145, 19);
        dc.setColor(isPanned ? COLOR_THEME_CYAN_ACCENT : COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(33, 145, 19);
        dc.setColor(isPanned ? COLOR_THEME_CYAN_ACCENT : COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(33, 145, 4);
        dc.drawCircle(33, 145, 8);

        // Top Status Header Floating Pills (Speed, Zoom Level)
        var speedStr = Lang.format("$1$ km/h", [CommManager.mapSpeed]);
        var speedW = dc.getTextWidthInPixels(speedStr, fontMicro) + 18;
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(14, 14, speedW, 30, 15);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(14, 14, speedW, 30, 15);
        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(14 + (speedW / 2), 14 + 12, fontMicro, speedStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var zoomNames = { 14 => "2km", 15 => "1km", 16 => "500m", 17 => "250m", 18 => "100m" };
        var zoomStr = zoomNames.hasKey(_mapZoom) ? zoomNames[_mapZoom] as String : "500m";
        var zoomW = dc.getTextWidthInPixels(zoomStr, fontMicro) + 18;
        var zoomX = 320 - 14 - zoomW;
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(zoomX, 14, zoomW, 30, 15);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(zoomX, 14, zoomW, 30, 15);
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(zoomX + (zoomW / 2), 14 + 12, fontMicro, zoomStr, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom Mini Turn Maneuver Pill (Y: 294 to 344)
        var navW = 296;
        var navH = 50;
        var navX = (320 - navW) / 2;
        var navY = 294;

        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(navX, navY, navW, navH, 20);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(navX, navY, navW, navH, 20);

        if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, navX + 28, navY + 25, CommManager.direction, CommManager.exitNumber, COLOR_THEME_CYAN_ACCENT);
        }

        if (CommManager.distText.length() > 0) {
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(navX + 60, navY + 24, fontBold, CommManager.distText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
