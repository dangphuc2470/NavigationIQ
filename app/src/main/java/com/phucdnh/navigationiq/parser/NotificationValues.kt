package com.phucdnh.navigationiq.parser

import android.graphics.drawable.Drawable
import android.widget.Button

/**
 * Container for parsed notification texts, drawables, and action buttons.
 * Ported from com.navigationparser.lib.Parsing.NotificationValues.
 */
class NotificationValues {
    val texts: MutableMap<String, String> = HashMap()
    val drawables: MutableMap<String, Drawable?> = HashMap()
    val buttons: MutableMap<String, Button?> = HashMap()
    var segmentDistMeters: Int? = null
}
