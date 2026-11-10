import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

(:glance)
class NavigationIQGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerY = height / 2;

        // Clear glance area
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();

        // 1. Draw signature NavigationIQ Two-Tone Emerald Arrow Vector
        // Size: 26x26 bounding box
        var iconSize = 24;
        if (height >= 70) {
            iconSize = 28;
        } else if (height <= 45) {
            iconSize = 20;
        }

        var iconX = 8;
        var iconY = centerY - (iconSize / 2);
        var halfW = iconSize / 2;

        var apexX = iconX + halfW;
        var apexY = iconY + 1;
        var leftBottomX = iconX + 1;
        var leftBottomY = iconY + iconSize - 1;
        var rightBottomX = iconX + iconSize - 1;
        var rightBottomY = iconY + iconSize - 1;
        var notchX = apexX;
        var notchY = iconY + (iconSize * 0.72).toNumber();

        // Left Wing - Deep Forest Green
        dc.setColor(0x1B4332, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [apexX, apexY],
            [leftBottomX, leftBottomY],
            [notchX, notchY]
        ]);

        // Right Wing - Vivid Mint Emerald
        dc.setColor(0x10B981, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [apexX, apexY],
            [rightBottomX, rightBottomY],
            [notchX, notchY]
        ]);

        // Center Crisp White Spine Divider
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(apexX, apexY, notchX, notchY);

        // 2. Text Labels
        var textStartX = iconX + iconSize + 10;
        var textFont = Graphics.FONT_GLANCE;
        if (!(Graphics has :FONT_GLANCE)) {
            textFont = Graphics.FONT_TINY;
        }

        if (height >= 55) {
            // Two-line layout: App Name + Subtitle
            var fontH = dc.getFontHeight(textFont);
            var titleY = centerY - fontH + 2;
            var subY = centerY + 3;

            // App Name
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(textStartX, titleY, textFont, "NavigationIQ", Graphics.TEXT_JUSTIFY_LEFT);

            // Subtitle status
            var subFont = Graphics.FONT_XTINY;
            dc.setColor(0x10B981, Graphics.COLOR_TRANSPARENT);
            dc.drawText(textStartX, subY, subFont, "Ready", Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            // Compact single line layout
            var fontH = dc.getFontHeight(textFont);
            var titleY = centerY - (fontH / 2);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(textStartX, titleY, textFont, "NavigationIQ", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
}
