import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

// =============================================================================
// TEXT & TYPOGRAPHY RENDERING ENGINE
// =============================================================================

class TextRenderer {

    // -------------------------------------------------------------------------
    // Replace All Substrings Helper
    // -------------------------------------------------------------------------
    public static function replaceAll(orig as String, search as String, rep as String) as String {
        var idx = orig.find(search);
        if (idx == null) {
            return orig;
        }
        var searchLen = search.length();
        var result = "";
        var current = orig;
        while (idx != null) {
            result += current.substring(0, idx) + rep;
            current = current.substring(idx + searchLen, current.length());
            idx = current.find(search);
        }
        result += current;
        return result;
    }

    // -------------------------------------------------------------------------
    // Strip Vietnamese Accents Helper (Full Unicode to ASCII standard)
    // -------------------------------------------------------------------------
    public static function hasNonAscii(str as String) as Boolean {
        var chars = str.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            if (chars[i].toNumber() > 127) {
                return true;
            }
        }
        return false;
    }

    public static function stripAccents(str as String) as String {
        if (str.length() == 0 || !hasNonAscii(str)) {
            return str;
        }

        var accents = [
            "á", "à", "ả", "ã", "ạ", "ă", "ắ", "ằ", "ẳ", "ẵ", "ặ", "â", "ấ", "ầ", "ẩ", "ẫ", "ậ",
            "Á", "À", "Ả", "Ã", "Ạ", "Ă", "Ắ", "Ằ", "Ẳ", "Ẵ", "Ặ", "Â", "Ấ", "Ầ", "Ẩ", "Ẫ", "Ậ",
            "đ", "Đ", "é", "è", "ẻ", "ẽ", "ẹ", "ê", "ế", "ề", "ể", "ễ", "ệ", "É", "È", "Ẻ", "Ẽ",
            "Ẹ", "Ê", "Ế", "Ề", "Ể", "Ễ", "Ệ", "í", "ì", "ỉ", "ĩ", "ị", "Í", "Ì", "Ỉ", "Ĩ", "Ị",
            "ó", "ò", "ỏ", "õ", "ọ", "ô", "ố", "ồ", "ổ", "ỗ", "ộ", "ơ", "ớ", "ờ", "ở", "ỡ", "ợ",
            "Ó", "Ò", "Ỏ", "Õ", "Ọ", "Ô", "Ố", "Ồ", "Ổ", "Ỗ", "Ộ", "Ơ", "Ớ", "Ờ", "Ở", "Ỡ", "Ợ",
            "ú", "ù", "ủ", "ũ", "ụ", "ư", "ứ", "ừ", "ử", "ữ", "ự", "Ú", "Ù", "Ủ", "Ũ", "Ụ", "Ư",
            "Ứ", "Ừ", "Ử", "Ữ", "Ự", "ý", "ỳ", "ỷ", "ỹ", "ỵ", "Ý", "Ỳ", "Ỷ", "Ỹ", "Ỵ"
        ];
        var baseChars = [
            "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a", "a",
            "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A", "A",
            "d", "D", "e", "e", "e", "e", "e", "e", "e", "e", "e", "e", "e", "E", "E", "E", "E",
            "E", "E", "E", "E", "E", "E", "E", "i", "i", "i", "i", "i", "I", "I", "I", "I", "I",
            "o", "o", "o", "o", "o", "o", "o", "o", "o", "o", "o", "o", "o", "o", "o", "o", "o",
            "O", "O", "O", "O", "O", "O", "O", "O", "O", "O", "O", "O", "O", "O", "O", "O", "O",
            "u", "u", "u", "u", "u", "u", "u", "u", "u", "u", "u", "U", "U", "U", "U", "U", "U",
            "U", "U", "U", "U", "U", "y", "y", "y", "y", "y", "Y", "Y", "Y", "Y", "Y"
        ];

        var res = str;
        for (var i = 0; i < accents.size(); i++) {
            var src = accents[i];
            if (res.find(src) != null) {
                res = replaceAll(res, src, baseChars[i]);
            }
        }
        return res;
    }

    // -------------------------------------------------------------------------
    // Capitalize First Character Helper (Full ASCII & 100% Vietnamese Accents)
    // -------------------------------------------------------------------------
    public static function capitalize(str as String) as String {
        if (str.length() == 0) {
            return str;
        }
        var chars = str.toCharArray();
        var code = chars[0].toNumber();
        var rest = str.substring(1, str.length());

        // 1. Standard Latin 'a'..'z' -> 'A'..'Z'
        if (code >= 97 && code <= 122) {
            var upperChar = (code - 32).toChar();
            return upperChar.toString() + rest;
        }

        // 2. Full Vietnamese Unicode Accented Characters Mapping
        var lowerVn = "aáàảãạăắằẳẵặâấầẩẫậeéèẻẽẹêếềểễệiíìỉĩịoóòỏõọôốồổỗộơớờởỡợuúùủũụưứừửữựyýỳỷỹỵđ";
        var upperVn = "AÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬEÉÈẺẼẸÊẾỀỂỄỆIÍÌỈĨỊOÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢUÚÙỦŨỤƯỨỪỬỮỰYÝỲỶỸỴĐ";
        var firstChar = str.substring(0, 1);
        var idx = lowerVn.find(firstChar);
        if (idx != null && idx >= 0) {
            return upperVn.substring(idx, idx + 1) + rest;
        }

        return str;
    }

    // -------------------------------------------------------------------------
    // Split Distance string into [Number, Unit] safely (Supports m, km, mi, ft)
    // -------------------------------------------------------------------------
    public static function splitDist(distStr as String, isSfNumberActive as Boolean) as Array<String> {
        var num = "";
        var unit = "";
        var hitSpace = false;
        var chars = distStr.toCharArray();

        for (var i = 0; i < chars.size(); i++) {
            var c = chars[i];
            var code = c.toNumber();

            // Treat standard space (32), non-breaking space (160), narrow NBSP (8239), tab (9), newline (10/13) as spaces
            var isSpace = (code == 32 || code == 160 || code == 8239 || code == 9 || code == 10 || code == 13);
            if (isSpace) {
                if (num.length() > 0) {
                    hitSpace = true;
                }
                continue;
            }

            // Digits 0-9, dot (46), comma (44)
            var isDigit = ((code >= 48 && code <= 57) || code == 46 || code == 44);

            if (isDigit && !hitSpace) {
                num = num + c.toString();
            } else {
                hitSpace = true;
                unit = unit + c.toString();
            }
        }

        unit = trim(unit);

        if (num.length() == 0 && unit.length() > 0) {
            num = unit;
            unit = "";
        }

        // When using Garmin system number font, Garmin FONT_NUMBER_* drops comma ','
        // Normalize ',' to '.' so decimal separator is never lost on Garmin font
        if (!isSfNumberActive) {
            var commaIdx = num.find(",");
            if (commaIdx != null) {
                num = num.substring(0, commaIdx) + "." + num.substring(commaIdx + 1, num.length());
            }
        }

        return [num, unit] as Array<String>;
    }

    public static function hasAlpha(str as String) as Boolean {
        var chars = str.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var code = chars[i].toNumber();
            if ((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) {
                return true;
            }
        }
        return false;
    }

    public static function trim(str as String) as String {
        var len = str.length();
        if (len == 0) {
            return str;
        }
        var start = 0;
        while (start < len) {
            var code = str.substring(start, start + 1).toCharArray()[0].toNumber();
            if (code == 32 || code == 160 || code == 8239 || code == 9 || code == 10 || code == 13) {
                start++;
            } else {
                break;
            }
        }
        if (start == len) {
            return "";
        }
        var end = len;
        while (end > start) {
            var code = str.substring(end - 1, end).toCharArray()[0].toNumber();
            if (code == 32 || code == 160 || code == 8239 || code == 9 || code == 10 || code == 13) {
                end--;
            } else {
                break;
            }
        }
        return str.substring(start, end);
    }

    // -------------------------------------------------------------------------
    // Intelligent Navigation Instruction Splitter (Preserves 100% Text Intact)
    // Full English & Vietnamese Support; Capitalizes Action Phrase for Clean Typography.
    // -------------------------------------------------------------------------
    public static function splitActionAndStreet(text as String) as Array<String> {
        // 1. Check for manual newline
        var nlIdx = text.find("\n");
        if (nlIdx != null && nlIdx > 0) {
            var act = capitalize(text.substring(0, nlIdx));
            var str = text.substring(nlIdx + 1, text.length());
            return [act, str] as Array<String>;
        }

        // 2. English Roundabout Pattern: "At ..., take the Nth exit onto ..."
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
            return [capitalize(actStr), fullRemaining] as Array<String>;
        }

        // 3. Vietnamese Roundabout Pattern: "Tại bùng binh/vòng xoay, đi theo lối ra thứ N..."
        var roundVnIdx = text.find("Tại bùng binh,");
        if (roundVnIdx == null) {
            roundVnIdx = text.find("Tại vòng xoay,");
        }
        if (roundVnIdx == null) {
            roundVnIdx = text.find("Tại bùng binh");
        }
        if (roundVnIdx == null) {
            roundVnIdx = text.find("Tại vòng xoay");
        }
        if (roundVnIdx != null) {
            var commaPos = text.find(",");
            if (commaPos != null && commaPos + 1 < text.length()) {
                var pfx = trim(text.substring(0, commaPos));
                var afterComma = trim(text.substring(commaPos + 1, text.length()));
                var vaoIdx = afterComma.find(" vào ");
                if (vaoIdx != null) {
                    var actPart = trim(afterComma.substring(0, vaoIdx));
                    var roadPart = trim(afterComma.substring(vaoIdx + 1, afterComma.length()));
                    var finalRoad = pfx + ", " + roadPart;
                    return [capitalize(actPart), finalRoad] as Array<String>;
                } else {
                    return [capitalize(afterComma), pfx] as Array<String>;
                }
            }
        }

        // 4. Common Action Prefixes
        var actionPrefixes = [
            "Turn slight right onto",
            "Turn slight right",
            "Turn slight left onto",
            "Turn slight left",
            "Turn sharp right onto",
            "Turn sharp right",
            "Turn sharp left onto",
            "Turn sharp left",
            "Turn right onto",
            "Turn right",
            "Turn left onto",
            "Turn left",
            "Keep right onto",
            "Keep right",
            "Keep left onto",
            "Keep left",
            "Make a U-turn",
            "Take the exit",
            "Take exit",
            "Head northeast on",
            "Head northwest on",
            "Head southeast on",
            "Head southwest on",
            "Head north on",
            "Head south on",
            "Head east on",
            "Head west on",
            "Head",
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
            "Đi về hướng Đông Bắc",
            "Đi về hướng Tây Bắc",
            "Đi về hướng Đông Nam",
            "Đi về hướng Tây Nam",
            "Đi về hướng Bắc",
            "Đi về hướng Nam",
            "Đi về hướng Đông",
            "Đi về hướng Tây",
            "Đi về hướng",
            "Tiếp tục đi thẳng",
            "Đi theo lối ra",
            "Đi dọc theo",
            "Đi thẳng",
            "Nhập vào",
            "Tiếp tục",
            "Tiep tuc di thang",
            "Di chech sang phai",
            "Di chech sang trai",
            "Re ngoat sang phai",
            "Re ngoat sang trai",
            "Re phai",
            "Re trai",
            "Quay dau xe",
            "Quay dau",
            "Di ve huong",
            "Di theo loi ra",
            "Di doc theo",
            "Di thang",
            "Nhap vao",
            "Tiep tuc"
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
                    return [capitalize(act), remaining] as Array<String>;
                }
            }
        }

        return [capitalize(text), ""] as Array<String>;
    }

    // -------------------------------------------------------------------------
    // Word Tokenizer
    // -------------------------------------------------------------------------
    public static function splitWords(text as String) as Array<String> {
        var words = [] as Array<String>;
        var cur = "";
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            var ch = chars[i].toString();
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
    // Text Wrapping Helper
    // -------------------------------------------------------------------------
    public static function wrapWithFont(dc as Dc, text as String, font as Graphics.FontDefinition, maxWidth as Number) as Array<String> {
        var words = splitWords(text);
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

    // -------------------------------------------------------------------------
    // 90° Clockwise Rotated Text Wrapping & Measurement
    // -------------------------------------------------------------------------
    public static function wrapWithRot90Font(dc as Dc, text as String, fontUpright as Graphics.FontDefinition, maxWidth as Number) as Array<String> {
        return wrapWithFont(dc, text, fontUpright, maxWidth);
    }

    public static function measureRot90String(dc as Dc, fontUpright as Graphics.FontDefinition, text as String) as Number {
        return dc.getTextWidthInPixels(text, fontUpright);
    }

    public static function drawRot90String(dc as Dc, vx as Number, vy as Number, fontRot as Graphics.FontDefinition, fontUpright as Graphics.FontDefinition, text as String, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var curVy = vy;
        for (var i = 0; i < text.length(); i++) {
            var ch = text.substring(i, i + 1);
            var px = 360 - curVy - 24;
            var py = vx;
            dc.drawText(px, py, fontRot, ch, Graphics.TEXT_JUSTIFY_LEFT);
            var chAdv = dc.getTextWidthInPixels(ch, fontUpright);
            if (chAdv < 6) { chAdv = 6; }
            curVy += chAdv;
        }
    }

    // -------------------------------------------------------------------------
    // Razor-Sharp 7-Segment Digital Typography Engine (Uniform Grid)
    // -------------------------------------------------------------------------
    public static function drawMicroText(dc as Dc, targetX as Number, centerY as Number, text as String, color as Number, isCentered as Boolean) as Void {
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
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
                curX += w + spacing;
                continue;
            } else if (ch.equals("T") || ch.equals("t")) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + (w / 2), y, x + (w / 2), y + h - 1);
                curX += w + spacing;
                continue;
            } else if (ch.equals("A") || ch.equals("a")) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                curX += w + spacing;
                continue;
            }

            var d = ch.toNumber();
            if (d == null) {
                curX += w + spacing;
                continue;
            }

            if (d == 0) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 1) {
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
            } else if (d == 2) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + w - 1, y, x + w - 1, y + midY);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + midY, x, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 3) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 4) {
                dc.drawLine(x, y, x, y + midY);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
            } else if (d == 5) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + midY);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x + w - 1, y + midY, x + w - 1, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 6) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x + w - 1, y + midY, x + w - 1, y + h - 1);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 7) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
            } else if (d == 8) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + h - 1);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            } else if (d == 9) {
                dc.drawLine(x, y, x + w - 1, y);
                dc.drawLine(x, y, x, y + midY);
                dc.drawLine(x + w - 1, y, x + w - 1, y + h - 1);
                dc.drawLine(x, y + midY, x + w - 1, y + midY);
                dc.drawLine(x, y + h - 1, x + w - 1, y + h - 1);
            }
            curX += w + spacing;
        }
    }
}
