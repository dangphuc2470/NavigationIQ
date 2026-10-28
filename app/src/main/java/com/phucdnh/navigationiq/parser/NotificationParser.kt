package com.phucdnh.navigationiq.parser

import android.content.Context
import android.graphics.drawable.Drawable
import android.graphics.drawable.Icon
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
    }
}
