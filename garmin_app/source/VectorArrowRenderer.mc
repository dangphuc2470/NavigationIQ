import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

// =============================================================================
// VECTOR ARROW & GRAPHICS SHAPE RENDERER
// =============================================================================

class VectorArrowRenderer {

    // -------------------------------------------------------------------------
    // High-Precision Vector Turn Arrow Engine
    // -------------------------------------------------------------------------
    public static function drawVectorArrow(dc as Dc, cx as Number, cy as Number, dir as Number, exitNum as Number, arrowAccent as Number) as Void {
        cy = cy - 4;
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);

        // --- ROUNDABOUT WITH SEAMLESS CURVED ARC ---
        if (dir >= DIR_ROUNDABOUT_1 && dir <= DIR_ROUNDABOUT_5) {
            var roundR = 14;
            var roundCy = cy - 2;

            // 1. Subtle background track of the roundabout island
            dc.setPenWidth(3);
            dc.setColor(0x3F3F46, Graphics.COLOR_TRANSPARENT);
            dc.drawCircle(cx, roundCy, roundR);

            // 2. Active route path in bright pure white
            dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(6);

            // Entrance branch from bottom
            dc.drawLine(cx - 5, cy + 18, cx - 5, roundCy + 13);

            if (dir == DIR_ROUNDABOUT_1) {
                // Exit 1: Turn right (leaves at ~15° / 2 o'clock)
                if (dc has :drawArc) {
                    dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 15);
                }
                dc.drawLine(cx + 12, roundCy - 4, cx + 20, roundCy - 4);
                var head = [
                    [cx + 17, roundCy - 12],
                    [cx + 27, roundCy - 4],
                    [cx + 17, roundCy + 4]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_2) {
                // Exit 2: Straight ahead (leaves at 90° / 12 o'clock)
                if (dc has :drawArc) {
                    dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 90);
                }
                dc.drawLine(cx, roundCy - 13, cx, roundCy - 21);
                var head = [
                    [cx - 8, roundCy - 19],
                    [cx, roundCy - 29],
                    [cx + 8, roundCy - 19]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_3) {
                // Exit 3: Straight / Left (leaves at 135° or 180°)
                if (dc has :drawArc) {
                    dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 150);
                }
                dc.drawLine(cx - 9, roundCy - 9, cx - 18, roundCy - 18);
                var head = [
                    [cx - 8, roundCy - 21],
                    [cx - 24, roundCy - 24],
                    [cx - 21, roundCy - 8]
                ];
                dc.fillPolygon(head);
            } else if (dir == DIR_ROUNDABOUT_4) {
                // Exit 4: Left (leaves at 180° / 9 o'clock)
                if (dc has :drawArc) {
                    dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 195);
                }
                dc.drawLine(cx - 12, roundCy + 3, cx - 20, roundCy + 3);
                var head = [
                    [cx - 17, roundCy - 5],
                    [cx - 27, roundCy + 3],
                    [cx - 17, roundCy + 11]
                ];
                dc.fillPolygon(head);
            } else {
                // Exit 5: U-turn around roundabout (leaves at 225° / 7 o'clock)
                if (dc has :drawArc) {
                    dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 235);
                }
                dc.drawLine(cx - 9, roundCy + 9, cx - 17, roundCy + 17);
                var head = [
                    [cx - 19, roundCy + 9],
                    [cx - 23, roundCy + 23],
                    [cx - 9, roundCy + 19]
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

    // -------------------------------------------------------------------------
    // Vector Arrow 90° Clockwise Rotated Renderer
    // -------------------------------------------------------------------------
    public static function drawVectorArrowRot90(dc as Dc, cx as Number, cy as Number, dir as Number, exitNum as Number, arrowAccent as Number) as Void {
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);

        if (dir == DIR_RIGHT || dir == DIR_SHARP_RIGHT) {
            dc.setPenWidth(9);
            dc.drawLine(cx - 16, cy - 10, cx + 2, cy - 10);
            dc.drawLine(cx + 2, cy - 10, cx + 2, cy + 8);
            var head = [
                [cx - 10, cy + 8],
                [cx + 2, cy + 22],
                [cx + 14, cy + 8]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_LEFT || dir == DIR_SHARP_LEFT) {
            dc.setPenWidth(9);
            dc.drawLine(cx - 16, cy + 10, cx + 2, cy + 10);
            dc.drawLine(cx + 2, cy + 10, cx + 2, cy - 8);
            var head = [
                [cx - 10, cy - 8],
                [cx + 2, cy - 22],
                [cx + 14, cy - 8]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_SLIGHT_RIGHT) {
            dc.setPenWidth(9);
            dc.drawLine(cx - 16, cy - 6, cx - 4, cy - 6);
            dc.drawLine(cx - 4, cy - 6, cx + 8, cy + 8);
            var head = [
                [cx - 2, cy + 16],
                [cx + 16, cy + 18],
                [cx + 18, cy + 2]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_SLIGHT_LEFT) {
            dc.setPenWidth(9);
            dc.drawLine(cx - 16, cy + 6, cx - 4, cy + 6);
            dc.drawLine(cx - 4, cy + 6, cx + 8, cy - 8);
            var head = [
                [cx + 18, cy - 2],
                [cx + 16, cy - 18],
                [cx - 2, cy - 16]
            ];
            dc.fillPolygon(head);
        }
        else if (dir == DIR_UTURN) {
            dc.setPenWidth(8);
            dc.drawLine(cx - 16, cy - 10, cx + 4, cy - 10);
            dc.drawLine(cx + 4, cy - 10, cx + 4, cy + 10);
            dc.drawLine(cx + 4, cy + 10, cx - 8, cy + 10);
            var head = [
                [cx - 6, cy + 1],
                [cx - 20, cy + 10],
                [cx - 6, cy + 19]
            ];
            dc.fillPolygon(head);
        }
        else {
            // Straight Ahead
            dc.setPenWidth(9);
            dc.drawLine(cx - 16, cy, cx + 6, cy);
            var head = [
                [cx + 4, cy - 14],
                [cx + 22, cy],
                [cx + 4, cy + 14]
            ];
            dc.fillPolygon(head);
        }
    }

    // -------------------------------------------------------------------------
    // Smooth Loading Spinner when waiting for new maneuver
    // -------------------------------------------------------------------------
    public static function drawLoadingSpinner(dc as Dc, cx as Number, cy as Number, radius as Number, accent as Number, animTick as Number) as Void {
        var startDeg = (animTick * 25) % 360;
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
    public static function drawRleBitmap(dc as Dc, cx as Number, cy as Number, rleData as Array<Number>) as Void {
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
    // Ultra-Smooth 120-Step RGB Concentric Ambient Glow Renderer
    // -------------------------------------------------------------------------
    public static function drawAmbientGlow(dc as Dc, cx as Number, cy as Number, srcRGB as Array<Number>) as Void {
        var bgR = 0x18;
        var bgG = 0x18;
        var bgB = 0x1B;
        var srcR = srcRGB[0];
        var srcG = srcRGB[1];
        var srcB = srcRGB[2];

        for (var step = GLOW_STEPS; step >= 1; step--) {
            var r = (step * GLOW_RADIUS_FACTOR).toNumber();
            var t = (1.0 - (step.toFloat() / GLOW_STEPS.toFloat()));
            var factor = Math.pow(t, 2.6) * 0.98;

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
    public static function maskCardCorners(dc as Dc, x as Number, y as Number, w as Number, h as Number, r as Number) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        var r2 = (r * r).toFloat();
        for (var i = 0; i < r; i++) {
            var dy = (r - i).toFloat();
            var dx = (r - Math.sqrt(r2 - (dy * dy))).toNumber();
            if (dx > 0) {
                dc.drawLine(x, y + i, x + dx, y + i);
                dc.drawLine(x + w - 1 - dx, y + i, x + w - 1, y + i);
                dc.drawLine(x, y + h - 1 - i, x + dx, y + h - 1 - i);
                dc.drawLine(x + w - 1 - dx, y + h - 1 - i, x + w - 1, y + h - 1 - i);
            }
        }
    }
}
