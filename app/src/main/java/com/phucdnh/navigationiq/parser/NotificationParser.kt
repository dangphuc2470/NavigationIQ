package com.phucdnh.navigationiq.parser

import android.app.Notification
import android.content.Context
import android.graphics.drawable.Drawable
import android.graphics.drawable.Icon
import android.service.notification.StatusBarNotification
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.ImageView
import android.widget.RemoteViews
import android.widget.TextView

/**
 * Parses StatusBarNotification by inflating RemoteViews and inspecting Bundle extras.
 * Ported from com.navigationparser.lib.Parsing.NotificationParser.
 */
object NotificationParser {
    private const val TAG = "NotificationParser"

    fun parse(context: Context, sbn: StatusBarNotification): NotificationValues {
        val values = NotificationValues()
        try {
            val pkgContext = context.createPackageContext(sbn.packageName, Context.CONTEXT_IGNORE_SECURITY)
            val bigContentView = getBigContentView(context, sbn)
            if (bigContentView != null) {
                val group = getRemoteViewGroup(pkgContext, bigContentView)
                parseRemoteView(pkgContext, group, "", values)
            } else {
                val normalContentView = getNormalContentView(context, sbn)
                if (normalContentView != null) {
                    val group = getRemoteViewGroup(pkgContext, normalContentView)
                    parseRemoteView(pkgContext, group, "", values)
                }
            }
            parseExtras(context, sbn, values)
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing notification: ${e.message}")
        }
        return values
    }

    private fun getNormalContentView(context: Context, sbn: StatusBarNotification): RemoteViews? {
        return try {
            Notification.Builder.recoverBuilder(context, sbn.notification).createContentView()
        } catch (e: Exception) {
            null
        }
    }

    private fun getBigContentView(context: Context, sbn: StatusBarNotification): RemoteViews? {
        return try {
            Notification.Builder.recoverBuilder(context, sbn.notification).createBigContentView()
        } catch (e: Exception) {
            null
        }
    }

    private fun getRemoteViewGroup(context: Context, remoteViews: RemoteViews?): ViewGroup? {
        if (remoteViews == null) return null
        return try {
            val inflater = context.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
            val group = inflater.inflate(remoteViews.layoutId, null) as? ViewGroup
            group?.let { remoteViews.reapply(context, it) }
            group
        } catch (e: Exception) {
            Log.e(TAG, "Error inflating RemoteViews: ${e.message}")
            null
        }
    }

    private fun parseRemoteView(
        context: Context,
        viewGroup: ViewGroup?,
        prefix: String,
        values: NotificationValues
    ) {
        if (viewGroup == null) return
        for (i in 0 until viewGroup.childCount) {
            val child = viewGroup.getChildAt(i) ?: continue
            var entryName = if (child.id != View.NO_ID) {
                try {
                    context.resources.getResourceEntryName(child.id)
                } catch (_: Exception) {
                    ""
                }
            } else ""

            if (entryName.isNotEmpty() && prefix.isNotEmpty()) {
                entryName = "$prefix-$entryName"
            }

            val keySuffix = if (values.drawables.containsKey(entryName) || values.texts.containsKey(entryName)) "$i" else ""
            val key = entryName + keySuffix

            when (child) {
                is ImageView -> {
                    values.drawables[key] = child.drawable
                }
                is Button -> {
                    values.buttons[key] = child
                }
                is TextView -> {
                    values.texts[key] = child.text?.toString() ?: ""
                }
                is ViewGroup -> {
                    parseRemoteView(context, child, entryName, values)
                }
            }
        }
    }

    private fun parseExtras(
        context: Context,
        sbn: StatusBarNotification,
        values: NotificationValues
    ) {
        try {
            val extras = sbn.notification.extras ?: return
            for (key in extras.keySet()) {
                val value = extras.get(key)
                val sanitizedKey = key.replace(".", "-")
                when (value) {
                    is CharSequence -> values.texts[sanitizedKey] = value.toString()
                    is Drawable -> values.drawables[sanitizedKey] = value
                    is Icon -> values.drawables[sanitizedKey] = value.loadDrawable(context)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing extras: ${e.message}")
        }
    }
}
