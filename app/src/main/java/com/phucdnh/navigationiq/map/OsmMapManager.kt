package com.phucdnh.navigationiq.map

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.util.Log
import android.util.LruCache
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
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
    val rleData: List<Int>, // Sequence of [count1, colorIdx1, count2, colorIdx2, ...]
    val palette: List<Int>  // 16 RGB values (e.g. 0x000000, 0xFFFFFF, etc.)
)

object OsmMapManager {

    private const val TAG = "OsmMapManager"
    private const val TILE_SIZE = 256
    private const val MAP_DIMENSION = 180 // 180x180 px square on Garmin Venu Sq 2 (320x360 screen)
    private const val USER_AGENT = "NavigationIQ/1.0 (Android Garmin Relay)"

    // In-memory LRU cache for 256x256 OSM tiles
    private val tileCache = LruCache<String, Bitmap>(30)

    // 16-color dark-mode palette optimized for AMOLED Garmin display
    val DARK_PALETTE = intArrayOf(
        0x000000, // 0: Pure Black (Background / Empty)
        0x1C1C1E, // 1: Dark Slate (Blocks / Buildings)
        0x2C2C2E, // 2: Gray (Minor pathways)
        0x48484A, // 3: Medium Gray (Secondary roads)
        0x636366, // 4: Light Slate (Primary roads)
        0x8E8E93, // 5: Silver (Highways / Main streets)
        0xFFFFFF, // 6: Pure White (Freeways / Key labels)
        0x0A84FF, // 7: Cyan Blue (Water / Rivers)
        0x30D158, // 8: Emerald Green (Parks / Forests)
        0xFFD60A, // 9: Bright Amber (Selected route / Major artery)
        0xFF9F0A, // 10: Orange (Toll roads)
        0xFF453A, // 11: Crimson Red (Traffic / Danger)
        0xBF5AF2, // 12: Purple (POI)
        0x5AC8FA, // 13: Light Blue (Lakes)
        0x34C759, // 14: Grass
        0x1B382B  // 15: Deep Green
    )

    private var locationManager: LocationManager? = null
    private var lastKnownLocation: Location? = null

    fun initialize(context: Context) {
        try {
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

            for (tx in minTileX..maxTileX) {
                for (ty in minTileY..maxTileY) {
                    val tile = fetchOsmTile(zoom, tx, ty)
                    if (tile != null) {
                        val drawLeft = (tx * TILE_SIZE - minX).toFloat()
                        val drawTop = (ty * TILE_SIZE - minY).toFloat()
                        canvas.drawBitmap(tile, drawLeft, drawTop, null)
                    }
                }
            }

            // 3. Process into AMOLED Dark Mode and Quantize to 16 Palette Colors
            val pixels = IntArray(MAP_DIMENSION * MAP_DIMENSION)
            viewportBitmap.getPixels(pixels, 0, MAP_DIMENSION, 0, 0, MAP_DIMENSION, MAP_DIMENSION)
            viewportBitmap.recycle()

            val indexedPixels = IntArray(pixels.size)
            for (i in pixels.indices) {
                val c = pixels[i]
                val r = Color.red(c)
                val g = Color.green(c)
                val b = Color.blue(c)
                indexedPixels[i] = mapRgbToDarkPaletteIndex(r, g, b)
            }

            // 4. Run-Length Encoding (RLE) Compression
            val rleList = mutableListOf<Int>()
            var currentIdx = indexedPixels[0]
            var count = 0

            for (idx in indexedPixels) {
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

            Log.d(TAG, "OSM Map compressed to ${rleList.size} RLE bytes for 180x180 viewport")

            OsmMapPacket(
                width = MAP_DIMENSION,
                height = MAP_DIMENSION,
                zoom = zoom,
                speedKmh = speedKmh,
                headingDeg = headingDeg,
                rleData = rleList,
                palette = DARK_PALETTE.toList()
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error generating OSM Map packet: ${e.message}", e)
            null
        }
    }

    private suspend fun fetchOsmTile(z: Int, x: Int, y: Int): Bitmap? = withContext(Dispatchers.IO) {
        val cacheKey = "$z/$x/$y"
        tileCache.get(cacheKey)?.let { return@withContext it }

        val tileUrl = "https://tile.openstreetmap.org/$z/$x/$y.png"
        var conn: HttpURLConnection? = null
        try {
            val url = URL(tileUrl)
            conn = url.openConnection() as HttpURLConnection
            conn.setRequestProperty("User-Agent", USER_AGENT)
            conn.connectTimeout = 4000
            conn.readTimeout = 4000
            conn.doInput = true
            conn.connect()

            if (conn.responseCode == 200) {
                val input: InputStream = conn.inputStream
                val bitmap = BitmapFactory.decodeStream(input)
                input.close()
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
     * Maps standard OSM tile RGB colors to a high-contrast AMOLED Dark Palette.
     */
    private fun mapRgbToDarkPaletteIndex(r: Int, g: Int, b: Int): Int {
        // Detect Water (Blue hues) -> Slate Blue (7)
        if (b > r + 20 && b > g) return 7
        // Detect Parks / Nature (Green hues) -> Deep Emerald (8 or 14)
        if (g > r + 15 && g > b + 15) return 8
        // Detect Highways / Primary Arteries (Orange / Red / Yellow) -> Bright Amber (9 or 10)
        if (r > 200 && g > 150 && b < 100) return 9
        if (r > 200 && g < 120 && b < 120) return 10

        // Invert light background / roads to dark mode
        val luminance = (0.299 * r + 0.587 * g + 0.114 * b).toInt()

        return when {
            luminance > 240 -> 6  // Major Road / Street -> Crisp White (6)
            luminance > 200 -> 5  // Regular Road -> Silver (5)
            luminance > 160 -> 4  // Secondary Pathway -> Light Slate (4)
            luminance > 120 -> 3  // Minor Road -> Medium Gray (3)
            luminance > 70  -> 1  // Building Outline -> Dark Slate (1)
            else            -> 0  // Pure Background -> Black (0)
        }
    }
}
