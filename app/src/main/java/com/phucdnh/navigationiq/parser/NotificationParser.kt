package com.phucdnh.navigationiq.parser

import android.content.Context
import android.graphics.drawable.Drawable
import android.graphics.drawable.Icon
import android.os.Bundle
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * Parses StatusBarNotification by safely inspecting standard notification Bundle extras.
 */
object NotificationParser {
    private const val TAG = "NotificationParser"

    fun parse(context: Context, sbn: StatusBarNotification): NotificationValues {
        val values = NotificationValues()
        try {
            parseExtras(context, sbn, values)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing notification: ${e.message}")
        }
        return values
    }

    private fun parseExtras(
        context: Context,
        sbn: StatusBarNotification,
        values: NotificationValues
    ) {
        val notif = sbn.notification ?: return
        val extras = notif.extras ?: return
        for (key in extras.keySet()) {
            val value = extras.get(key)
            val sanitizedKey = key.replace(".", "-")
            when (value) {
                is CharSequence -> values.texts[sanitizedKey] = value.toString()
                is Number -> values.texts[sanitizedKey] = value.toString()
                is Drawable -> values.drawables[sanitizedKey] = value
                is Icon -> {
                    try {
                        values.drawables[sanitizedKey] = value.loadDrawable(context)
                    } catch (_: Exception) {}
                }
            }
        }
        notif.actions?.forEachIndexed { index, action ->
            val title = action.title?.toString() ?: ""
            if (title.isNotEmpty()) {
                values.texts["action-$index"] = title
            }
        }

        // Parse Android 15/16 Notification.ProgressStyle segments (Google Maps turn-by-turn segments)
        try {
            val progressCur = extras.getInt("android.progress", 0)
            val rawSegments = extras.get("android.progressSegments")
                ?: extras.get("androidx.core.app.extra.PROGRESS_SEGMENTS")
            if (rawSegments is List<*>) {
                var accumLength = 0
                for (seg in rawSegments) {
                    val segBundle = seg as? Bundle ?: continue
                    var segLen = -1
                    for (k in segBundle.keySet()) {
                        val v = segBundle.get(k)
                        if (v is Int && v > 0) {
                            if (k.contains("length", ignoreCase = true) || segLen == -1) {
                                segLen = v
                            }
                        }
                    }
                    if (segLen > 0) {
                        accumLength += segLen
                        if (accumLength > progressCur) {
                            values.segmentDistMeters = accumLength - progressCur
                            break
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to parse progress segments: ${e.message}")
        }
    }
}
