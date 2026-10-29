import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Application.Storage;

class ColorNavigationIQView extends NavigationIQView {

    function initialize() {
        NavigationIQView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        var effectiveProfile = getEffectiveProfile(dc);
        if (effectiveProfile == 3) {
            NavigationIQView.onUpdate(dc);
            return;
        }

        _needsAnimRedraw = false;
        _wasToastActive = CommManager.isToastActive();
        _lastDrawnMin = System.getClockTime().min;

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        if (_isPreviewMode) {
            CommManager.checkHapticUpdate();
        }

        dc.setColor(COLOR_BG_AMOLED, COLOR_BG_AMOLED);
        dc.clear();

        // Arrived at destination summary screen
        if (CommManager.isArrived || CommManager.direction == DIR_ARRIVED) {
            _drawArrivedScreen(dc);
            if (CommManager.isToastActive()) {
                _drawToastOverlay(dc, effectiveProfile);
            }
            return;
        }

        // Vector Radar Corridor Screen
        if (_currentTab == TAB_MAP) {
            _drawVectorRadarScreen(dc);
            return;
        }

        if (!CommManager.isActive && !_isPreviewMode) {
            _drawIdleScreen(dc);
            return;
        }

        if (effectiveProfile == 2) {
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
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeRadius, accentColor, _animTick);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            VectorArrowRenderer.drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeRadius, accentColor, _animTick);
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

        _needsAnimRedraw = true;
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
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgePx, badgePy, badgeR, accentColor, _animTick);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrowRot90(dc, badgePx, badgePy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgePx, badgePy, badgeR, accentColor, _animTick);
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

                _needsAnimRedraw = true;
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
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, accentColor, _animTick);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            VectorArrowRenderer.drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            VectorArrowRenderer.drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            _needsAnimRedraw = true; VectorArrowRenderer.drawLoadingSpinner(dc, badgeCx, badgeCy, badgeR, accentColor, _animTick);
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

                _needsAnimRedraw = true;
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
            path = [0, -30, 0, 0, 0, 45, 15, 75] as Array<Number>;
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
            alleys = [] as Array<Number>;
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

    // -------------------------------------------------------------------------
    // Instinct Crossover Screen (High-Contrast Monochrome MIP)
    // -------------------------------------------------------------------------

}
