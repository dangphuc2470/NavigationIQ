package com.phucdnh.navigationiq.update

import android.content.Context
import android.content.Intent
import android.net.Uri
import com.phucdnh.navigationiq.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

data class AppUpdateInfo(
    val versionName: String,
    val releaseTitle: String,
    val whatsNew: String,
    val apkDownloadUrl: String,
    val htmlUrl: String
)

object UpdateChecker {
    private const val PREFS_NAME = "navigation_iq_prefs"
    private const val KEY_SKIPPED_VERSION = "pref_skipped_version"
    private const val GITHUB_LATEST_RELEASE_API =
        "https://api.github.com/repos/dangphuc2470/NavigationIQ/releases/latest"

    fun getSkippedVersion(context: Context): String? {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getString(KEY_SKIPPED_VERSION, null)
    }

    fun setSkippedVersion(context: Context, version: String) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putString(KEY_SKIPPED_VERSION, version).apply()
    }

    suspend fun checkForUpdate(
        context: Context,
        isManualCheck: Boolean = false
    ): AppUpdateInfo? = withContext(Dispatchers.IO) {
        try {
            val url = URL(GITHUB_LATEST_RELEASE_API)
            val connection = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 6000
                readTimeout = 6000
                requestMethod = "GET"
                setRequestProperty("Accept", "application/vnd.github.v3+json")
                setRequestProperty("User-Agent", "NavigationIQ-AndroidApp")
            }

            if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                return@withContext null
            }

            val responseBody = connection.inputStream.bufferedReader().use { it.readText() }
            val json = JSONObject(responseBody)

            val tagName = json.optString("tag_name", "").trim()
            val remoteVersion = tagName.removePrefix("v").removePrefix("V").trim()
            if (remoteVersion.isEmpty()) return@withContext null

            // If automatic check and user skipped this specific version, do not prompt
            if (!isManualCheck) {
                val skipped = getSkippedVersion(context)
                if (skipped != null && skipped.equals(remoteVersion, ignoreCase = true)) {
                    return@withContext null
                }
            }

            val currentVersion = BuildConfig.VERSION_NAME.removePrefix("v").removePrefix("V").trim()
            if (!isNewerVersion(remoteVersion, currentVersion)) {
                return@withContext null
            }

            val releaseTitle = json.optString("name", "Version $tagName")
            val rawBody = json.optString("body", "")
            val whatsNew = extractWhatsNew(rawBody)
            val htmlUrl = json.optString("html_url", "https://github.com/dangphuc2470/NavigationIQ/releases/latest")

            var apkUrl: String? = null
            val assets = json.optJSONArray("assets")
            if (assets != null) {
                for (i in 0 until assets.length()) {
                    val asset = assets.getJSONObject(i)
                    val name = asset.optString("name", "")
                    if (name.endsWith(".apk", ignoreCase = true)) {
                        apkUrl = asset.optString("browser_download_url", "")
                        break
                    }
                }
            }

            val targetDownloadUrl = apkUrl?.takeIf { it.isNotBlank() } ?: htmlUrl

            AppUpdateInfo(
                versionName = remoteVersion,
                releaseTitle = releaseTitle,
                whatsNew = whatsNew,
                apkDownloadUrl = targetDownloadUrl,
                htmlUrl = htmlUrl
            )
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    fun isNewerVersion(remote: String, current: String): Boolean {
        val cleanRemote = remote.split("-")[0].trim()
        val cleanCurrent = current.split("-")[0].trim()
        val remoteParts = cleanRemote.split(".").mapNotNull { it.toIntOrNull() }
        val currentParts = cleanCurrent.split(".").mapNotNull { it.toIntOrNull() }
        val maxLen = maxOf(remoteParts.size, currentParts.size)
        for (i in 0 until maxLen) {
            val r = remoteParts.getOrElse(i) { 0 }
            val c = currentParts.getOrElse(i) { 0 }
            if (r > c) return true
            if (r < c) return false
        }
        return false
    }

    private fun extractWhatsNew(body: String): String {
        if (body.isBlank()) return ""
        val marker = "What's New"
        val idx = body.indexOf(marker, ignoreCase = true)
        val raw = if (idx != -1) {
            val sub = body.substring(idx + marker.length).trim()
            val endIdx = sub.indexOf("---")
            if (endIdx != -1) sub.substring(0, endIdx).trim() else sub.take(400).trim()
        } else {
            val endIdx = body.indexOf("---")
            if (endIdx != -1) body.substring(0, endIdx).trim() else body.take(400).trim()
        }
        return raw.lines()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") }
            .joinToString("\n")
    }

    fun openPlayStore(context: Context) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=${context.packageName}")).apply {
                setPackage("com.android.vending")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            val webIntent = Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=${context.packageName}")).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(webIntent)
        }
    }
}
