package com.phucdnh.navigationiq.model

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Icon
import android.icu.text.MeasureFormat
import android.icu.util.Measure
import android.icu.util.MeasureUnit
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.text.DateFormat
import java.util.Date
import java.util.Locale

/**
 * Data model for turn-by-turn navigation state extracted from Google Maps / OsmAnd.
 * Directly ported from HeadUpNav com.navigationparser.lib.Parsing.NavigationInfo.
 */
data class NavigationInfo(
    var isPublicTransport: Boolean = false,
    var units: String = "",
    var eta: String = "",
    var length: String = "",
    var duration: String = "",
    var distance: String = "",
    var error: String = "",
    var signs: String = "",
    var bitmap: Bitmap? = null,
    var progress: Int = -1,
    var icon: Icon? = null,
    var isArrivedState: Boolean = false
) {
    fun isEmpty(): Boolean {
        return units.isEmpty() && eta.isEmpty() && length.isEmpty() &&
                duration.isEmpty() && distance.isEmpty() && error.isEmpty() &&
                signs.isEmpty() && bitmap == null && icon == null
    }

    fun isArrived(): Boolean {
        if (isArrivedState) return true
        val s = signs.lowercase().trim()
        return s.contains("bạn đã đến") || s.contains("đã đến điểm đến") ||
                s.contains("đã đến nơi") || s.contains("đã tới nơi") ||
                s.contains("you have arrived") || s.contains("arrived at") ||
                s == "arrived" || s == "đã đến" || s == "đã tới" ||
                s.startsWith("arrived ·") || s.startsWith("đã đến ·") ||
                s.startsWith("arriving") || s.contains("arriving at") ||
                s.contains("sắp đến") || s.contains("sắp tới") ||
                s.contains("đang đến") || s.contains("đang tới") ||
                s.contains("bạn sắp đến") || s.contains("bạn đang đến")
    }

    fun getDistanceMeters(): Int {
        if (distance.isEmpty()) return -1
        val clean = distance.trim().lowercase()
        return try {
            if (clean.endsWith("km")) {
                val num = clean.replace("km", "").trim().replace(",", ".").toFloatOrNull() ?: -1f
                if (num >= 0) (num * 1000).toInt() else -1
            } else if (clean.endsWith("m") || clean.endsWith("м")) {
                val num = clean.replace("m", "").replace("м", "").trim().replace(",", ".").toFloatOrNull() ?: -1f
                if (num >= 0) num.toInt() else -1
            } else {
                val digits = clean.filter { it.isDigit() || it == '.' }.toFloatOrNull() ?: -1f
                if (digits >= 0) digits.toInt() else -1
            }
        } catch (_: Exception) {
            -1
        }
    }

    fun getLengthMeters(): Int {
        if (length.isEmpty() || length == "-") return -1
        val clean = length.replace('\u00A0', ' ').trim().lowercase()
        return try {
            if (clean.endsWith("km")) {
                val num = clean.replace("km", "").trim().replace(",", ".").toFloatOrNull() ?: -1f
                if (num >= 0) (num * 1000).toInt() else -1
            } else if (clean.endsWith("mi")) {
                val num = clean.replace("mi", "").trim().replace(",", ".").toFloatOrNull() ?: -1f
                if (num >= 0) (num * 1609.34f).toInt() else -1
            } else if (clean.endsWith("m") || clean.endsWith("м")) {
                val num = clean.replace("m", "").replace("м", "").trim().replace(",", ".").toFloatOrNull() ?: -1f
                if (num >= 0) num.toInt() else -1
            } else {
                -1
            }
        } catch (_: Exception) {
            -1
        }
    }

    fun getMinutesRemaining(): Int {
        val parsed = getMinutesFromDuration(duration)
        if (parsed > 0) return parsed
        val digits = duration.split(" ", " ").firstOrNull { it.all { c -> c.isDigit() } }?.toIntOrNull()
        if (digits != null && (duration.contains("min") || duration.contains("phút") || duration.contains("m"))) {
            return digits
        }
        return -1
    }

    fun getEtaDifferenceMinutes(): Int? {
        if (eta.isEmpty() || !eta.contains(":")) return null
        return try {
            val parts = eta.split(":")
            if (parts.size >= 2) {
                val etaHour = parts[0].trim().toIntOrNull() ?: return null
                val etaMin = parts[1].trim().take(2).toIntOrNull() ?: return null
                val now = java.util.Calendar.getInstance()
                val nowHour = now.get(java.util.Calendar.HOUR_OF_DAY)
                val nowMin = now.get(java.util.Calendar.MINUTE)
                val etaTotalMin = etaHour * 60 + etaMin
                val nowTotalMin = nowHour * 60 + nowMin
                etaTotalMin - nowTotalMin
            } else null
        } catch (_: Exception) {
            null
        }
    }

    /**
     * Determines whether navigation was practically at or near the destination.
     * Useful fallback when navigation notification is dismissed without explicit arrival text
     * (e.g. Foreign languages, user arrives at destination and closes Maps, or Maps auto-finishes).
     */
    fun isNearDestination(): Boolean {
        if (isArrived()) return true

        // 1. Total remaining route length <= 150m (NOT distance to next turn!)
        val remainingLengthMeters = getLengthMeters()
        if (remainingLengthMeters in 0..150) return true

        // 2. Remaining duration <= 1 minute (and remaining length is small <= 500m or unspecified)
        val mins = getMinutesRemaining()
        if (mins in 0..1 && (remainingLengthMeters in 0..500 || remainingLengthMeters < 0)) return true

        // 3. Route progress >= 98%
        if (progress in 98..100) return true

        return false
    }

    fun hasDirections(): Boolean {
        if (isNearDestination()) return true
        if (bitmap == null && icon == null && !isPublicTransport) {
            return false
        }
        return distance.isNotEmpty() || duration.isNotEmpty() || eta.isNotEmpty() || length.isNotEmpty()
    }

    fun hasAllRequiredFieldsCar(): Boolean {
        if (bitmap == null && icon == null) return false
        return eta.isNotEmpty() && length.isNotEmpty() && duration.isNotEmpty() && signs.isNotEmpty()
    }

    fun hasAllRequiredFieldsPT(): Boolean {
        if (bitmap == null && icon == null) return false
        return eta.isNotEmpty() && signs.isNotEmpty() && distance.isNotEmpty()
    }

    fun getDirectionStrings(context: Context, stripHtml: Boolean = true): List<String> {
        val cleanSigns = if (stripHtml) {
            signs.replace("<b>", "").replace("</b>", "")
        } else {
            signs
        }
        return listOf(units, eta, length, duration, distance, cleanSigns, getCurrentTimeString())
    }

    fun setProgress(context: Context, startDuration: String): Boolean {
        val totalMinutes = getMinutesFromDuration(startDuration)
        val remainingMinutes = getMinutesFromDuration(duration)
        if (totalMinutes == 0 || remainingMinutes == 0 || totalMinutes < remainingMinutes) {
            return false
        }
        progress = (((totalMinutes - remainingMinutes).toFloat() / totalMinutes.toFloat()) * 100f).toInt()
        return true
    }

    private fun getMinutesFromDuration(str: String): Int {
        if (str.isEmpty()) return 0
        return try {
            val measureFormat = MeasureFormat.getInstance(Locale.getDefault(), MeasureFormat.FormatWidth.SHORT)
            val measureFormatNarrow = MeasureFormat.getInstance(Locale.getDefault(), MeasureFormat.FormatWidth.NARROW)
            val hourUnit = measureFormat.format(Measure(1, MeasureUnit.HOUR)).replace("1 ", "")
            val minUnit = measureFormat.format(Measure(1, MeasureUnit.MINUTE)).replace("1 ", "")
            val dayUnit = measureFormatNarrow.format(Measure(1, MeasureUnit.DAY)).replace("1 ", "")

            val tokens = str.split(" ", " ")
            var totalMin = 0
            var i = 0
            while (i < tokens.size - 1) {
                val num = tokens[i].toIntOrNull()
                val unitStr = tokens[i + 1]
                if (num != null) {
                    if (unitStr.startsWith(minUnit)) {
                        totalMin += num
                        break
                    } else if (unitStr.startsWith(hourUnit)) {
                        totalMin += num * 60
                    } else if (unitStr.startsWith(dayUnit)) {
                        totalMin += num * 1440
                    }
                }
                i += 2
            }
            totalMin
        } catch (_: Exception) {
            0
        }
    }

    fun getBitmapToSerialize(context: Context, tintColor: Int = Color.WHITE): Bitmap? {
        var bmp = bitmap
        if (bmp == null) {
            icon?.let { ic ->
                val drawable = ic.loadDrawable(context)
                if (drawable is BitmapDrawable) {
                    bmp = drawable.bitmap
                } else if (drawable != null) {
                    val w = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 64
                    val h = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 64
                    val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                    val c = Canvas(b)
                    drawable.setBounds(0, 0, w, h)
                    drawable.draw(c)
                    bmp = b
                }
            }
        }
        return bmp?.let { tintBitmap(it, tintColor) }
    }

    /**
     * Run-Length Encoding (RLE) bitmap serializer for Garmin ConnectIQ devices.
     * Compresses bitmap to low bandwidth payload suitable for Garmin BLE transfer.
     */
    fun getRleBytes(context: Context, tintColor: Int, targetWidth: Int = 85, targetHeight: Int = 85): List<Int> {
        val result = mutableListOf<Int>()
        var bmp = getBitmapToSerialize(context, tintColor) ?: return result

        if (targetWidth > 0 && targetHeight > 0) {
            bmp = Bitmap.createScaledBitmap(bmp, targetWidth, targetHeight, true)
        }

        val pixels = IntArray(bmp.width * bmp.height)
        bmp.getPixels(pixels, 0, bmp.width, 0, 0, bmp.width, bmp.height)

        result.add(bmp.width)
        result.add(bmp.height)

        var currentColor = 0
        var currentCount = 0
        var xPos = 0

        for (pixel in pixels) {
            if (currentColor != pixel || xPos == bmp.width) {
                if (currentCount > 0) {
                    result.add(currentColor)
                    result.add(currentCount)
                }
                if (xPos == bmp.width) {
                    xPos = 0
                }
                currentCount = 0
                currentColor = pixel
            }
            currentCount++
            xPos++
        }
        if (currentCount > 0) {
            result.add(currentColor)
            result.add(currentCount)
        }
        return result
    }

    fun getPngBytes(context: Context, tintColor: Int): ByteArray {
        val bmp = getBitmapToSerialize(context, tintColor) ?: return ByteArray(0)
        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, 100, stream)
        return stream.toByteArray()
    }

    companion object {
        fun getCurrentTimeString(): String {
            val formatted = DateFormat.getTimeInstance(DateFormat.SHORT).format(Date())
            val parts = formatted.trim().split("\\s+".toRegex())
            return if (parts.isNotEmpty() && parts[0].isNotEmpty()) parts[0] else formatted
        }

        fun tintBitmap(source: Bitmap?, color: Int): Bitmap? {
            if (source == null) return null
            val result = Bitmap.createBitmap(source.width, source.height, Bitmap.Config.ARGB_8888)
            val canvas = android.graphics.Canvas(result)
            val paint = android.graphics.Paint()
            val colorMatrix = android.graphics.ColorMatrix()
            colorMatrix.setSaturation(0f)

            val r = android.graphics.Color.red(color) / 255f
            val g = android.graphics.Color.green(color) / 255f
            val b = android.graphics.Color.blue(color) / 255f

            val matrix = android.graphics.ColorMatrix(
                floatArrayOf(
                    r, 0f, 0f, 0f, 0f,
                    0f, g, 0f, 0f, 0f,
                    0f, 0f, b, 0f, 0f,
                    0f, 0f, 0f, 1f, 0f
                )
            )
            colorMatrix.postConcat(matrix)
            paint.colorFilter = android.graphics.ColorMatrixColorFilter(colorMatrix)
            canvas.drawBitmap(source, 0f, 0f, paint)
            return result
        }

    }
}
