package com.phucdnh.navigationiq.history

import android.content.Context
import com.phucdnh.navigationiq.model.TripSummary
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import org.json.JSONArray
import org.json.JSONObject

object TripHistoryManager {
    private const val PREFS_NAME = "navigation_iq_prefs"
    private const val KEY_ENABLED = "trip_history_enabled"
    private const val KEY_HISTORY_JSON = "trip_history_json"
    private const val MAX_HISTORY_ITEMS = 30

    private val _isEnabled = MutableStateFlow(false)
    val isEnabledFlow: StateFlow<Boolean> = _isEnabled.asStateFlow()

    private val _history = MutableStateFlow<List<TripSummary>>(emptyList())
    val historyFlow: StateFlow<List<TripSummary>> = _history.asStateFlow()

    private var initialized = false

    @Synchronized
    fun init(context: Context) {
        if (initialized) return
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        _isEnabled.value = prefs.getBoolean(KEY_ENABLED, false)
        _history.value = loadFromPrefs(prefs)
        initialized = true
    }

    fun isHistoryEnabled(context: Context): Boolean {
        init(context)
        return _isEnabled.value
    }

    @Synchronized
    fun setHistoryEnabled(context: Context, enabled: Boolean) {
        init(context)
        _isEnabled.value = enabled
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_ENABLED, enabled)
            .apply()
    }

    fun getHistory(context: Context): List<TripSummary> {
        init(context)
        return _history.value
    }

    @Synchronized
    fun addTrip(context: Context, summary: TripSummary) {
        init(context)
        if (!_isEnabled.value) return

        val current = _history.value.toMutableList()
        // Prevent accidental duplicate logs within 30 seconds for the same destination
        val recentDup = current.firstOrNull()
        if (recentDup != null &&
            recentDup.destination == summary.destination &&
            kotlin.math.abs(summary.timestamp - recentDup.timestamp) < 30_000L
        ) {
            return
        }

        current.add(0, summary)
        val trimmed = if (current.size > MAX_HISTORY_ITEMS) {
            current.take(MAX_HISTORY_ITEMS)
        } else {
            current
        }

        _history.value = trimmed
        saveToPrefs(context, trimmed)
    }

    @Synchronized
    fun deleteTrip(context: Context, index: Int) {
        init(context)
        val current = _history.value.toMutableList()
        if (index in current.indices) {
            current.removeAt(index)
            _history.value = current
            saveToPrefs(context, current)
        }
    }

    @Synchronized
    fun clearHistory(context: Context) {
        init(context)
        _history.value = emptyList()
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_HISTORY_JSON)
            .apply()
    }

    private fun loadFromPrefs(prefs: android.content.SharedPreferences): List<TripSummary> {
        val raw = prefs.getString(KEY_HISTORY_JSON, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            val list = ArrayList<TripSummary>(arr.length())
            for (i in 0 until arr.length()) {
                val obj = arr.optJSONObject(i) ?: continue
                list.add(
                    TripSummary(
                        destination = obj.optString("destination", ""),
                        duration = obj.optString("duration", ""),
                        distance = obj.optString("distance", ""),
                        avgSpeed = obj.optString("avgSpeed", ""),
                        startTime = obj.optString("startTime", ""),
                        endTime = obj.optString("endTime", ""),
                        timestamp = obj.optLong("timestamp", System.currentTimeMillis())
                    )
                )
            }
            list
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun saveToPrefs(context: Context, list: List<TripSummary>) {
        val arr = JSONArray()
        for (item in list) {
            val obj = JSONObject().apply {
                put("destination", item.destination)
                put("duration", item.duration)
                put("distance", item.distance)
                put("avgSpeed", item.avgSpeed)
                put("startTime", item.startTime)
                put("endTime", item.endTime)
                put("timestamp", item.timestamp)
            }
            arr.put(obj)
        }
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_HISTORY_JSON, arr.toString())
            .apply()
    }
}
