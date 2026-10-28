package com.phucdnh.navigationiq.parser

import android.content.Context
import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.VectorDrawable
import android.util.Log
import com.phucdnh.navigationiq.model.NavigationInfo
import java.util.regex.Pattern

/**
 * Google Maps parser extracting turn directions, icons, distance, street name and ETA.
 * Directly ported and optimized from com.navigationparser.lib.Parsing.Maps.ParserMaps.
 */
object GoogleMapsParser {
    private const val TAG = "GoogleMapsParser"
    private val ETA_PATTERN = Pattern.compile("\\b(\\d{1,2}:\\d{1,2})\\b")

    fun parse(context: Context, values: NotificationValues): NavigationInfo? {
        var info = getCarNavigationInfo(values)
        if (info == null || !info.hasDirections()) {
            info = getPublicTransportNavigationInfo(values)
        }
        return if (info != null && info.hasDirections()) info else null
    }

    private fun getCarNavigationInfo(values: NotificationValues): NavigationInfo? {
        return try {
            val info = parseCar(values) ?: return null
            info.isPublicTransport = false
            val drawable = values.drawables["android-largeIcon"]
                ?: values.drawables["android-icon"]
                ?: values.drawables["right_icon_container-right_icon"]
                ?: values.drawables["right_icon"]
                ?: values.drawables["icon"]
                ?: values.drawables["notification_main_column-right_icon"]
            info.bitmap = getBitmap(drawable)
            info
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse car navigation: ${e.message}")
            null
        }
    }

    private fun isArrivalText(text: String?): Boolean {
        if (text.isNullOrBlank()) return false
        val s = text.lowercase().trim()
        return s.contains("bạn đã đến") || s.contains("đã đến điểm đến") ||
                s.contains("đã đến nơi") || s.contains("đã tới nơi") ||
                s.contains("you have arrived") || s.contains("arrived at") ||
                s == "arrived" || s == "đã đến" || s == "đã tới" ||
                s.startsWith("arrived ·") || s.startsWith("đã đến ·") ||
                s.startsWith("arriving") || s.contains("arriving") ||
                s.contains("đang đến") || s.contains("đang tới") ||
                s.contains("bạn đang đến") || s.contains("bạn sắp đến") ||
                s.contains("sắp đến") || s.contains("sắp tới")
    }

    private fun cleanArrivalDestination(title: String, text: String, isTitleArrival: Boolean, isTextArrival: Boolean): String {
        val destPart = if (isTitleArrival && text.isNotBlank()) {
            text
        } else if (isTextArrival && title.isNotBlank()) {
            title
        } else if (!isTitleArrival && title.isNotBlank()) {
            title
        } else {
            text
        }

        var clean = destPart.trim()
        val lower = clean.lowercase()
        val prefixes = listOf(
            "bạn đang đến ", "bạn sắp đến ", "bạn đã đến ",
            "đang đến ", "đang tới ", "sắp đến ", "sắp tới ",
            "đã đến ", "đã tới ", "arriving at ", "arrived at ",
            "at ", "tại ", "đến ", "to "
        )
        for (prefix in prefixes) {
            if (lower.startsWith(prefix)) {
                clean = clean.substring(prefix.length).trim()
                break
            }
        }
        return clean.ifEmpty { if (title.isNotBlank()) title else text }
    }

    private fun isSystemNotification(title: String, text: String): Boolean {
        val t = title.lowercase().trim()
        val s = text.lowercase().trim()
        val isSystemTitle = t == "google maps" || t == "bản đồ" || t.isEmpty()
        if (isSystemTitle) {
            if (s.contains("gps") || s.contains("chia sẻ") || s.contains("vị trí") ||
                s.contains("đang tìm") || s.contains("searching") || s.contains("sharing") ||
                s.contains("đỗ xe") || s.contains("parking") || s.contains("xem trước") ||
                s.contains("preview") || s.contains("tuyến đường")) {
                return true
            }
        }
        return false
    }

    private fun isValidDistance(dist: String): Boolean {
        val d = dist.trim().lowercase()
        if (d.isEmpty()) return false
        if (d == "0 m" || d == "0 km" || d == "0") return true
        val hasDigit = d.any { it.isDigit() }
        val hasUnit = d.contains("m") || d.contains("km") || d.contains("ft") || d.contains("mi") || d.contains("yd")
        return hasDigit && (hasUnit || d.length <= 10)
    }

    private fun parseCar(values: NotificationValues): NavigationInfo? {
        val info = NavigationInfo()
        val title = values.texts["android-title"] ?: ""
        val text = values.texts["android-text"] ?: ""
        val subText = values.texts["android-subText"]

        // 0. Filter out non-navigation system notifications (e.g. Searching for GPS, sharing location)
        if (isSystemNotification(title, text)) {
            return null
        }

        // 1. Priority: check if notification indicates destination arrival
        val isTitleArrival = isArrivalText(title)
        val isTextArrival = isArrivalText(text)
        if (isTitleArrival || isTextArrival) {
            info.isPublicTransport = false
            info.isArrivedState = true
            info.signs = cleanArrivalDestination(title, text, isTitleArrival, isTextArrival)
            info.distance = "0 m"
            if (!subText.isNullOrEmpty()) {
                parseEtaLengthDuration(subText, info)
            }
            applyProgressInfo(values, info)
            return info
        }

        if (title.isNotEmpty() && subText != null) {
            parseDistanceSigns(title, info)
            parseEtaLengthDuration(subText, info)
            applyProgressInfo(values, info)
            return info
        }

        val mainColumnTitle = getMainColumnTitle(values)
        val mainColumnText = values.texts["notification_main_column-text"]
        if (mainColumnTitle != null && mainColumnText != null && subText != null) {
            if (mainColumnText.isNotEmpty()) {
                info.distance = mainColumnTitle
                info.signs = mainColumnText
                parseEtaLengthDuration(subText, info)
                applyProgressInfo(values, info)
                return info
            }
            parseDistanceSigns(mainColumnTitle, info)
            info.eta = parseEtaOnly(subText)
            applyProgressInfo(values, info)
            return info
        }

        if (text.isNotEmpty()) {
            if (info.signs.isEmpty()) info.signs = text
            if (info.distance.isEmpty() && isValidDistance(title)) {
                info.distance = title
            }
            if (!subText.isNullOrEmpty()) parseEtaLengthDuration(subText, info)
            applyProgressInfo(values, info)
            if (info.distance.isNotEmpty() && isValidDistance(info.distance)) {
                return info
            }
            return null
        }

        return null
    }

    private fun applyProgressInfo(values: NotificationValues, info: NavigationInfo) {
        val maxStr = values.texts["android-progressMax"]
        val curStr = values.texts["android-progress"]
        val maxMeters = maxStr?.toIntOrNull()
        if (maxMeters != null && maxMeters > 0) {
            if (info.length.isEmpty() || info.length == "-") {
                info.length = if (maxMeters >= 1000) {
                    String.format(java.util.Locale.US, "%.1f km", maxMeters / 1000.0)
                } else {
                    "$maxMeters m"
                }
            }
            if (info.units.isEmpty()) {
                info.units = "km/h"
            }
        }
    }

    private fun parsePublicTransport(values: NotificationValues): NavigationInfo {
        val info = NavigationInfo().apply {
            isPublicTransport = true
            eta = getEta(values)
            if (eta.isNotEmpty()) {
                signs = getSigns(values).ifEmpty { getSigns2(values) }
                distance = trim(getDistance(values)).ifEmpty { getDistance2(values) }
                duration = getDuration(values)
                length = "-"
            }
        }
        return info
    }

    private fun getPublicTransportNavigationInfo(values: NotificationValues): NavigationInfo? {
        return try {
            val info = parsePublicTransport(values)
            val iconDrawable = values.drawables["icon"]
            info.bitmap = getBitmap(iconDrawable)
            info
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse public transport: ${e.message}")
            null
        }
    }

    private fun getMainColumnTitle(values: NotificationValues): String? {
        for ((key, value) in values.texts) {
            if (key.contains("notification_main_column") && key.contains("title")) {
                return value
            }
        }
        return null
    }

    private fun parseDistanceSigns(rawTitle: String, info: NavigationInfo) {
        val split = rawTitle.split(" · ", " • ", " – ", " - ", " – ", " - ", " – ", " - ")
        if (split.size >= 2) {
            info.distance = split[0].trim()
            info.signs = split[1].trim()
        } else if (split.size == 1) {
            info.signs = split[0].trim()
        }
    }

    private fun parseEtaLengthDuration(rawSubText: String, info: NavigationInfo) {
        val split = rawSubText.split(" · ", " • ", " – ", " - ", " – ", " - ", " – ", " - ")
        if (split.size >= 3) {
            info.duration = split[0].trim()
            info.length = split[1].trim()
            info.units = parseUnits(info.length)
            info.eta = parseEta(split[2].trim())
        } else if (split.size == 2) {
            for (part in split) {
                val p = part.trim()
                if (p.contains(":") && info.eta.isEmpty()) {
                    info.eta = parseEta(p)
                } else if ((p.contains("km") || p.contains("m") || p.contains("mi")) && info.length.isEmpty()) {
                    info.length = p
                    info.units = parseUnits(p)
                } else if (info.duration.isEmpty()) {
                    info.duration = p
                }
            }
        } else if (split.isNotEmpty()) {
            info.eta = parseEtaOnly(rawSubText)
        }
    }

    fun parseEtaOnly(str: String): String {
        val matcher = ETA_PATTERN.matcher(str)
        return if (matcher.find()) matcher.group(1) ?: "" else ""
    }

    fun parseUnits(lengthStr: String): String {
        if (lengthStr.isEmpty()) return "km/h"
        val lastChar = lengthStr.last()
        return when (lastChar) {
            'm', 'м' -> "km/h"
            't', 'i' -> "mph"
            else -> "km/h"
        }
    }

    fun parseEta(str: String): String {
        val direct = parseEtaOnly(str)
        if (direct.isNotEmpty()) return direct

        for (token in str.split(" ")) {
            val idx = token.indexOf(':')
            if (idx > 0 && idx < token.length - 1) {
                var start = idx - 1
                var end = idx + 2
                if (start - 1 >= 0 && token[start - 1].isDigit()) start--
                if (end < token.length && token[end].isDigit()) end++
                if (start >= 0 && end <= token.length) {
                    return token.substring(start, end)
                }
            }
        }
        return ""
    }

    private fun getEta(values: NotificationValues): String {
        val headerText = values.texts["header_text"]
        if (headerText.isNullOrEmpty()) {
            val subText = values.texts["android-subText"] ?: return ""
            return parseEtaOnly(subText)
        }
        return parseEtaOnly(headerText)
    }

    private fun getSigns(values: NotificationValues): String {
        val text = values.texts["title_container-notification_text_container-text"]
        val text2 = values.texts["title_container-notification_text_container-text2"]
        val androidTitle = values.texts["android-title"] ?: return ""
        if (text == null) return ""
        return if (text2 == null) text else "$text <b>${androidTitle.replace(text, "").replace(text2, "")}</b> $text2"
    }

    private fun getSigns2(values: NotificationValues): String {
        return values.texts["notification_main_column-title"] ?: ""
    }

    private fun getDistance(values: NotificationValues): String {
        val text = values.texts["description_container-notification_text_container-text"]
        val text1 = values.texts["description_container-notification_text_container-text1"]
        val text3 = values.texts["description_container-notification_text_container-text3"]
        val androidText = values.texts["android-text"]
        return if (text3 != null && text3.length > 1) text3
        else if (values.drawables["description_container-notification_text_container-icon_image"] != null && !androidText.isNullOrEmpty()) androidText
        else text1 ?: text ?: ""
    }

    private fun getDistance2(values: NotificationValues): String {
        return values.texts["notification_main_column-text"] ?: ""
    }

    private fun getDuration(values: NotificationValues): String {
        val text = values.texts["description_container-notification_text_container-text"]
        val text1 = values.texts["description_container-notification_text_container-text1"]
        val text2 = values.texts["description_container-notification_text_container-text2"]
        return if (values.drawables["description_container-notification_text_container-icon_image"] != null && !text2.isNullOrEmpty()) text2
        else text1 ?: text ?: "-"
    }

    private fun trim(str: String): String {
        return if (str.startsWith(" · ")) str.substring(3) else str
    }

    private fun getBitmap(drawable: Drawable?): Bitmap? {
        if (drawable == null) return null
        if (drawable is BitmapDrawable) return drawable.bitmap
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 85
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 85
        val bmp = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = android.graphics.Canvas(bmp)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bmp
    }
}
