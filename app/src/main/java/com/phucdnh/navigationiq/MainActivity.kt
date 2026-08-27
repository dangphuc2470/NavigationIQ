package com.phucdnh.navigationiq

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Download
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Navigation
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Watch
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucdnh.navigationiq.garmin.GarminManager
import com.phucdnh.navigationiq.map.OsmMapManager
import com.phucdnh.navigationiq.model.NavigationInfo
import com.phucdnh.navigationiq.service.NavNotificationService

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GarminManager.initSdk(this)
        OsmMapManager.initialize(this)
        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme(
                    primary = Color(0xFF0A84FF),
                    background = Color(0xFF000000),
                    surface = Color(0xFF1C1C1E),
                    onSurface = Color.White
                )
            ) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color(0xFF000000)
                ) {
                    MainScreen()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        GarminManager.loadDevices(this)
        OsmMapManager.updateStorageStats()
    }
}

@Composable
fun MainScreen() {
    val context = LocalContext.current
    var isNotificationPermissionGranted by remember { mutableStateOf(isNotificationServiceEnabled(context)) }
    val currentNavInfo by NavNotificationService.currentNavigationInfo.collectAsState()
    val isHeartbeatLive by GarminManager.isHeartbeatLiveFlow.collectAsState()
    val watchName by GarminManager.watchNameFlow.collectAsState()
    val sentCount by GarminManager.sentCountFlow.collectAsState()
    val logs by GarminManager.logsFlow.collectAsState()

    val downloadState by OsmMapManager.downloadStateFlow.collectAsState()
    val storageSizeText by OsmMapManager.storageSizeTextFlow.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Header (WatchOS Clean Modern Style)
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .background(Color(0xFF0A84FF).copy(alpha = 0.15f), shape = RoundedCornerShape(22.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Navigation,
                    contentDescription = null,
                    tint = Color(0xFF0A84FF),
                    modifier = Modifier.size(24.dp)
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = "Navigation IQ",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Text(
                    text = "Garmin Companion & Offline OSM Relay",
                    fontSize = 12.sp,
                    color = Color(0xFF8E8E93)
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Card 1: Notification Permission Status (WatchOS Style)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1C1C1E)),
            border = BorderStroke(1.dp, Color(0xFF2C2C2E))
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = if (isNotificationPermissionGranted) Icons.Default.CheckCircle else Icons.Default.Warning,
                        contentDescription = null,
                        tint = if (isNotificationPermissionGranted) Color(0xFF30D158) else Color(0xFFFF9F0A),
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = if (isNotificationPermissionGranted) "Quyền thông báo: ĐÃ BẬT" else "Chưa cấp quyền đọc thông báo",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp,
                        color = Color.White
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = "App bắt dữ liệu rẽ/ETA từ Google Maps & OsmAnd để chuyển tiếp tức thì sang Garmin.",
                    fontSize = 12.sp,
                    color = Color(0xFF8E8E93)
                )
                if (!isNotificationPermissionGranted) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Button(
                        onClick = {
                            context.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        },
                        shape = RoundedCornerShape(50),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0A84FF))
                    ) {
                        Text(text = "Cấp quyền ngay", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 13.sp)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Card 2: Garmin Device Status (WatchOS Pill Style)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1C1C1E)),
            border = BorderStroke(1.dp, Color(0xFF2C2C2E))
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Watch,
                            contentDescription = null,
                            tint = Color(0xFF0A84FF),
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Garmin Venu Sq 2",
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp,
                            color = Color.White
                        )
                    }
                    if (sentCount > 0) {
                        Surface(
                            shape = RoundedCornerShape(50),
                            color = Color(0xFF0A84FF).copy(alpha = 0.15f)
                        ) {
                            Text(
                                text = "$sentCount gói",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF0A84FF),
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(6.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val dotColor = if (isHeartbeatLive) Color(0xFF30D158) else Color(0xFFFF9F0A)
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = dotColor,
                        modifier = Modifier.size(8.dp)
                    ) {}
                    Spacer(modifier = Modifier.width(8.dp))
                    val displayName = watchName ?: "Đang chờ kết nối Bluetooth..."
                    val statusLabel = if (isHeartbeatLive) "$displayName (Live Heartbeat)" else displayName
                    Text(
                        text = statusLabel,
                        fontSize = 13.sp,
                        color = if (isHeartbeatLive) Color(0xFF30D158) else Color(0xFF8E8E93)
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Card 3: Bản Đồ Ngoại Tuyến (Offline Maps - WatchOS Dark Style)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1C1C1E)),
            border = BorderStroke(1.dp, Color(0xFF2C2C2E))
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Map,
                            contentDescription = null,
                            tint = Color(0xFF0A84FF),
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Bản Đồ Ngoại Tuyến (OSM)",
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp,
                            color = Color.White
                        )
                    }
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = Color(0xFF30D158).copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = storageSizeText,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF30D158),
                            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "Tải trước mọi mức Zoom (14 - 17) xung quanh vị trí GPS để dùng ngay cả khi không có 4G.",
                    fontSize = 12.sp,
                    color = Color(0xFF8E8E93)
                )

                if (downloadState.isDownloading) {
                    Spacer(modifier = Modifier.height(12.dp))
                    LinearProgressIndicator(
                        progress = { downloadState.percent / 100f },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(6.dp),
                        color = Color(0xFF0A84FF),
                        trackColor = Color(0xFF2C2C2E)
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = downloadState.statusMessage,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFF0A84FF)
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Button(
                        onClick = {
                            OsmMapManager.startOfflineDownload(radiusKm = 5.0)
                        },
                        enabled = !downloadState.isDownloading,
                        shape = RoundedCornerShape(50),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFF0A84FF),
                            disabledContainerColor = Color(0xFF2C2C2E)
                        ),
                        modifier = Modifier.weight(1f)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Download,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (downloadState.isDownloading) "Đang tải..." else "Tải vùng này (5km)",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }

                    OutlinedButton(
                        onClick = {
                            OsmMapManager.clearOfflineStorage()
                        },
                        enabled = !downloadState.isDownloading,
                        shape = RoundedCornerShape(50),
                        border = BorderStroke(1.dp, Color(0xFF3A3A3C)),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color(0xFFFF453A))
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Card 4: Live Navigation Preview (WatchOS Aesthetics)
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF1C1C1E)),
            border = BorderStroke(1.dp, Color(0xFF2C2C2E))
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                val nav = currentNavInfo
                if (nav != null && nav.hasDirections()) {
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = Color(0xFF30D158).copy(alpha = 0.15f)
                    ) {
                        Text(
                            text = "ĐANG ĐIỀU HƯỚNG TRỰC TIẾP",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF30D158),
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(12.dp))

                    nav.bitmap?.let { bmp ->
                        Image(
                            bitmap = bmp.asImageBitmap(),
                            contentDescription = "Mũi tên chỉ đường",
                            modifier = Modifier.size(64.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                    }

                    Text(
                        text = nav.distance.ifEmpty { "--" },
                        fontSize = 28.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = nav.signs.ifEmpty { "Đang chuẩn bị lộ trình..." },
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text(text = "ETA: ${nav.eta}", fontSize = 12.sp, color = Color(0xFF8E8E93))
                        Text(text = "Thời lượng: ${nav.duration}", fontSize = 12.sp, color = Color(0xFF8E8E93))
                        Text(text = "Còn lại: ${nav.length}", fontSize = 12.sp, color = Color(0xFF8E8E93))
                    }
                } else {
                    Text(
                        text = "Chưa có chỉ đường nào đang chạy",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color(0xFF8E8E93)
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = "Mở Google Maps trên điện thoại để bắt đầu chỉ đường",
                        fontSize = 11.sp,
                        color = Color(0xFF636366)
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Button(
                        onClick = {
                            val mockInfo = NavigationInfo(
                                units = "m",
                                eta = "12:30",
                                length = "5.2 km",
                                duration = "15 phút",
                                distance = "250 m",
                                signs = "Rẽ trái vào đường Lê Lợi"
                            )
                            GarminManager.sendNavigationInfo(context, mockInfo)
                        },
                        shape = RoundedCornerShape(50),
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0A84FF))
                    ) {
                        Text(text = "Gửi thử chỉ đường sang Garmin", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Card 5: Live Send Log
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp),
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF141416)),
            border = BorderStroke(1.dp, Color(0xFF2C2C2E))
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "Live Log",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF0A84FF)
                    )
                    Text(
                        text = "${logs.size} entries",
                        fontSize = 11.sp,
                        color = Color(0xFF636366)
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                if (logs.isEmpty()) {
                    Text(text = "Chưa có log nào...", fontSize = 11.sp, color = Color(0xFF636366))
                } else {
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        items(logs) { entry ->
                            val color = when {
                                entry.contains("[SEND]") || entry.contains("[MAP]") -> Color(0xFF30D158)
                                entry.contains("[FAIL]") || entry.contains("[ERR]") -> Color(0xFFFF453A)
                                entry.contains("[WARN]") -> Color(0xFFFF9F0A)
                                entry.contains("[RECV") -> Color(0xFF0A84FF)
                                else -> Color(0xFF8E8E93)
                            }
                            Text(
                                text = entry,
                                fontSize = 10.sp,
                                color = color,
                                fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace,
                                modifier = Modifier.padding(vertical = 1.dp)
                            )
                        }
                    }
                }
            }
        }
    }
}

fun isNotificationServiceEnabled(context: Context): Boolean {
    val pkgName = context.packageName
    val flat = Settings.Secure.getString(context.contentResolver, "enabled_notification_listeners")
    if (!TextUtils.isEmpty(flat)) {
        val names = flat.split(":")
        for (name in names) {
            val cn = ComponentName.unflattenFromString(name)
            if (cn != null && TextUtils.equals(pkgName, cn.packageName)) {
                return true
            }
        }
    }
    return false
}