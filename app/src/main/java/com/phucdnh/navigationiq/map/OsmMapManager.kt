package com.phucdnh.navigationiq.map

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.util.Log
import android.util.LruCache
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.cos
import kotlin.math.floor
import kotlin.math.ln
import kotlin.math.tan

/**
 * Data structure for a compressed map packet sent to Garmin watch.
 */
data class OsmMapPacket(
    val width: Int,
    val height: Int,
    val zoom: Int,
    val speedKmh: Int,
    val headingDeg: Int,
    val rleData: String, // Compact Hex String of RLE pairs e.g. "0A060500..." (only 2-4 KB)
    val palette: List<Int>  // 16 RGB values (e.g. 0x000000, 0xFFFFFF, etc.)
)

data class OfflineDownloadState(
    val isDownloading: Boolean = false,
    val current: Int = 0,
    val total: Int = 0,
    val percent: Int = 0,
    val statusMessage: String = "Sẵn sàng"
)

object OsmMapManager {

    private const val TAG = "OsmMapManager"
    private const val TILE_SIZE = 256
    private const val MAP_DIMENSION = 100 // 100x100 px square (ultra-fast BLE transmission & butter smooth Garmin rendering)
    private const val USER_AGENT = "NavigationIQ/1.0 (Android Garmin Relay)"

    // In-memory LRU cache for 256x256 OSM tiles
    private val tileCache = LruCache<String, Bitmap>(50)
    private var offlineDir: File? = null

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private val _downloadState = MutableStateFlow(OfflineDownloadState())
    val downloadStateFlow = _downloadState.asStateFlow()

    private val _storageSizeText = MutableStateFlow("0 MB (0 mảnh)")
    val storageSizeTextFlow = _storageSizeText.asStateFlow()

    private val _latestMapBitmap = MutableStateFlow<Bitmap?>(null)
    val latestMapBitmapFlow = _latestMapBitmap.asStateFlow()

    // 16-color ultra-high-contrast bright roads palette for AMOLED display
    val BRIGHT_PALETTE = intArrayOf(
        0x000000, // 0: Pure Black Background
        0x2C2C2E, // 1: Dark Slate (Buildings)
        0x48484A, // 2: Medium Slate
        0x8E8E93, // 3: Medium Gray
        0xD1D5DB, // 4: Bright Light Silver (Local Streets)
        0xF3F4F6, // 5: Bright White Silver (Secondary Roads)
        0xFFFFFF, // 6: Pure Solid White (Main Streets / Roads)
        0x0A84FF, // 7: Electric Cyan Blue (Water / Rivers)
        0x30D158, // 8: Emerald Green (Parks / Nature)
        0xFFD60A, // 9: Bright Amber (Highways / Arteries)
        0xFF9F0A, // 10: Orange (Expressways)
        0xFF453A, // 11: Crimson Red
        0xBF5AF2, // 12: Purple
        0x5AC8FA, // 13: Light Blue
        0x34C759, // 14: Green
        0x14532D  // 15: Deep Pine
    )
    val DARK_PALETTE = BRIGHT_PALETTE

    private var locationManager: LocationManager? = null
    private var lastKnownLocation: Location? = null

    fun initialize(context: Context) {
        try {
            // Remove old daytime cache if it exists
            File(context.filesDir, "osm_offline_tiles").deleteRecursively()

            offlineDir = File(context.filesDir, "carto_dark_tiles").apply { mkdirs() }
            tileCache.evictAll()
            updateStorageStats()

            locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            val fineLoc = try {
                locationManager?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            } catch (e: SecurityException) {
                null
            }
            val coarseLoc = try {
                locationManager?.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            } catch (e: SecurityException) {
                null
            }
            lastKnownLocation = fineLoc ?: coarseLoc

            // Register continuous listener for accurate 5s location
            try {
                locationManager?.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    3000L,
                    5f,
                    object : LocationListener {
                        override fun onLocationChanged(location: Location) {
                            lastKnownLocation = location
                        }
                        override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
                        override fun onProviderEnabled(provider: String) {}
                        override fun onProviderDisabled(provider: String) {}
                    }
                )
            } catch (e: SecurityException) {
                Log.w(TAG, "Location permission not granted for GPS updates: ${e.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to init LocationManager: ${e.message}")
        }
    }

    fun getCurrentLocation(): Location? {
        return lastKnownLocation
    }

    /**
     * Fetch, crop, render dark-mode and RLE-compress a 180x180 map tile around current location.
     */
    suspend fun generateMapPacket(
        customLat: Double? = null,
        customLon: Double? = null,
        zoom: Int = 16
    ): OsmMapPacket? = withContext(Dispatchers.IO) {
        val lat = customLat ?: lastKnownLocation?.latitude ?: 10.7769
        val lon = customLon ?: lastKnownLocation?.longitude ?: 106.7009
        val speedKmh = ((lastKnownLocation?.speed ?: 0f) * 3.6f).toInt()
        val headingDeg = (lastKnownLocation?.bearing ?: 0f).toInt()

        try {
            // 1. Calculate World Pixel coordinates at given Zoom
            val n = 1 shl zoom
            val worldX = (lon + 180.0) / 360.0 * n * TILE_SIZE
            val latRad = Math.toRadians(lat)
            val worldY = (1.0 - ln(tan(latRad) + 1.0 / cos(latRad)) / Math.PI) / 2.0 * n * TILE_SIZE

            val halfDim = MAP_DIMENSION / 2
            val minX = worldX - halfDim
            val minY = worldY - halfDim
            val maxX = worldX + halfDim
            val maxY = worldY + halfDim

            val minTileX = floor(minX / TILE_SIZE).toInt()
            val minTileY = floor(minY / TILE_SIZE).toInt()
            val maxTileX = floor(maxX / TILE_SIZE).toInt()
            val maxTileY = floor(maxY / TILE_SIZE).toInt()

            // 2. Render viewport bitmap
            val viewportBitmap = Bitmap.createBitmap(MAP_DIMENSION, MAP_DIMENSION, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(viewportBitmap)
            canvas.drawColor(Color.BLACK)
            val tilePaint = Paint().apply {
                isAntiAlias = true
                isFilterBitmap = true
                isDither = true
            }

            for (tx in minTileX..maxTileX) {
                for (ty in minTileY..maxTileY) {
                    val tile = fetchOsmTile(zoom, tx, ty)
                    if (tile != null) {
                        val drawLeft = (tx * TILE_SIZE - minX).toFloat()
                        val drawTop = (ty * TILE_SIZE - minY).toFloat()
                        canvas.drawBitmap(tile, drawLeft, drawTop, tilePaint)
                    }
                }
            }

            // 3. Process into High-Contrast Bright Roads on Pure Black AMOLED
            val pixels = IntArray(MAP_DIMENSION * MAP_DIMENSION)
            viewportBitmap.getPixels(pixels, 0, MAP_DIMENSION, 0, 0, MAP_DIMENSION, MAP_DIMENSION)
            viewportBitmap.recycle()

            val indexedPixels = IntArray(pixels.size)
            for (i in pixels.indices) {
                indexedPixels[i] = mapPixelToBrightContrast(pixels[i])
            }

            // 4. Clean Subpixel Noise & Smooth Road Vectors (3x3 Majority / Mode Filter)
            val cleanPixels = IntArray(indexedPixels.size)
            for (y in 0 until MAP_DIMENSION) {
                for (x in 0 until MAP_DIMENSION) {
                    val center = indexedPixels[y * MAP_DIMENSION + x]
                    var maxCount = 0
                    var dominant = center
                    val counts = IntArray(16)
                    for (dy in -1..1) {
                        for (dx in -1..1) {
                            val nx = x + dx
                            val ny = y + dy
                            if (nx in 0 until MAP_DIMENSION && ny in 0 until MAP_DIMENSION) {
                                val p = indexedPixels[ny * MAP_DIMENSION + nx]
                                counts[p]++
                                if (counts[p] > maxCount) {
                                    maxCount = counts[p]
                                    dominant = p
                                }
                            }
                        }
                    }
                    // Keep center if it has at least 3 supporting neighbors, else merge into dominant surrounding cluster
                    cleanPixels[y * MAP_DIMENSION + x] = if (counts[center] >= 3) center else dominant
                }
            }

            // 5. Generate Ultra-Crisp High-Contrast Preview Bitmap for Android
            val previewPixels = IntArray(cleanPixels.size)
            for (i in cleanPixels.indices) {
                val palIdx = cleanPixels[i]
                previewPixels[i] = (0xFF shl 24) or BRIGHT_PALETTE[palIdx]
            }
            val previewBmp = Bitmap.createBitmap(previewPixels, MAP_DIMENSION, MAP_DIMENSION, Bitmap.Config.ARGB_8888)
            _latestMapBitmap.value = previewBmp

            // 6. Run-Length Encoding (RLE) Compression
            val rleList = mutableListOf<Int>()
            var currentIdx = cleanPixels[0]
            var count = 0

            for (idx in cleanPixels) {
                if (idx == currentIdx && count < 255) {
                    count++
                } else {
                    rleList.add(count)
                    rleList.add(currentIdx)
                    currentIdx = idx
                    count = 1
                }
            }
            if (count > 0) {
                rleList.add(count)
                rleList.add(currentIdx)
            }

            // Convert RLE list to ultra-compact Hex String (2 chars per byte)
            val hexChars = "0123456789ABCDEF"
            val sb = java.lang.StringBuilder(rleList.size * 2)
            for (item in rleList) {
                val byteVal = item and 0xFF
                sb.append(hexChars[byteVal shr 4])
                sb.append(hexChars[byteVal and 0x0F])
            }
            val rleHexString = sb.toString()

            Log.d(TAG, "OSM Map compressed to ${rleHexString.length / 2} bytes (${rleList.size / 2} runs) for ${MAP_DIMENSION}x${MAP_DIMENSION} viewport")

            OsmMapPacket(
                width = MAP_DIMENSION,
                height = MAP_DIMENSION,
                zoom = zoom,
                speedKmh = speedKmh,
                headingDeg = headingDeg,
                rleData = rleHexString,
                palette = BRIGHT_PALETTE.toList()
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error generating OSM Map packet: ${e.message}", e)
            null
        }
    }

    fun refreshPreview(zoom: Int = 16) {
        scope.launch {
            generateMapPacket(zoom = zoom)
        }
    }

    private suspend fun fetchOsmTile(z: Int, x: Int, y: Int): Bitmap? = withContext(Dispatchers.IO) {
        val cacheKey = "$z/$x/$y"
        // 1. Check RAM Cache
        tileCache.get(cacheKey)?.let { return@withContext it }

        // 2. Check Offline Storage on Disk
        val tileFile = offlineDir?.resolve("$z/$x/$y.png")
        if (tileFile != null && tileFile.exists() && tileFile.length() > 0) {
            try {
                val bitmap = BitmapFactory.decodeFile(tileFile.absolutePath)
                if (bitmap != null) {
                    tileCache.put(cacheKey, bitmap)
                    return@withContext bitmap
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to decode disk tile $cacheKey: ${e.message}")
            }
        }

        // 3. Fetch from CartoDB Dark Matter (Stadia / OpenMapTiles / Stamen Dark Mode CDN - Clean No-labels)
        val subdomains = arrayOf("a", "b", "c", "d")
        val s = subdomains[(x + y).let { if (it < 0) -it else it } % subdomains.size]
        val tileUrl = "https://$s.basemaps.cartocdn.com/rastertiles/dark_nolabels/$z/$x/$y.png"
        var conn: HttpURLConnection? = null
        try {
            val url = URL(tileUrl)
            conn = url.openConnection() as HttpURLConnection
            conn.setRequestProperty("User-Agent", USER_AGENT)
            conn.connectTimeout = 5000
            conn.readTimeout = 5000
            conn.doInput = true
            conn.connect()

            if (conn.responseCode == 200) {
                val input: InputStream = conn.inputStream
                val bytes = input.readBytes()
                input.close()

                // Save to offline disk cache
                tileFile?.parentFile?.mkdirs()
                if (tileFile != null && bytes.isNotEmpty()) {
                    FileOutputStream(tileFile).use { it.write(bytes) }
                }

                val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                if (bitmap != null) {
                    tileCache.put(cacheKey, bitmap)
                    return@withContext bitmap
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to download OSM tile $tileUrl: ${e.message}")
        } finally {
            conn?.disconnect()
        }
        null
    }

    /**
     * Download all zoom levels (14, 15, 16, 17) for a radius around GPS location.
     */
    fun startOfflineDownload(radiusKm: Double = 5.0) {
        if (_downloadState.value.isDownloading) return

        scope.launch {
            val lat = lastKnownLocation?.latitude ?: 10.7769
            val lon = lastKnownLocation?.longitude ?: 106.7009

            val dLat = radiusKm / 111.32
            val dLon = radiusKm / (111.32 * cos(Math.toRadians(lat)))
            val minLat = lat - dLat
            val maxLat = lat + dLat
            val minLon = lon - dLon
            val maxLon = lon + dLon

            val tileTasks = mutableListOf<Triple<Int, Int, Int>>()
            for (z in 14..17) {
                val n = 1 shl z
                val minX = floor((minLon + 180.0) / 360.0 * n).toInt().coerceIn(0, n - 1)
                val maxX = floor((maxLon + 180.0) / 360.0 * n).toInt().coerceIn(0, n - 1)
                val maxRad = Math.toRadians(maxLat)
                val minRad = Math.toRadians(minLat)
                val minY = floor((1.0 - ln(tan(maxRad) + 1.0 / cos(maxRad)) / Math.PI) / 2.0 * n).toInt().coerceIn(0, n - 1)
                val maxY = floor((1.0 - ln(tan(minRad) + 1.0 / cos(minRad)) / Math.PI) / 2.0 * n).toInt().coerceIn(0, n - 1)
                for (tx in minX..maxX) {
                    for (ty in minY..maxY) {
                        tileTasks.add(Triple(z, tx, ty))
                    }
                }
            }

            val total = tileTasks.size
            _downloadState.value = OfflineDownloadState(
                isDownloading = true,
                current = 0,
                total = total,
                percent = 0,
                statusMessage = "Đang bắt đầu tải $total mảnh..."
            )

            var count = 0
            for (task in tileTasks) {
                val z = task.first
                val x = task.second
                val y = task.third
                fetchOsmTile(z, x, y)
                count++
                val percent = if (total > 0) (count * 100) / total else 100
                _downloadState.value = OfflineDownloadState(
                    isDownloading = true,
                    current = count,
                    total = total,
                    percent = percent,
                    statusMessage = "Đang tải Zoom $z: $count/$total mảnh ($percent%)"
                )
                delay(30L) // Polite request pacing
            }

            updateStorageStats()
            _downloadState.value = OfflineDownloadState(
                isDownloading = false,
                current = total,
                total = total,
                percent = 100,
                statusMessage = "Đã tải xong toàn bộ $total mảnh ngoại tuyến!"
            )
        }
    }

    fun clearOfflineStorage() {
        scope.launch {
            try {
                offlineDir?.deleteRecursively()
                offlineDir?.mkdirs()
                tileCache.evictAll()
                updateStorageStats()
                _downloadState.value = OfflineDownloadState(
                    isDownloading = false,
                    current = 0,
                    total = 0,
                    percent = 0,
                    statusMessage = "Đã xóa toàn bộ dữ liệu ngoại tuyến"
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error clearing offline storage: ${e.message}")
            }
        }
    }

    fun updateStorageStats() {
        scope.launch {
            val dir = offlineDir ?: return@launch
            var totalBytes = 0L
            var fileCount = 0
            dir.walkTopDown().forEach { file ->
                if (file.isFile) {
                    totalBytes += file.length()
                    fileCount++
                }
            }
            val mb = String.format("%.1f", totalBytes / (1024.0 * 1024.0))
            _storageSizeText.value = "$mb MB ($fileCount mảnh)"
        }
    }

    /**
     * Extracts dynamic top 16 original RGB colors directly from the tile pixels.
     */
    private fun extractDynamicPalette(pixels: IntArray, maxColors: Int = 16): IntArray {
        val hist = HashMap<Int, Int>()
        for (c in pixels) {
            val r = (Color.red(c) shr 4) shl 4
            val g = (Color.green(c) shr 4) shl 4
            val b = (Color.blue(c) shr 4) shl 4
            val q = (r shl 16) or (g shl 8) or b
            hist[q] = (hist[q] ?: 0) + 1
        }
        val sortedClusters = hist.entries.sortedByDescending { it.value }.map { it.key }
        val palette = IntArray(maxColors)
        for (i in 0 until maxColors) {
            palette[i] = if (i < sortedClusters.size) sortedClusters[i] else 0x000000
        }
        return palette
    }

    /**
     * Finds closest original color in the dynamic palette using Euclidean RGB distance.
     */
    private fun findClosestPaletteIndex(c: Int, palette: IntArray): Int {
        val r = Color.red(c)
        val g = Color.green(c)
        val b = Color.blue(c)
        var minDiff = Int.MAX_VALUE
        var bestIdx = 0
        for (i in palette.indices) {
            val pr = (palette[i] shr 16) and 0xFF
            val pg = (palette[i] shr 8) and 0xFF
            val pb = palette[i] and 0xFF
            val dr = r - pr
            val dg = g - pg
            val db = b - pb
            val dist = dr * dr + dg * dg + db * db
            if (dist < minDiff) {
                minDiff = dist
                bestIdx = i
                if (dist == 0) break
            }
        }
        return bestIdx
    }

    /**
     * Converts raw CartoDB Dark Matter tile pixels into crisp bright white & silver roads on pure AMOLED black.
     */
    private fun mapPixelToBrightContrast(c: Int): Int {
        val r = Color.red(c)
        val g = Color.green(c)
        val b = Color.blue(c)

        // 1. Water (Electric Cyan Blue)
        if (b > 40 && b > r + 15 && b > g) return 7
        // 2. Parks / Nature (Emerald Green)
        if (g > 35 && g > r + 10 && g > b + 6) return 8
        // 3. Highways / Primary Arteries (Bright Amber / Orange)
        if (r > 120 && g > 70 && b < 70) return 9

        // 4. Multi-level anti-aliased luminance grading (eliminates jaggies!)
        val luminance = (0.299 * r + 0.587 * g + 0.114 * b).toInt()

        return when {
            luminance > 110 -> 6  // Center of Road -> Pure Solid Bright White (#FFFFFF)
            luminance > 68  -> 5  // Inner Road Body -> Bright White Silver (#F3F4F6)
            luminance > 38  -> 4  // Anti-aliased Feather Edge -> Light Silver (#D1D5DB)
            luminance > 22  -> 3  // Soft Border Transition -> Slate (#8E8E93)
            luminance > 12  -> 1  // Buildings / Structures -> Dark Slate (#2C2C2E)
            else            -> 0  // Background Land -> Pure Black (#000000)
        }
    }
}
