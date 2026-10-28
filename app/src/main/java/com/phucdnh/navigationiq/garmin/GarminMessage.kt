package com.phucdnh.navigationiq.garmin

import android.content.Context
import android.util.Log
import com.phucdnh.navigationiq.model.NavigationInfo
import java.math.BigInteger
import java.nio.ByteBuffer
import java.security.MessageDigest

/**
 * Garmin message structure and diff cache.
 * Directly ported from HeadUpNav com.headupnav.navigationwear.ConnectIQManager.
 */
class GarminMessage {
    var settings: List<Int?>? = null
    var navigation: List<String?>? = null
    var bitmapData: List<Int> = emptyList()
    var imageHash: String = ""
    var isNaviEnd: Boolean = false

    constructor() {
        isNaviEnd = true
    }

    constructor(context: Context, info: NavigationInfo, cache: SentDataCache, forceFullSync: Boolean = false) {
        isNaviEnd = false
        val defaultSettings = listOf(
            1, // isPremium
            1, // showCurrentTime
            0, // showEta
            0, // showDuration
            0, // showLength
            0, // showSpeed
            0, // dimDisplay
            0, // layout
            0, // playVoice
            info.progress, // showProgress
            1, // vibrationMode
            0, // rotateDisplay
            -257, // directionColor
            -257, // instructionColor
            -257, // distanceColor
            -257, // lengthColor
            -257, // durationColor
            -257, // etaColor
            -257, // timeColor
            -257  // speedColor
        )
        settings = if (forceFullSync) defaultSettings else cache.diffSettings(defaultSettings)
        val rawNav = info.getDirectionStrings(context, true)
        navigation = if (forceFullSync) rawNav else cache.diffNavigation(rawNav)

        val rleBytes = info.getRleBytes(context, -257, 56, 56)
        val currentHash = getDataHash(rleBytes)
        val hasImageChanged = forceFullSync || cache.hasImageChanged(currentHash)
        bitmapData = if (hasImageChanged && rleBytes.isNotEmpty()) rleBytes else emptyList()
        imageHash = if (hasImageChanged) currentHash else ""
    }

    fun isEmpty(): Boolean {
        return !isNaviEnd &&
                isAllNulls(settings) &&
                isAllNulls(navigation) &&
                bitmapData.isEmpty() &&
                imageHash.isEmpty()
    }

    fun toDataPayload(): List<Any?> {
        if (isNaviEnd) {
            return listOf("naviend")
        }
        return listOf(
            settings,
            navigation,
            bitmapData,
            imageHash
        )
    }

    private fun isAllNulls(list: List<Any?>?): Boolean {
        if (list == null) return true
        return list.all { it == null }
    }

    companion object {
        fun getDataHash(list: List<Int>): String {
            if (list.isEmpty()) return ""
            val buffer = ByteBuffer.allocate(list.size * 4)
            for (item in list) {
                buffer.putInt(item)
            }
            return try {
                val md5 = MessageDigest.getInstance("MD5")
                val digest = md5.digest(buffer.array())
                BigInteger(1, digest).toString(16)
            } catch (e: Exception) {
                Log.e("GarminMessage", "Error calculating hash: ${e.message}")
                ""
            }
        }
    }
}

class SentDataCache {
    var sendBitmap: Boolean = true
    private var lastImageHash: String? = null
    private var lastNavigation: MutableList<String?>? = null
    private var lastSettings: MutableList<Int?>? = null

    fun diffSettings(incoming: List<Int>): List<Int?> {
        val last = lastSettings
        if (last == null) {
            lastSettings = incoming.toMutableList()
            return incoming
        }
        val diff = ArrayList<Int?>(incoming.size)
        for (i in incoming.indices) {
            val newVal = incoming[i]
            if (i >= last.size || last[i] != newVal) {
                diff.add(newVal)
                if (i < last.size) last[i] = newVal else last.add(newVal)
            } else {
                diff.add(null)
            }
        }
        return diff
    }

    fun diffNavigation(incoming: List<String>): List<String?> {
        val last = lastNavigation
        if (last == null) {
            lastNavigation = incoming.toMutableList()
            return incoming
        }
        val diff = ArrayList<String?>(incoming.size)
        for (i in incoming.indices) {
            val newVal = incoming[i]
            if (i == 5 || i >= last.size || last[i] != newVal) {
                diff.add(newVal)
                if (i < last.size) last[i] = newVal else last.add(newVal)
            } else {
                diff.add(null)
            }
        }
        return diff
    }

    fun hasImageChanged(newHash: String): Boolean {
        if (newHash.isEmpty()) return false
        if (sendBitmap || lastImageHash == null || lastImageHash != newHash) {
            lastImageHash = newHash
            sendBitmap = false
            return true
        }
        return false
    }

    fun reset() {
        sendBitmap = true
        lastImageHash = null
        lastNavigation = null
        lastSettings = null
    }
}
