import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

// =============================================================================
// VECTOR ARROW & GRAPHICS SHAPE RENDERER
// =============================================================================

class VectorArrowRenderer {

    // -------------------------------------------------------------------------
    // High-Precision Vector Turn Arrow Engine
    // -------------------------------------------------------------------------
    public static function drawVectorArrow(dc as Dc, cx as Number, cy as Number, dir as Number, exitNum as Number, arrowAccent as Number) as Void {
        dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT);

        // --- ROUNDABOUT WITH SEAMLESS CURVED ARC ---
        if (dir >= DIR_ROUNDABOUT_1 && dir <= DIR_ROUNDABOUT_5) {
            var isSmall = (dc.getWidth() <= 200);

            if (isSmall) {
                // Compact Roundabout (Instinct Crossover, radius ~24)
                // Center slightly offset (+2) so bottom entrance (cy+16) and top exit arrow (cy-14) are balanced
                var roundR = 8;
                var roundCy = cy + 2;

                // 1. Background ring (1px white line for clear visibility on 1-bit monochrome MIP)
                dc.setPenWidth(1);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(cx, roundCy, roundR);

                // 2. Active route path (4px prominent white stroke)
                dc.setPenWidth(4);

                // Entrance branch from bottom
                dc.drawLine(cx - 3, roundCy + 14, cx - 3, roundCy + 6);

                if (dir == DIR_ROUNDABOUT_1) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 15);
                    }
                    dc.drawLine(cx + 6, roundCy - 2, cx + 10, roundCy - 2);
                    var head = [
                        [cx + 9, roundCy - 6],
                        [cx + 15, roundCy - 2],
                        [cx + 9, roundCy + 2]
                    ];
                    dc.fillPolygon(head);
                } else if (dir == DIR_ROUNDABOUT_2) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 90);
                    }
                    dc.drawLine(cx, roundCy - 7, cx, roundCy - 11);
                    var head = [
                        [cx - 4, roundCy - 10],
                        [cx, roundCy - 16],
                        [cx + 4, roundCy - 10]
                    ];
                    dc.fillPolygon(head);
                } else if (dir == DIR_ROUNDABOUT_3) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 145);
                    }
                    dc.drawLine(cx - 5, roundCy - 5, cx - 9, roundCy - 9);
                    var head = [
                        [cx - 5, roundCy - 11],
                        [cx - 14, roundCy - 14],
                        [cx - 11, roundCy - 5]
                    ];
                    dc.fillPolygon(head);
                } else if (dir == DIR_ROUNDABOUT_4) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 200);
                    }
                    dc.drawLine(cx - 7, roundCy + 2, cx - 11, roundCy + 2);
                    var head = [
                        [cx - 9, roundCy - 2],
                        [cx - 15, roundCy + 2],
                        [cx - 9, roundCy + 6]
                    ];
                    dc.fillPolygon(head);
                } else {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 240);
                    }
                    dc.drawLine(cx - 5, roundCy + 5, cx - 9, roundCy + 9);
                    var head = [
                        [cx - 11, roundCy + 5],
                        [cx - 13, roundCy + 14],
                        [cx - 5, roundCy + 12]
                    ];
                    dc.fillPolygon(head);
                }
            } else {
                // Full-size Roundabout (Venu 2, Venu Sq 2, radius ~36)
                // Center slightly offset (+2) so bottom entrance (cy+21) and top exit arrow (cy-21) are perfectly balanced
                var roundR = 13;
                var roundCy = cy + 2;

                dc.setPenWidth(3);
                dc.setColor(0x3F3F46, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(cx, roundCy, roundR);

                dc.setColor(arrowAccent, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(6);

                dc.drawLine(cx - 4, roundCy + 19, cx - 4, roundCy + 10);

                if (dir == DIR_ROUNDABOUT_1) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 15);
                    }
                    dc.drawLine(cx + 9, roundCy - 3, cx + 15, roundCy - 3);
                    var head = [
                        [cx + 13, roundCy - 9],
                        [cx + 22, roundCy - 3],
                        [cx + 13, roundCy + 3]
                    ];
                    dc.fillPolygon(head);
                } else if (dir == DIR_ROUNDABOUT_2) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 90);
                    }
                    dc.drawLine(cx, roundCy - 11, cx, roundCy - 17);
                    var head = [
                        [cx - 6, roundCy - 15],
                        [cx, roundCy - 23],
                        [cx + 6, roundCy - 15]
                    ];
                    dc.fillPolygon(head);
                } else if (dir == DIR_ROUNDABOUT_3) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 150);
                    }
                    dc.drawLine(cx - 8, roundCy - 8, cx - 14, roundCy - 14);
                    var head = [
                        [cx - 8, roundCy - 17],
                        [cx - 20, roundCy - 20],
                        [cx - 17, roundCy - 8]
                    ];
                    dc.fillPolygon(head);
                } else if (dir == DIR_ROUNDABOUT_4) {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 195);
                    }
                    dc.drawLine(cx - 10, roundCy + 3, cx - 16, roundCy + 3);
                    var head = [
                        [cx - 13, roundCy - 3],
                        [cx - 22, roundCy + 3],
                        [cx - 13, roundCy + 9]
                    ];
                    dc.fillPolygon(head);
                } else {
                    if (dc has :drawArc) {
                        dc.drawArc(cx, roundCy, roundR, Graphics.ARC_COUNTER_CLOCKWISE, 250, 235);
                    }
                    dc.drawLine(cx - 7, roundCy + 7, cx - 13, roundCy + 13);
                    var head = [
                        [cx - 15, roundCy + 7],
                        [cx - 19, roundCy + 19],
                        [cx - 7, roundCy + 15]
                    ];
                    dc.fillPolygon(head);
                }
            }
            return;
        }

        cy = cy - 4;

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
    // Concentric Ambient Glow Radial Gradient (Signature App Bloom into Pure Black)
    // -------------------------------------------------------------------------
    public static function drawAmbientGlow(dc as Dc, cx as Number, cy as Number, srcRGB as Array<Number>) as Void {
        var bgR = 0x00;
        var bgG = 0x00;
        var bgB = 0x00;
        var srcR = srcRGB[0];
        var srcG = srcRGB[1];
        var srcB = srcRGB[2];

        var steps = 32;
        var w = dc.getWidth();
        var maxR = (w * 0.30).toNumber();
        if (maxR < 50) { maxR = 50; }
        if (maxR > 130) { maxR = 130; }

        for (var step = steps; step >= 1; step--) {
            var r = ((step.toFloat() / steps.toFloat()) * maxR).toNumber();
            var t = (1.0 - (step.toFloat() / steps.toFloat()));
            var factor = Math.pow(t, 2.0) * 0.90;

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
