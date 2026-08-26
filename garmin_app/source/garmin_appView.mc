import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;
import Toybox.Timer;
import Toybox.Math;

// =============================================================================
// UI CONSTANTS & DESIGN SYSTEM TOKENS (Easily Configurable)
// =============================================================================

// 1. Device Screen
const SCREEN_W = 320;
const SCREEN_H = 360;

// 2. Main Navigation Card Layout (Maximized Screen Real Estate)
const CARD_X = 8;
const CARD_Y = 8;
const CARD_W = 304;
const CARD_H = 276;
const CARD_RADIUS = 30;

// 3. Turn Badge Geometry
const BADGE_OFFSET_X = 52;
const BADGE_OFFSET_Y = 52;
const BADGE_RADIUS = 36;
const BADGE_SPINNER_PEN_WIDTH = 6;

// 4. Distance Row Layout
const DIST_OFFSET_X = 102;
const DIST_UNIT_GAP = 6;

// 5. Divider Line
const DIVIDER_OFFSET_Y = 106;
const DIVIDER_PADDING_X = 16;

// 6. Navigation Text Box Geometry
const NAV_TEXT_PADDING_X = 16;
const NAV_TEXT_OFFSET_Y = 10;
const NAV_TEXT_BOTTOM_PADDING = 14;

// 7. Bottom Pill Bar Layout (Flush to bottom edge)
const BAR_Y = 290;
const BAR_H = 62;
const BAR_RADIUS = 28;

// 8. ETA Capsule Badge
const ETA_BADGE_W = 124;
const ETA_BADGE_H = 38;
const ETA_BADGE_RADIUS = 19;
const ETA_BADGE_PADDING_X = 14;

// 9. Ambient Glow Radial Gradient
const GLOW_STEPS = 70;
const GLOW_RADIUS_FACTOR = 2.0;

// 10. Color Tokens
const COLOR_BG_AMOLED = 0x000000;
const COLOR_BG_CARD = 0x18181B;
const COLOR_BORDER_CARD = 0x27272A;
const COLOR_DIVIDER = 0x27272A;

const COLOR_TEXT_WHITE = 0xFFFFFF;
const COLOR_TEXT_SILVER = 0xE4E4E7;
const COLOR_TEXT_MUTED = 0x71717A;
const COLOR_TEXT_UNIT = 0x9CA3AF;

// Straight / 2nd Exit (Cyan Theme)
const COLOR_THEME_CYAN_ACCENT = 0x00E5FF;
const COLOR_THEME_CYAN_BADGE = 0x5C8E98;
const COLOR_THEME_CYAN_ETA_BG = 0x243E45;
const GLOW_RGB_CYAN = [0x00, 0x99, 0xBB];

// Turn Left / U-turn (Amber Theme)
const COLOR_THEME_AMBER_ACCENT = 0xF59E0B;
const COLOR_THEME_AMBER_BADGE = 0x9E806C;
const COLOR_THEME_AMBER_ETA_BG = 0x423226;
const GLOW_RGB_AMBER = [0xCC, 0x60, 0x05];

// Turn Right / 1st Exit (Green Theme)
const COLOR_THEME_GREEN_ACCENT = 0x10B981;
const COLOR_THEME_GREEN_BADGE = 0x5C8E74;
const COLOR_THEME_GREEN_ETA_BG = 0x243E30;
const GLOW_RGB_GREEN = [0x10, 0x90, 0x55];

class NavigationIQView extends WatchUi.View {

    private var _pageTimer as Timer.Timer?;
    private var _animTick as Number = 0;
    private var _pageIndex as Number = 0;
    private var _fontSfStreetBold as Graphics.FontDefinition?;
    private var _fontSfStreet as Graphics.FontDefinition?;
    private var _fontSfCompactBold as Graphics.FontDefinition?;
    private var _fontSfCompact as Graphics.FontDefinition?;
    private var _fontSfMicro as Graphics.FontDefinition?;

    function initialize() {
        View.initialize();
        _pageTimer = new Timer.Timer();
        try {
            _fontSfStreetBold = WatchUi.loadResource(Rez.Fonts.SfStreetBold) as Graphics.FontDefinition;
            _fontSfStreet = WatchUi.loadResource(Rez.Fonts.SfStreet) as Graphics.FontDefinition;
            _fontSfCompactBold = WatchUi.loadResource(Rez.Fonts.SfCompactBold) as Graphics.FontDefinition;
            _fontSfCompact = WatchUi.loadResource(Rez.Fonts.SfCompact) as Graphics.FontDefinition;
            _fontSfMicro = WatchUi.loadResource(Rez.Fonts.SfMicro) as Graphics.FontDefinition;
        } catch (e) {
            _fontSfStreetBold = null;
            _fontSfStreet = null;
            _fontSfCompactBold = null;
            _fontSfCompact = null;
            _fontSfMicro = null;
        }
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
        if (_animTick % 12 == 0) {
            _pageIndex++;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        CommManager.checkHapticUpdate();

        // True AMOLED Pure Black Background
        dc.setColor(COLOR_BG_AMOLED, COLOR_BG_AMOLED);
        dc.clear();

        if (!CommManager.isActive) {
            _drawIdleScreen(dc);
        } else {
            _drawUnifiedAppleHUD(dc);
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
        // Status Pill
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(40, 24, 240, 32, 16);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(40, 24, 240, 32, 16);

        dc.setColor(COLOR_THEME_GREEN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(58, 40, 4);
        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            165, 40,
            Graphics.FONT_XTINY,
            "Garmin Link: Connected",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Center Compass HUD
        var cx = 160;
        var cy = 165;
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 60);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, 60);

        var arrowPts = [
            [cx, cy - 36],
            [cx + 18, cy + 16],
            [cx, cy + 6],
            [cx - 18, cy + 16]
        ];
        dc.setColor(COLOR_THEME_CYAN_ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(arrowPts);

        // Title
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            160, 248,
            Graphics.FONT_MEDIUM,
            "Navigation IQ",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Subtitle
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        var subText = (CommManager.rxCount > 0) ? ("Packets: " + CommManager.rxCount) : "Waiting for Google Maps...";
        dc.drawText(
            160, 280,
            Graphics.FONT_XTINY,
            subText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Bottom Clock Pill
        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(110, 314, 100, 26, 13);
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            160, 327,
            Graphics.FONT_XTINY,
            timeStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // -------------------------------------------------------------------------
    // Theme Palette Selector (Bright Milky Desaturated Pastel Badge + Glow)
    // -------------------------------------------------------------------------
    private function _getTheme(dir as Number) as Array<Object> {
        if (dir == DIR_STRAIGHT || dir == DIR_ROUNDABOUT_2 || dir == DIR_ROUNDABOUT_3) {
            // Straight Ahead / 2nd-3rd Exit: Bright Milky Pastel Teal/Cyan Badge
            return [COLOR_THEME_CYAN_ACCENT, COLOR_THEME_CYAN_BADGE, GLOW_RGB_CYAN, COLOR_THEME_CYAN_ETA_BG] as Array<Object>;
        } else if (dir == DIR_LEFT || dir == DIR_SLIGHT_LEFT || dir == DIR_SHARP_LEFT ||
                   dir == DIR_ROUNDABOUT_4 || dir == DIR_ROUNDABOUT_5 || dir == DIR_UTURN) {
            // Turn Left / U-turn: Bright Milky Pastel Amber/Taupe Badge
            return [COLOR_THEME_AMBER_ACCENT, COLOR_THEME_AMBER_BADGE, GLOW_RGB_AMBER, COLOR_THEME_AMBER_ETA_BG] as Array<Object>;
        } else if (dir == DIR_RIGHT || dir == DIR_SLIGHT_RIGHT || dir == DIR_SHARP_RIGHT ||
                   dir == DIR_ROUNDABOUT_1) {
            // Turn Right / 1st Exit: Bright Milky Pastel Jade/Sage Badge
            return [COLOR_THEME_GREEN_ACCENT, COLOR_THEME_GREEN_BADGE, GLOW_RGB_GREEN, COLOR_THEME_GREEN_ETA_BG] as Array<Object>;
        } else {
            // Default Cyan Theme
            return [COLOR_THEME_CYAN_ACCENT, COLOR_THEME_CYAN_BADGE, GLOW_RGB_CYAN, COLOR_THEME_CYAN_ETA_BG] as Array<Object>;
        }
    }

    // -------------------------------------------------------------------------
    // Ultra-Smooth 70-Step RGB Concentric Ambient Glow Renderer (No Banding)
    // -------------------------------------------------------------------------
    private function _drawAmbientGlow(dc as Dc, cx as Number, cy as Number, srcRGB as Array<Number>) as Void {
        var bgR = 0x18;
        var bgG = 0x18;
        var bgB = 0x1B;
        var srcR = srcRGB[0];
        var srcG = srcRGB[1];
        var srcB = srcRGB[2];

        // 70 fine concentric steps (radius step 2px for butter-smooth gradient)
        for (var step = GLOW_STEPS; step >= 1; step--) {
            var r = (step * GLOW_RADIUS_FACTOR).toNumber();
            var t = (1.0 - (step.toFloat() / GLOW_STEPS.toFloat()));
            var factor = t * t * 0.95; // Quadratic ease-out

            var curR = (bgR + (srcR - bgR) * factor).toNumber();
            var curG = (bgG + (srcG - bgG) * factor).toNumber();
            var curB = (bgB + (srcB - bgB) * factor).toNumber();
            var col = (curR << 16) | (curG << 8) | curB;

            dc.setColor(col, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, r);
        }
    }

    // -------------------------------------------------------------------------
    // Mask Card Outer Corners to Pure AMOLED Black
    // -------------------------------------------------------------------------
    private function _maskCardCorners(dc as Dc, x as Number, y as Number, w as Number, h as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var r2 = (r * r).toFloat();
        for (var i = 0; i < r; i++) {
            var dy = (r - i).toFloat();
            var dx = (r - Math.sqrt(r2 - (dy * dy))).toNumber();
            if (dx > 0) {
                // Top-Left corner mask
                dc.drawLine(x, y + i, x + dx, y + i);
                // Top-Right corner mask
                dc.drawLine(x + w - 1 - dx, y + i, x + w - 1, y + i);
                // Bottom-Left corner mask
                dc.drawLine(x, y + h - 1 - i, x + dx, y + h - 1 - i);
                // Bottom-Right corner mask
                dc.drawLine(x + w - 1 - dx, y + h - 1 - i, x + w - 1, y + h - 1 - i);
            }
        }
    }

    // -------------------------------------------------------------------------
    // Razor-Sharp 7-Segment Digital Typography Engine (Uniform Grid)
    // -------------------------------------------------------------------------
    private function _drawMicroText(dc as Dc, targetX as Number, centerY as Number, text as String, color as Number, isCentered as Boolean) as Void {
        var digitW = 7;
        var digitH = 12;
        var midY = 6;
        var spacing = 3;
        var colonW = 3;
        var spaceW = 4;

        var totalW = 0;
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i + 1);
            if (ch.equals(":")) {
                totalW += colonW + spacing;
            } else if (ch.equals(" ")) {
                totalW += spaceW + spacing;
            } else {
                totalW += digitW + spacing;
            }
        }
        if (totalW > 0) {
            totalW -= spacing;
        }

        var startX = isCentered ? (targetX - (totalW / 2)) : (targetX - totalW);
        var topY = centerY - (digitH / 2);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        var curX = startX;
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i + 1);
            var x = curX;
            var y = topY;
            var w = digitW;
            var h = digitH;

            if (ch.equals(":")) {
                dc.fillCircle(x + 1, y + 3, 1);
                dc.fillCircle(x + 1, y + 8, 1);
                curX += colonW + spacing;
                continue;
            } else if (ch.equals(" ")) {
                curX += spaceW + spacing;
                continue;
            } else if (ch.equals("-")) {
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                curX += w + spacing;
                continue;
            } else if (ch.equals("E") || ch.equals("e")) {
                // Segments: a, f, e, g, d
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
                curX += w + spacing;
                continue;
            } else if (ch.equals("T") || ch.equals("t")) {
                // Segment a + centered vertical bar
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + (w / 2), y, x + (w / 2), y + h - 1);
                curX += w + spacing;
                continue;
            } else if (ch.equals("A") || ch.equals("a")) {
                // Segments: a, f, e, b, c, g (8 without bottom bar)
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                curX += w + spacing;
                continue;
            }

            var d = ch.toNumber();
            if (d == 0) {
                // Segments: a, b, c, d, e, f
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
                dc.drawLine(x, y, x, y + h - 1);
            } else if (d == 1) {
                // Segments: b, c (Pure straight vertical bar on right side)
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
            } else if (d == 2) {
                // Segments: a, b, g, e, d
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + w - 1, y, x + w - 1, y + midY);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + midY, x, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 3) {
                // Segments: a, b, c, d, g
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 4) {
                // Segments: f, g, b, c
                dc.drawLine(x, y, x, y + midY);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
            } else if (d == 5) {
                // Segments: a, f, g, c, d
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + midY);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x + w - 1, y + midY, x + w - 1, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 6) {
                // Segments: a, f, e, d, c, g
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x + w - 1, y + midY, x + w - 1, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 7) {
                // Segments: a, b, c
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
            } else if (d == 8) {
                // Segments: a, b, c, d, e, f, g (All segments)
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 9) {
                // Segments: a, b, c, d, f, g
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + midY);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            }
            curX += w + spacing;
        }
    }

    // -------------------------------------------------------------------------
    // Unified Apple Watch Style Aero HUD with Ambient Glow Gradient
    // -------------------------------------------------------------------------
    private function _drawUnifiedAppleHUD(dc as Dc) as Void {
        var theme = _getTheme(CommManager.direction);
        var accentColor = theme[0] as Number;
        var badgeBgColor = theme[1] as Number;
        var glowRGB = theme[2] as Array<Number>;
        var etaBgColor = theme[3] as Number;

        // 1. Draw Base Dark Card (Charcoal/Graphite)
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, CARD_Y, CARD_W, CARD_H, CARD_RADIUS);

        // 2. Draw Multi-Layered Ambient Glow Gradient blooming from Top-Left
        var badgeCx = CARD_X + BADGE_OFFSET_X;
        var badgeCy = CARD_Y + BADGE_OFFSET_Y;

        if (dc has :setClip) {
            dc.setClip(CARD_X, CARD_Y, CARD_W, CARD_H);
        }

        _drawAmbientGlow(dc, badgeCx, badgeCy, glowRGB);

        if (dc has :clearClip) {
            dc.clearClip();
        }

        // 3. Clear outer corner leak to maintain perfect round curves
        _maskCardCorners(dc, CARD_X, CARD_Y, CARD_W, CARD_H, CARD_RADIUS);

        // 4. Left Circular Turn Badge (Solid bright milky pastel theme badge, NO outline border)
        dc.setColor(badgeBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(badgeCx, badgeCy, BADGE_RADIUS);

        // Draw Real Google Maps RLE Bitmap, Vector Arrow or Spinner inside Badge
        if (CommManager.isWaitingImage) {
            _drawLoadingSpinner(dc, badgeCx, badgeCy, BADGE_RADIUS, accentColor);
        } else if (CommManager.rleBitmap != null && CommManager.rleBitmap.size() > 2) {
            _drawRleBitmap(dc, badgeCx, badgeCy, CommManager.rleBitmap);
        } else if (CommManager.direction != DIR_UNKNOWN) {
            _drawVectorArrow(dc, badgeCx, badgeCy, CommManager.direction, CommManager.exitNumber, accentColor);
        } else {
            _drawLoadingSpinner(dc, badgeCx, badgeCy, BADGE_RADIUS, accentColor);
        }

        // 5. Distance Row on Top Right (Huge Bold Pure White + Baseline Aligned Muted Grey Unit)
        var distFull = CommManager.distText;
        if (distFull.length() > 0) {
            var parts = _splitDist(distFull);
            var distNum = parts[0];
            var distUnit = parts[1];

            var numX = CARD_X + DIST_OFFSET_X;
            var numY = badgeCy;

            var numFont = Graphics.FONT_NUMBER_HOT;
            if (distNum.length() >= 3 || distUnit.length() >= 2) {
                numFont = Graphics.FONT_NUMBER_MILD;
            }

            // Bold Pure White Distance Number
            dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                numX, numY,
                numFont,
                distNum,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
            );

            // Sleek Muted Grey Unit (km / m) perfectly aligned to baseline
            var numWidth = dc.getTextWidthInPixels(distNum, numFont);
            if (distUnit.length() > 0) {
                dc.setColor(COLOR_TEXT_UNIT, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    numX + numWidth + DIST_UNIT_GAP,
                    badgeCy,
                    Graphics.FONT_MEDIUM,
                    distUnit,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }

        // 6. Subtle Horizontal Divider Line
        var divY = CARD_Y + DIVIDER_OFFSET_Y;
        dc.setColor(COLOR_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(CARD_X + DIVIDER_PADDING_X, divY, CARD_X + CARD_W - DIVIDER_PADDING_X, divY);

        // 7. Bottom Row of Main Card: Instruction & Street Name
        var streetText = CommManager.navText;
        if (streetText.length() > 0) {
            _drawDynamicWrappedText(dc, CARD_X + NAV_TEXT_PADDING_X, divY + NAV_TEXT_OFFSET_Y, CARD_W - (NAV_TEXT_PADDING_X * 2), CARD_H - (divY - CARD_Y) - NAV_TEXT_BOTTOM_PADDING, streetText, accentColor);
        }

        // ---------------------------------------------------------------------
        // 8. Bottom Pill Bar: Tinted ETA Capsule + Dot + Current Time (Y: 286 to 338)
        // ---------------------------------------------------------------------
        dc.setColor(COLOR_BG_CARD, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(CARD_X, BAR_Y, CARD_W, BAR_H, BAR_RADIUS);
        dc.setColor(COLOR_BORDER_CARD, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(CARD_X, BAR_Y, CARD_W, BAR_H, BAR_RADIUS);

        // Left: Tinted ETA Outlined Pill Badge
        var etaStr = (CommManager.etaText.length() > 0) ? ("ETA " + CommManager.etaText) : "ETA --:--";
        var etaBadgeX = CARD_X + ETA_BADGE_PADDING_X;
        var etaBadgeY = BAR_Y + (BAR_H - ETA_BADGE_H) / 2;

        // Subtle tinted theme background
        dc.setColor(etaBgColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(etaBadgeX, etaBadgeY, ETA_BADGE_W, ETA_BADGE_H, ETA_BADGE_RADIUS);

        // Outlined border with theme accent
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRoundedRectangle(etaBadgeX, etaBadgeY, ETA_BADGE_W, ETA_BADGE_H, ETA_BADGE_RADIUS);

        // Crisp White SF Pro Font for ETA
        var microFont = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;
        dc.setColor(COLOR_TEXT_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            etaBadgeX + (ETA_BADGE_W / 2),
            etaBadgeY + (ETA_BADGE_H / 2),
            microFont,
            etaStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Center: Subtle Bullet Dot
        var dotX = etaBadgeX + ETA_BADGE_W + 16;
        var dotY = BAR_Y + (BAR_H / 2);
        dc.setColor(COLOR_TEXT_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(dotX, dotY, 2.5);

        // Right: Crisp White SF Pro Live Clock Time
        var clockTime = System.getClockTime();
        var timeStr = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        dc.setColor(COLOR_TEXT_SILVER, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            CARD_X + CARD_W - 18,
            dotY,
            microFont,
            timeStr,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    // -------------------------------------------------------------------------
    // Smooth Loading Spinner when waiting for new maneuver (Bold 6px, No Center Dot)
    // -------------------------------------------------------------------------
    private function _drawLoadingSpinner(dc as Dc, cx as Number, cy as Number, radius as Number, accent as Number) as Void {
        var startDeg = (_animTick * 25) % 360;
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(BADGE_SPINNER_PEN_WIDTH);
        if (dc has :drawArc) {
            dc.drawArc(cx, cy, radius - 10, Graphics.ARC_CLOCKWISE, startDeg, (startDeg + 110) % 360);
        } else {
            dc.drawCircle(cx, cy, radius - 10);
        }
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
    // Optional Instruction Simplifier (For future user settings toggle)
    // -------------------------------------------------------------------------
    private function _simplifyInstructionText(text as String) as String {
        // Reserved for future user preferences (e.g. optional preposition stripping)
        return text;
    }

    // -------------------------------------------------------------------------
    // Intelligent Navigation Instruction Splitter (Preserves 100% Text Intact)
    // Extracts exact Action Phrase for Bold typography; keeps all remaining words Regular.
    // -------------------------------------------------------------------------
    private function _splitActionAndStreet(text as String) as Array<String> {
        // 1. Check for manual newline
        var nlIdx = text.find("\n");
        if (nlIdx != null && nlIdx > 0) {
            var act = text.substring(0, nlIdx);
            var str = text.substring(nlIdx + 1, text.length());
            return [act, str] as Array<String>;
        }

        // 2. Roundabout Pattern with leading location (e.g. "At Ngã sáu..., take the 2nd exit onto...")
        var takeIdx = text.find("take the ");
        if (takeIdx == null) {
            takeIdx = text.find("Take the ");
        }
        if (takeIdx != null && takeIdx > 0) {
            var prefix = text.substring(0, takeIdx);
            var afterTake = text.substring(takeIdx, text.length());
            var exitOntoIdx = afterTake.find(" onto ");
            var actStr = afterTake;
            var suffix = "";
            if (exitOntoIdx != null) {
                actStr = afterTake.substring(0, exitOntoIdx);
                suffix = afterTake.substring(exitOntoIdx + 1, afterTake.length());
            }
            var fullRemaining = prefix;
            if (suffix.length() > 0) {
                fullRemaining = (prefix.length() > 0) ? (prefix + suffix) : suffix;
            }
            return [actStr, fullRemaining] as Array<String>;
        }

        // 3. Known Action Verb Prefixes (Priority order: longest phrases first)
        var actionPrefixes = [
            "Turn sharp right",
            "Turn sharp left",
            "Turn slight right",
            "Turn slight left",
            "Slight right",
            "Slight left",
            "Sharp right",
            "Sharp left",
            "Turn right",
            "Turn left",
            "Keep right",
            "Keep left",
            "Make a U-turn",
            "Head northeast",
            "Head northwest",
            "Head southeast",
            "Head southwest",
            "Head north",
            "Head south",
            "Head east",
            "Head west",
            "Take the",
            "Continue onto",
            "Continue straight",
            "Continue",
            "Đi chếch sang phải",
            "Đi chếch sang trái",
            "Rẽ ngoặt sang phải",
            "Rẽ ngoặt sang trái",
            "Rẽ phải",
            "Rẽ trái",
            "Quay đầu xe",
            "Quay đầu",
            "Đi về hướng",
            "Tiếp tục đi thẳng",
            "Đi thẳng",
            "Tiếp tục"
        ];

        for (var i = 0; i < actionPrefixes.size(); i++) {
            var pfx = actionPrefixes[i];
            var pfxLen = pfx.length();
            if (text.length() >= pfxLen) {
                var sub = text.substring(0, pfxLen);
                if (sub.equals(pfx)) {
                    var act = pfx;
                    var remaining = text.substring(pfxLen, text.length());
                    if (remaining.length() > 0 && remaining.substring(0, 1).equals(" ")) {
                        remaining = remaining.substring(1, remaining.length());
                    }
                    return [act, remaining] as Array<String>;
                }
            }
        }

        return [text, ""] as Array<String>;
    }

    // -------------------------------------------------------------------------
    // Dynamic Font Scaling + Multi-Weight Typography (Bold Action + Regular Road)
    // -------------------------------------------------------------------------
    private function _drawDynamicWrappedText(dc as Dc, startX as Number, startY as Number, maxWidth as Number, maxHeight as Number, text as String, accentColor as Number) as Void {
        var parts = _splitActionAndStreet(text);
        var actionText = parts[0];
        var streetText = parts[1];

        var fontActionBold = (_fontSfStreetBold != null) ? _fontSfStreetBold : Graphics.FONT_SMALL;
        var fontStreetReg = (_fontSfStreet != null) ? _fontSfStreet : Graphics.FONT_TINY;
        var fontCompactBold = (_fontSfCompactBold != null) ? _fontSfCompactBold : Graphics.FONT_TINY;
        var fontCompactReg = (_fontSfCompact != null) ? _fontSfCompact : Graphics.FONT_XTINY;
        var fontMicro = (_fontSfMicro != null) ? _fontSfMicro : Graphics.FONT_XTINY;

        // If single action phrase with no target road
        if (streetText.length() == 0) {
            var linesStreet = _wrapWithFont(dc, actionText, fontActionBold, maxWidth);
            var fontHStreet = dc.getFontHeight(fontActionBold);
            if (linesStreet.size() <= 2 && (linesStreet.size() * (fontHStreet + 2)) <= maxHeight) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                _renderLines(dc, linesStreet, fontActionBold, startX, startY, maxHeight, fontHStreet + 2);
                return;
            }

            var linesCompact = _wrapWithFont(dc, actionText, fontCompactBold, maxWidth);
            var fontHCompact = dc.getFontHeight(fontCompactBold);
            if (linesCompact.size() <= 3 && (linesCompact.size() * (fontHCompact + 2)) <= maxHeight) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                _renderLines(dc, linesCompact, fontCompactBold, startX, startY, maxHeight, fontHCompact + 2);
                return;
            }

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var linesMicro = _wrapWithFont(dc, actionText, fontMicro, maxWidth);
            var fontHMicro = dc.getFontHeight(fontMicro);
            _renderLines(dc, linesMicro, fontMicro, startX, startY, maxHeight, fontHMicro + 2);
            return;
        }

        // 1. Try Standard Weight Hierarchy (Action Bold 24px + Street Regular 22px)
        var linesAct = _wrapWithFont(dc, actionText, fontActionBold, maxWidth);
        var linesStr = _wrapWithFont(dc, streetText, fontStreetReg, maxWidth);
        var hAct = dc.getFontHeight(fontActionBold) + 2;
        var hStr = dc.getFontHeight(fontStreetReg) + 2;
        var totalH = (linesAct.size() * hAct) + (linesStr.size() * hStr);

        if (totalH <= maxHeight) {
            var curY = startY + (maxHeight - totalH) / 2;
            // Primary Action in Bold Pure White
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < linesAct.size(); i++) {
                dc.drawText(startX, curY + (hAct / 2), fontActionBold, linesAct[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                curY += hAct;
            }
            // Target Road in Regular Soft Off-White
            dc.setColor(0xE4E4E7, Graphics.COLOR_TRANSPARENT);
            for (var j = 0; j < linesStr.size(); j++) {
                dc.drawText(startX, curY + (hStr / 2), fontStreetReg, linesStr[j], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                curY += hStr;
            }
            return;
        }

        // 2. Try Compact Weight Hierarchy (Action Bold 20px + Street Regular 18px)
        linesAct = _wrapWithFont(dc, actionText, fontCompactBold, maxWidth);
        linesStr = _wrapWithFont(dc, streetText, fontCompactReg, maxWidth);
        hAct = dc.getFontHeight(fontCompactBold) + 2;
        hStr = dc.getFontHeight(fontCompactReg) + 2;
        totalH = (linesAct.size() * hAct) + (linesStr.size() * hStr);

        if (totalH <= maxHeight) {
            var curY = startY + (maxHeight - totalH) / 2;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            for (var i = 0; i < linesAct.size(); i++) {
                dc.drawText(startX, curY + (hAct / 2), fontCompactBold, linesAct[i], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                curY += hAct;
            }
            dc.setColor(0xE4E4E7, Graphics.COLOR_TRANSPARENT);
            for (var j = 0; j < linesStr.size(); j++) {
                dc.drawText(startX, curY + (hStr / 2), fontCompactReg, linesStr[j], Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
                curY += hStr;
            }
            return;
        }

        // 3. Fallback to Micro font with smooth vertical auto-scroll
        var fullText = actionText + "\n" + streetText;
        var linesMicro = _wrapWithFont(dc, fullText, fontMicro, maxWidth);
        var fontHMicro = dc.getFontHeight(fontMicro);
        var lineH = fontHMicro + 2;
        var totalLines = linesMicro.size();
        totalH = totalLines * lineH;

        if (totalH <= maxHeight) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            _renderLines(dc, linesMicro, fontMicro, startX, startY, maxHeight, lineH);
        } else {
            // Smooth Vertical Auto-Scroll with Pause at top and bottom
            if (dc has :setClip) {
                dc.setClip(startX - 2, startY, maxWidth + 4, maxHeight);
            }

            var overflow = totalH - maxHeight + 10;
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

            var renderY = startY + 4 - scrollOffset;
            for (var j = 0; j < totalLines; j++) {
                dc.drawText(startX, renderY + (j * lineH), fontMicro, linesMicro[j], Graphics.TEXT_JUSTIFY_LEFT);
            }

            if (dc has :clearClip) {
                dc.clearClip();
            }

            // Subtle vertical scrollbar indicator on the right edge
            var barX = startX + maxWidth - 3;
            var barTrackH = maxHeight - 16;
            var thumbH = (maxHeight.toFloat() / totalH.toFloat() * barTrackH).toNumber();
            if (thumbH < 10) {
                thumbH = 10;
            }
            var thumbY = startY + 8 + ((scrollOffset.toFloat() / overflow.toFloat()) * (barTrackH - thumbH)).toNumber();
            dc.setColor(0x27272A, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(barX, startY + 8, 2, barTrackH, 1);
            dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
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
    // High-Precision Vector Turn Arrow Engine
    // -------------------------------------------------------------------------
    private function _drawVectorArrow(dc as Dc, cx as Number, cy as Number, dir as Number, exitNum as Number, arrowAccent as Number) as Void {
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);

        // --- ROUNDABOUT WITH EXACT ANGLES ---
        if (dir >= DIR_ROUNDABOUT_1 && dir <= DIR_ROUNDABOUT_5) {
            dc.setPenWidth(5);
            dc.setColor(0x52525B, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(cx, cy - 2, 14);

            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(7);
            dc.drawLine(cx - 7, cy + 18, cx - 7, cy + 9);

            if (dir == DIR_ROUNDABOUT_1) {
                dc.drawLine(cx + 7, cy - 7, cx + 17, cy - 17);
                var head = [
                    [cx + 7, cy - 19],
                    [cx + 23, cy - 23],
                    [cx + 19, cy - 7]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_2) {
                dc.drawLine(cx + 11, cy - 2, cx + 19, cy - 2);
                var head = [
                    [cx + 17, cy - 10],
                    [cx + 27, cy - 2],
                    [cx + 17, cy + 6]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_3) {
                dc.drawLine(cx, cy - 13, cx, cy - 21);
                var head = [
                    [cx - 8, cy - 19],
                    [cx, cy - 29],
                    [cx + 8, cy - 19]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_4) {
                dc.drawLine(cx - 11, cy - 2, cx - 19, cy - 2);
                var head = [
                    [cx - 17, cy - 10],
                    [cx - 27, cy - 2],
                    [cx - 17, cy + 6]
                ];
                dc.fillPolygon(head);
            } else {
                dc.drawLine(cx - 7, cy + 6, cx - 17, cy + 16);
                var head = [
                    [cx - 19, cy + 8],
                    [cx - 23, cy + 23],
                    [cx - 8, cy + 19]
                ];
                dc.fillPolygon(head);
            }
            return;
        }

        // --- STANDARD MANEUVER ARROWS ---
        if (dir == DIR_LEFT || dir == DIR_SHARP_LEFT) {
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
            // Straight Ahead
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
