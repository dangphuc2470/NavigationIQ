import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;

// Screen dimensions for Venu Sq 2: 320 x 360 px
const SCREEN_W = 320;
const SCREEN_H = 360;

class NavigationIQView extends WatchUi.View {

    private var _pageTimer as Timer.Timer?;
    private var _animTick as Number = 0;
    private var _pageIndex as Number = 0;

    function initialize() {
        View.initialize();
        _pageTimer = new Timer.Timer();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        CommManager.start();
        if (_pageTimer != null) {
            _pageTimer.start(method(:onTimerTick), 200, true);
        }
    }

    function onTimerTick() as Void {
        _animTick++;
        if (_animTick % 12 == 0) { // Every 2.4s advance page
            _pageIndex++;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        CommManager.checkHapticUpdate();

        // Clear background - True AMOLED Pure Black
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (!CommManager.isActive) {
            _drawIdleScreen(dc);
        } else {
            _drawNavScreen(dc);
        }
    }

    function onHide() as Void {
        if (_pageTimer != null) {
            _pageTimer.stop();
        }
    }

    // -------------------------------------------------------------------------
    // Theme Palette Selector:
    // Straight = Xanh biển (Cyan), Turn Left = Cam (Amber), Turn Right = Xanh lá (Emerald)
    // -------------------------------------------------------------------------
    private function _getTheme(dir as Number) as Array<Number> {
        if (dir == DIR_STRAIGHT || dir == DIR_ROUNDABOUT_3) {
            // Straight Ahead / Straight Roundabout: Xanh biển (Cyan/Blue)
            return [0x00E5FF, 0x0C4A6E, 0x38BDF8, 0x0369A1] as Array<Number>;
        } else if (dir == DIR_LEFT || dir == DIR_SLIGHT_LEFT || dir == DIR_SHARP_LEFT ||
                   dir == DIR_ROUNDABOUT_4 || dir == DIR_ROUNDABOUT_5 || dir == DIR_UTURN) {
            // Turn Left / U-turn / Left Roundabout: Cam (Amber/Orange)
            return [0xF59E0B, 0x451A03, 0xFCD34D, 0x78350F] as Array<Number>;
        } else if (dir == DIR_RIGHT || dir == DIR_SLIGHT_RIGHT || dir == DIR_SHARP_RIGHT ||
                   dir == DIR_ROUNDABOUT_1 || dir == DIR_ROUNDABOUT_2) {
            // Turn Right / Right Roundabout: Xanh lá (Emerald Green)
            return [0x10B981, 0x064E3B, 0x6EE7B7, 0x065F46] as Array<Number>;
        } else {
            // Default: Xanh biển
            return [0x00E5FF, 0x0C4A6E, 0x38BDF8, 0x0369A1] as Array<Number>;
        }
    }

    // -------------------------------------------------------------------------
    // Idle Screen - Modern Standby HUD
    // -------------------------------------------------------------------------
    private function _drawIdleScreen(dc as Dc) as Void {
        // Top status pill badge
        dc.setColor(0x064E3B, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(50, 24, 220, 30, 15);
        dc.setColor(0x10B981, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(68, 39, 4);
        dc.setColor(0xA7F3D0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            165, 39,
            Graphics.FONT_XTINY,
            "Garmin Link: Ready",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Center Radar / Compass Graphic
        var cx = 160;
        var cy = 165;
        dc.setColor(0x0F172A, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 64);

        dc.setColor(0x1E293B, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, 64);
        dc.drawCircle(cx, cy, 40);

        // Center vector arrow
        var arrowPts = [
            [cx, cy - 38],
            [cx + 18, cy + 16],
            [cx, cy + 6],
            [cx - 18, cy + 16]
        ];
        dc.setColor(0x00E5FF, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(arrowPts);

        // App Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            160, 248,
            Graphics.FONT_MEDIUM,
            "Navigation IQ",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Subtitle status
        dc.setColor(0x94A3B8, Graphics.COLOR_TRANSPARENT);
        var subText = (CommManager.rxCount > 0) ? ("Packets: " + CommManager.rxCount) : "Waiting for Google Maps...";
        dc.drawText(
            160, 280,
            Graphics.FONT_XTINY,
            subText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Bottom clock pill
        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(0x1E293B, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(110, 314, 100, 26, 13);
        dc.setColor(0x94A3B8, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            160, 327,
            Graphics.FONT_XTINY,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // -------------------------------------------------------------------------
    // Active HUD Screen - Dynamic Maneuver-Aware Theming
    // -------------------------------------------------------------------------
    private function _drawNavScreen(dc as Dc) as Void {
        var theme = _getTheme(CommManager.direction);
        var accentColor = theme[0];
        var badgeBgColor = theme[1];
        var subtextColor = theme[2];
        var borderTint = theme[3];

        // ---------------------------------------------------------------------
        // 1. Top Card: Turn Arrow & Distance + Marquee Next Street (Y: 8 to 122)
        // ---------------------------------------------------------------------
        dc.setColor(0x0F172A, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(10, 8, 300, 114, 18);
        dc.setColor(borderTint, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(10, 8, 300, 114, 18);

        // Left circle badge for Turn Arrow (Center X: 64, Y: 65, Radius: 38)
        var arrowCx = 64;
        var arrowCy = 65;
        var arrowR  = 38;

        dc.setColor(badgeBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(arrowCx, arrowCy, arrowR);
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        dc.drawCircle(arrowCx, arrowCy, arrowR);

        // Render Real Google Maps RLE Bitmap if available and NOT waiting, otherwise Spinner
        if (CommManager.isWaitingImage) {
            // Rotating Radar Spinner while awaiting new turn graphic
            _drawLoadingSpinner(dc, arrowCx, arrowCy, arrowR, accentColor, subtextColor);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            _drawRleBitmap(dc, arrowCx, arrowCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            _drawVectorArrow(dc, arrowCx, arrowCy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            // Rotating Radar Spinner while awaiting new turn graphic
            _drawLoadingSpinner(dc, arrowCx, arrowCy, arrowR, accentColor, subtextColor);
        }

        // Right side of Top Card: Distance & Next Street
        var distFull = CommManager.distText;
        var distNum = "";
        var distUnit = "";

        if (distFull.length() > 0) {
            var parts = _splitDist(distFull);
            distNum = parts[0];
            distUnit = parts[1];

            var numX = 114;
            var numY = (CommManager.nextStreet.length() > 0) ? 44 : 65;

            var numFont = Graphics.FONT_NUMBER_HOT;
            if (distNum.length() >= 3 || distUnit.length() >= 2) {
                numFont = Graphics.FONT_NUMBER_MILD;
            }

            // Draw distance number in Dynamic Accent
            dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                numX, numY,
                numFont,
                distNum,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // Draw unit (e.g. "m", "km") next to distance number
            var numWidth = dc.getTextWidthInPixels(distNum, numFont);
            if (distUnit.length() > 0) {
                dc.setColor(subtextColor, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    numX + numWidth + 6, numY + 8,
                    Graphics.FONT_SMALL,
                    distUnit,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }

            // Smooth Marquee Scrolling for Next Street Name
            if (CommManager.nextStreet.length() > 0) {
                dc.setColor(subtextColor, Graphics.COLOR_TRANSPARENT);
                var fullStreet = CommManager.nextStreet;
                var font = Graphics.FONT_XTINY;
                var strWidth = dc.getTextWidthInPixels(fullStreet, font);
                var maxW = 180;
                var textY = 88;

                if (strWidth <= maxW) {
                    dc.drawText(numX, textY, font, fullStreet, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                } else {
                    // Smooth Marquee Animation
                    var speed = 3;
                    var totalCycle = strWidth + 60;
                    var offset = (_animTick * speed) % totalCycle;

                    if (dc has :setClip) {
                        dc.setClip(numX, textY - 14, maxW, 28);
                    }
                    dc.drawText(numX - offset, textY, font, fullStreet, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                    if (offset > (strWidth - maxW)) {
                        dc.drawText(numX - offset + strWidth + 60, textY, font, fullStreet, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                    }
                    if (dc has :clearClip) {
                        dc.clearClip();
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // 2. Middle Card: Instruction with Dynamic Accent Bar (Y: 128 to 284)
        // ---------------------------------------------------------------------
        dc.setColor(0x0F172A, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(10, 128, 300, 156, 18);
        dc.setColor(0x1E293B, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(10, 128, 300, 156, 18);

        // Dynamic Accent Line matching maneuver theme
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(16, 142, 4, 128, 2);

        var streetText = CommManager.navText;
        if (streetText.length() > 0) {
            _drawDynamicWrappedText(dc, 30, 134, 268, 144, streetText, accentColor);
        }

        // ---------------------------------------------------------------------
        // 3. Bottom Pill Bar: ETA & Clock Time (Y: 292 to 344)
        // ---------------------------------------------------------------------
        var barY = 292;
        dc.setColor(0x111827, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(10, barY, 300, 52, 26);
        dc.setColor(0x1F2937, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawRoundedRectangle(10, barY, 300, 52, 26);

        // ETA badge on left
        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "Navigating";
        dc.setColor(0x064E3B, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(22, barY + 11, 130, 30, 15);
        dc.setColor(0x34D399, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            87, barY + 26,
            Graphics.FONT_XTINY,
            etaStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Live Clock Time on right
        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(0xE2E8F0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            285, barY + 26,
            Graphics.FONT_TINY,
            timeStr,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // -------------------------------------------------------------------------
    // Smooth Loading Spinner when waiting for new maneuver
    // -------------------------------------------------------------------------
    private function _drawLoadingSpinner(dc as Dc, cx as Number, cy as Number, radius as Number, accent as Number, sub as Number) as Void {
        var startDeg = (_animTick * 25) % 360;
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);
        if (dc has :drawArc) {
            dc.drawArc(cx, cy, radius - 8, Graphics.ARC_CLOCKWISE, startDeg, (startDeg + 100) % 360);
        } else {
            dc.drawCircle(cx, cy, 6);
        }
        dc.setColor(sub, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 4);
    }

    // -------------------------------------------------------------------------
    // RLE Bitmap Renderer (Renders real Google Maps bitmap on Garmin DC)
    // -------------------------------------------------------------------------
    private function _drawRleBitmap(dc as Dc, cx as Number, cy as Number, rleData as Array<Number>) as Void {
        dc.setPenWidth(1);
        var w = rleData[0];
        var h = rleData[1];
        var startX = cx - (w / 2);
        var startY = cy - (h / 2);

        var curX = 0;
        var curY = 0;
        var idx = 2;
        var len = rleData.size();

        while (idx < len - 1) {
            var color = rleData[idx];
            var count = rleData[idx + 1];
            idx += 2;

            if (color != 0) {
                // Non-transparent pixel: draw white icon line
                dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
                var rem = count;
                while (rem > 0) {
                    var canFit = w - curX;
                    var drawSpan = (rem < canFit) ? rem : canFit;
                    dc.drawLine(startX + curX, startY + curY, startX + curX + drawSpan - 1, startY + curY);
                    curX += drawSpan;
                    if (curX >= w) {
                        curX = 0;
                        curY++;
                    }
                    rem -= drawSpan;
                }
            } else {
                curX += count;
                while (curX >= w) {
                    curX -= w;
                    curY++;
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Split Distance string into [Number, Unit] safely
    // -------------------------------------------------------------------------
    private function _splitDist(distStr as String) as Array<String> {
        var num = "";
        var unit = "";
        var hitSpace = false;

        for (var i = 0; i < distStr.length(); i++) {
            var ch = distStr.substring(i, i + 1);
            if (ch.equals(" ") || ch.equals("\n") || ch.equals("\t")) {
                if (num.length() > 0) {
                    hitSpace = true;
                }
                continue;
            }

            var isDigit = (ch.equals("0") || ch.equals("1") || ch.equals("2") || ch.equals("3") ||
                           ch.equals("4") || ch.equals("5") || ch.equals("6") || ch.equals("7") ||
                           ch.equals("8") || ch.equals("9") || ch.equals(".") || ch.equals(","));

            if (isDigit && !hitSpace) {
                num = num + ch;
            } else {
                hitSpace = true;
                unit = unit + ch;
            }
        }

        if (num.length() == 0 && unit.length() > 0) {
            num = unit;
            unit = "";
        }

        return [num, unit] as Array<String>;
    }

    // -------------------------------------------------------------------------
    // Dynamic Font Scaling + Auto-Pagination Text Renderer
    // -------------------------------------------------------------------------
    private function _drawDynamicWrappedText(dc as Dc, startX as Number, startY as Number, maxWidth as Number, maxHeight as Number, text as String, pageDotAccent as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // 1. Try FONT_SMALL for short instructions (<= 2 lines)
        var linesSmall = _wrapWithFont(dc, text, Graphics.FONT_SMALL, maxWidth);
        var fontHSmall = dc.getFontHeight(Graphics.FONT_SMALL);
        if (linesSmall.size() <= 2 && (linesSmall.size() * (fontHSmall + 2)) <= maxHeight) {
            _renderLines(dc, linesSmall, Graphics.FONT_SMALL, startX, startY, maxHeight, fontHSmall + 2);
            return;
        }

        // 2. Try FONT_TINY for medium instructions (<= 3 lines)
        var linesTiny = _wrapWithFont(dc, text, Graphics.FONT_TINY, maxWidth);
        var fontHTiny = dc.getFontHeight(Graphics.FONT_TINY);
        if (linesTiny.size() <= 3 && (linesTiny.size() * (fontHTiny + 2)) <= maxHeight) {
            _renderLines(dc, linesTiny, Graphics.FONT_TINY, startX, startY, maxHeight, fontHTiny + 2);
            return;
        }

        // 3. Fallback to FONT_XTINY (Smallest font)
        var linesXTiny = _wrapWithFont(dc, text, Graphics.FONT_XTINY, maxWidth);
        var fontHXTiny = dc.getFontHeight(Graphics.FONT_XTINY);
        var lineH = fontHXTiny + 2;
        var totalLines = linesXTiny.size();
        var totalH = totalLines * lineH;

        if (totalH <= maxHeight) {
            // Fits cleanly inside the card without scrolling
            _renderLines(dc, linesXTiny, Graphics.FONT_XTINY, startX, startY, maxHeight, lineH);
        } else {
            // Smooth Vertical Auto-Scrolling with Pause at Top and Bottom
            if (dc has :setClip) {
                dc.setClip(startX - 2, startY + 4, maxWidth + 4, maxHeight - 8);
            }

            var overflow = totalH - maxHeight + 16;
            // 70 ticks cycle (14 seconds at 200ms per tick):
            // 0 - 15 ticks (3s): Pause at top
            // 15 - 35 ticks (4s): Smooth glide down
            // 35 - 50 ticks (3s): Pause at bottom
            // 50 - 70 ticks (4s): Smooth glide back to top
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

            var renderY = startY + 8 - scrollOffset;
            for (var j = 0; j < totalLines; j++) {
                dc.drawText(startX, renderY + (j * lineH), Graphics.FONT_XTINY, linesXTiny[j], Graphics.TEXT_JUSTIFY_LEFT);
            }

            if (dc has :clearClip) {
                dc.clearClip();
            }

            // Subtle vertical scroll indicator track & thumb on right edge
            var barX = startX + maxWidth - 4;
            var barTrackH = maxHeight - 24;
            var thumbH = (maxHeight.toFloat() / totalH.toFloat() * barTrackH).toNumber();
            if (thumbH < 12) {
                thumbH = 12;
            }
            var thumbY = startY + 12 + ((scrollOffset.toFloat() / overflow.toFloat()) * (barTrackH - thumbH)).toNumber();
            dc.setColor(0x334155, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, startY + 12, 2, barTrackH, 1);
            dc.setColor(pageDotAccent, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, thumbY, 2, thumbH, 1);
        }
    }

    private function _wrapWithFont(dc as Dc, text as String, font as Graphics.FontDefinition, maxWidth as Number) as Array<String> {
        var words = _splitWords(text);
        var lines = [] as Array<String>;
        var curLine = "";

        for (var i = 0; i < words.size(); i++) {
            var word = words[i];
            var testLine = (curLine.length() == 0) ? word : (curLine + " " + word);
            var width = dc.getTextWidthInPixels(testLine, font);

            if (width > maxWidth && curLine.length() > 0) {
                lines.add(curLine);
                curLine = word;
            } else {
                curLine = testLine;
            }
        }

        if (curLine.length() > 0) {
            lines.add(curLine);
        }

        return lines;
    }

    private function _renderLines(dc as Dc, lines as Array<String>, font as Graphics.FontDefinition, startX as Number, startY as Number, maxHeight as Number, lineH as Number) as Void {
        var totalH = lines.size() * lineH;
        var renderY = startY;
        if (maxHeight > totalH) {
            renderY = startY + (maxHeight - totalH) / 2;
        }
        for (var j = 0; j < lines.size(); j++) {
            dc.drawText(startX, renderY + (j * lineH), font, lines[j], Graphics.TEXT_JUSTIFY_LEFT);
        }
    }

    private function _splitWords(text as String) as Array<String> {
        var words = [] as Array<String>;
        var cur = "";
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i + 1);
            if (ch.equals(" ") || ch.equals("\n") || ch.equals("\t")) {
                if (cur.length() > 0) {
                    words.add(cur);
                    cur = "";
                }
            } else {
                cur = cur + ch;
            }
        }
        if (cur.length() > 0) {
            words.add(cur);
        }
        return words;
    }

    // -------------------------------------------------------------------------
    // High-Precision Vector Turn Arrow Engine (with exact Roundabout geometry)
    // -------------------------------------------------------------------------
    private function _drawVectorArrow(dc as Dc, cx as Number, cy as Number, dir as Number, exitNum as Number, arrowAccent as Number) as Void {
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);

        // --- ROUNDABOUT WITH EXACT ANGLES ---
        if (dir >= DIR_ROUNDABOUT_1 && dir <= DIR_ROUNDABOUT_5) {
            // 1. Roundabout Ring (Loop)
            dc.setPenWidth(4);
            dc.setColor(0x64748B, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy - 2, 15);

            // 2. Bottom Entry Stem (from 6 o'clock entering clockwise)
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(6);
            dc.drawLine(cx - 8, cy + 18, cx - 8, cy + 9);

            // 3. Exit branch & Arrowhead based on Exit #
            if (dir == DIR_ROUNDABOUT_1) {
                // 1st Exit -> 45° Slight Right (Top-Right ↗)
                dc.drawLine(cx + 8, cy - 8, cx + 18, cy - 18);
                var head = [
                    [cx + 8, cy - 20],
                    [cx + 24, cy - 24],
                    [cx + 20, cy - 8]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_2) {
                // 2nd Exit -> 90° Right (East →)
                dc.drawLine(cx + 12, cy - 2, cx + 20, cy - 2);
                var head = [
                    [cx + 18, cy - 10],
                    [cx + 28, cy - 2],
                    [cx + 18, cy + 6]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_3) {
                // 3rd Exit -> 0° Straight (North ↑)
                dc.drawLine(cx, cy - 14, cx, cy - 22);
                var head = [
                    [cx - 8, cy - 20],
                    [cx, cy - 30],
                    [cx + 8, cy - 20]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_4) {
                // 4th Exit -> 270° Left (West ←)
                dc.drawLine(cx - 12, cy - 2, cx - 20, cy - 2);
                var head = [
                    [cx - 18, cy - 10],
                    [cx - 28, cy - 2],
                    [cx - 18, cy + 6]
                ];
                dc.fillPolygon(head);
            } else {
                // 5th Exit -> 225° Sharp Left (South-West ↙)
                dc.drawLine(cx - 8, cy + 6, cx - 18, cy + 16);
                var head = [
                    [cx - 20, cy + 8],
                    [cx - 24, cy + 24],
                    [cx - 8, cy + 20]
                ];
                dc.fillPolygon(head);
            }

            // 4. Clean exit number in center circle
            if (exitNum > 0) {
                dc.setColor(arrowAccent, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    cx, cy - 2,
                    Graphics.FONT_XTINY,
                    "" + exitNum,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
            return;
        }

        // --- STANDARD MANEUVER ARROWS ---
        if (dir == DIR_LEFT || dir == DIR_SHARP_LEFT) {
            // Turn Left Arrow (Bold 9px)
            dc.setPenWidth(9);
            dc.drawLine(cx + 10, cy + 18, cx + 10, cy - 2);
            dc.drawLine(cx + 10, cy - 2, cx - 8, cy - 2);
            var head = [
                [cx - 8, cy - 14],
                [cx - 22, cy - 2],
                [cx - 8, cy + 10]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_RIGHT || dir == DIR_SHARP_RIGHT) {
            // Turn Right Arrow (Bold 9px)
            dc.setPenWidth(9);
            dc.drawLine(cx - 10, cy + 18, cx - 10, cy - 2);
            dc.drawLine(cx - 10, cy - 2, cx + 8, cy - 2);
            var head = [
                [cx + 8, cy - 14],
                [cx + 22, cy - 2],
                [cx + 8, cy + 10]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_SLIGHT_LEFT) {
            // Slight Left / Bear Left (Bold 9px)
            dc.setPenWidth(9);
            dc.drawLine(cx + 6, cy + 18, cx + 6, cy + 4);
            dc.drawLine(cx + 6, cy + 4, cx - 8, cy - 8);
            var head = [
                [cx - 16, cy - 2],
                [cx - 18, cy - 18],
                [cx - 2, cy - 16]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_SLIGHT_RIGHT) {
            // Slight Right / Bear Right (Bold 9px)
            dc.setPenWidth(9);
            dc.drawLine(cx - 6, cy + 18, cx - 6, cy + 4);
            dc.drawLine(cx - 6, cy + 4, cx + 8, cy - 8);
            var head = [
                [cx + 2, cy - 16],
                [cx + 18, cy - 18],
                [cx + 16, cy - 2]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_UTURN) {
            // U-Turn (Loop left & down, Bold 8px)
            dc.setPenWidth(8);
            dc.drawLine(cx + 10, cy + 18, cx + 10, cy - 4);
            dc.drawLine(cx + 10, cy - 4, cx - 10, cy - 4);
            dc.drawLine(cx - 10, cy - 4, cx - 10, cy + 8);
            var head = [
                [cx - 19, cy + 6],
                [cx - 10, cy + 20],
                [cx - 1, cy + 6]
            ];
            dc.fillPolygon(head);
        }
        else {
            // Straight Ahead (Bold 9px)
            dc.setPenWidth(9);
            dc.drawLine(cx, cy + 18, cx, cy - 6);
            var head = [
                [cx - 14, cy - 4],
                [cx, cy - 22],
                [cx + 14, cy - 4]
            ];
            dc.fillPolygon(head);
        }
    }
}
