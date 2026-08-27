package com.phucdnh.navigationiq

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
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
import com.phucdnh.navigationiq.model.NavigationInfo
import com.phucdnh.navigationiq.service.NavNotificationService

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GarminManager.initSdk(this)
        setContent {
            MaterialTheme(
                colorScheme = darkColorScheme(
                    primary = Color(0xFF00E676),
                    background = Color(0xFF121212),
                    surface = Color(0xFF1E1E1E),
                    onSurface = Color.White
                )
            ) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    MainScreen()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        GarminManager.loadDevices(this)
    }
}

@Composable
fun MainScreen() {
    val context = LocalContext.current
    var isNotificationPermissionGranted by remember { mutableStateOf(isNotificationServiceEnabled(context)) }
    val currentNavInfo by NavNotificationService.currentNavigationInfo.collectAsState()
    val isWatchFound by GarminManager.isWatchFoundFlow.collectAsState()
    val watchName by GarminManager.watchNameFlow.collectAsState()
    val sentCount by GarminManager.sentCountFlow.collectAsState()
    val logs by GarminManager.logsFlow.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = Icons.Default.Navigation,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(32.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = "Navigation IQ",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Text(
                    text = "Garmin Companion & Relay",
                    fontSize = 13.sp,
                    color = Color.Gray
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Card 1: Notification Permission Status
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(modifier = Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = if (isNotificationPermissionGranted) Icons.Default.CheckCircle else Icons.Default.Warning,
                        contentDescription = null,
                        tint = if (isNotificationPermissionGranted) Color(0xFF00E676) else Color(0xFFFFB300)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = if (isNotificationPermissionGranted) "Quyền thông báo: ĐÃ CẤP" else "Chưa cấp quyền thông báo",
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "App cần quyền đọc thông báo để bắt dữ liệu chỉ đường từ Google Maps và OsmAnd.",
                    fontSize = 13.sp,
                    color = Color.LightGray
                )
                if (!isNotificationPermissionGranted) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Button(
                        onClick = {
                            context.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Text(text = "Cấp quyền ngay", color = Color.Black, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Card 2: Garmin Device Status
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
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
                            tint = MaterialTheme.colorScheme.primary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Đồng hồ Garmin (Venu Sq 2)",
                            fontWeight = FontWeight.SemiBold,
                            color = Color.White
                        )
                    }
                    if (sentCount > 0) {
                        Text(
                            text = "Đã gửi: $sentCount gói",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                val displayName = watchName ?: "Chưa phát hiện thiết bị"
                Text(
                    text = "Thiết bị kết nối: $displayName",
                    fontSize = 14.sp,
                    color = if (isWatchFound) Color(0xFF00E676) else Color.Gray
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Card 3: Live Navigation Preview
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                val nav = currentNavInfo
                if (nav != null && nav.hasDirections()) {
                    Text(
                        text = "ĐANG ĐIỀU HƯỚNG TRỰC TIẾP",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.height(16.dp))

                    nav.bitmap?.let { bmp ->
                        Image(
                            bitmap = bmp.asImageBitmap(),
                            contentDescription = "Mũi tên chỉ đường",
                            modifier = Modifier.size(80.dp)
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                    }

                    Text(
                        text = nav.distance.ifEmpty { "--" },
                        fontSize = 32.sp,
                        fontWeight = FontWeight.ExtraBold,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = nav.signs.ifEmpty { "Đang chuẩn bị lộ trình..." },
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Medium,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Text(text = "ETA: ${nav.eta}", fontSize = 14.sp, color = Color.Gray)
                        Text(text = "Thời lượng: ${nav.duration}", fontSize = 14.sp, color = Color.Gray)
                        Text(text = "Còn lại: ${nav.length}", fontSize = 14.sp, color = Color.Gray)
                    }
                } else {
                    Icon(
                        imageVector = Icons.Default.Navigation,
                        contentDescription = null,
                        tint = Color.DarkGray,
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = "Chưa có chỉ đường nào đang chạy",
                        fontWeight = FontWeight.Medium,
                        color = Color.Gray
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Hãy mở Google Maps trên điện thoại và bấm Bắt đầu chỉ đường",
                        fontSize = 12.sp,
                        color = Color.DarkGray
                    )
                    Spacer(modifier = Modifier.height(16.dp))
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
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Text(text = "Gửi thử chỉ đường sang Garmin", color = Color.Black, fontWeight = FontWeight.Bold)
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Card 4: Live Send Log
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF0D0D0D))
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
                        color = Color(0xFF00E676)
                    )
                    Text(
                        text = "${logs.size} entries",
                        fontSize = 11.sp,
                        color = Color.DarkGray
                    )
                }
                Spacer(modifier = Modifier.height(6.dp))
                if (logs.isEmpty()) {
                    Text(text = "Chưa có log nào...", fontSize = 11.sp, color = Color.DarkGray)
                } else {
                    LazyColumn(modifier = Modifier.fillMaxSize()) {
                        items(logs) { entry ->
                            val color = when {
                                entry.contains("[SEND]") -> Color(0xFF00E676)
                                entry.contains("[FAIL]") || entry.contains("[ERR]") -> Color(0xFFFF5252)
                                entry.contains("[WARN]") -> Color(0xFFFFB300)
                                entry.contains("[RECV") -> Color(0xFF40C4FF)
                                else -> Color(0xFF666666)
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