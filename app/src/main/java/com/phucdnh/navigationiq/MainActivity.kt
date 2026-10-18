package com.phucdnh.navigationiq

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsDraggedAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.GenericShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.input.pointer.pointerInput
import kotlin.math.roundToInt
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.filled.Message
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.BatteryChargingFull
import androidx.compose.material.icons.filled.BluetoothConnected
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.DirectionsCar
import androidx.compose.material.icons.filled.FormatSize
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.Map
import androidx.compose.material.icons.filled.Navigation
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.PersonOutline
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.Route
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.TurnRight
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material.icons.filled.Watch
import androidx.compose.material.icons.filled.WifiTethering
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.phucdnh.navigationiq.garmin.GarminManager
import com.phucdnh.navigationiq.model.NavigationInfo
import com.phucdnh.navigationiq.service.NavNotificationService
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

// =============================================================================
// Material You Expressive palette (legacy token names retained for existing screens)
// =============================================================================
val IosBg = Color(0xFFF2F2F7)
val IosCard = Color(0xFFFFFFFF)
val IosBorder = Color(0xFFE5E5EA)
val IosTextPrimary = Color(0xFF1D1D1F)
val IosTextSecondary = Color(0xFF86868B)
val IosTextTertiary = Color(0xFFAEAEB2)
val IosBlue = Color(0xFF007AFF)
val IosGreen = Color(0xFF34C759)
val IosOrange = Color(0xFFFF9500)
val IosRed = Color(0xFFFF3B30)
val IosIndigo = Color(0xFF5856D6)
val IosTeal = Color(0xFF30B0C7)
val IosPillBg = Color(0xFFE5E5EA)

@Immutable
data class AppleThemePalette(
    val isDark: Boolean,
    val bg: Color,
    val card: Color,
    val cardSubtle: Color,
    val separator: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val pillTrack: Color,
    val pillThumb: Color,
    val blue: Color,
    val green: Color,
    val orange: Color,
    val red: Color,
    val indigo: Color,
    val glassFillTop: Color,
    val glassFillBottom: Color,
    val glassBorderLit: Color,
    val glassBorderShadow: Color,
    val glassShadowColor: Color
)

val LightApplePalette = AppleThemePalette(
    false, Color(0xFFFAF8EF), Color(0xFFFFFDF6), Color(0xFFEDF2E3),
    Color(0xFFD9DFD0), Color(0xFF10251A), Color(0xFF606960), Color(0xFF7A8377),
    Color(0xFFE6EEDB), Color(0xFF194F36), Color(0xFF194F36), Color(0xFF28734B),
    Color(0xFFEE8E28), Color(0xFFBA3B30), Color(0xFF476341),
    Color(0xFFEAF1DF), Color(0xFFEAF1DF), Color.Transparent, Color.Transparent, Color.Transparent
)
val DarkApplePalette = AppleThemePalette(
    true, Color(0xFF111810), Color(0xFF1B241A), Color(0xFF263323),
    Color(0xFF3C4836), Color(0xFFE7EEDC), Color(0xFFB7C4AE), Color(0xFF91A187),
    Color(0xFF303E2A), Color(0xFFB8D8A4), Color(0xFFB8D8A4), Color(0xFFADD39D),
    Color(0xFFFFB877), Color(0xFFFFB4A9), Color(0xFFBCD2AB),
    Color(0xFF263323), Color(0xFF263323), Color.Transparent, Color.Transparent, Color.Transparent
)

val LocalApplePalette = staticCompositionLocalOf { LightApplePalette }

// =============================================================================
// Language Configuration (English as default)
// =============================================================================
enum class AppLanguage(val code: String, val displayName: String) {
    EN("en", "English"),
    VI("vi", "Tiếng Việt")
}

val LocalAppLanguage = staticCompositionLocalOf { AppLanguage.EN }

// =============================================================================
// Navigation Page Definitions
// =============================================================================
enum class AppPage(
    val titleEn: String,
    val titleVi: String,
    val headerTitleEn: String,
    val headerTitleVi: String,
    val headerSubtitleEn: String,
    val headerSubtitleVi: String,
    val icon: ImageVector
) {
    COCKPIT(
        titleEn = "Navigation",
        titleVi = "Điều hướng",
        headerTitleEn = "Navigation",
        headerTitleVi = "Điều hướng",
        headerSubtitleEn = "Turn-by-turn HUD & route simulation",
        headerSubtitleVi = "Trung tâm chỉ đường & Mô phỏng lộ trình",
        icon = Icons.Default.Navigation
    ),
    WATCH_STUDIO(
        titleEn = "Watch",
        titleVi = "Đồng hồ",
        headerTitleEn = "Watch Studio",
        headerTitleVi = "Watch Studio",
        headerSubtitleEn = "Watch face layout & typography",
        headerSubtitleVi = "Tùy biến mặt đồng hồ & Cỡ chữ Garmin",
        icon = Icons.Default.Watch
    ),
    SYSTEM(
        titleEn = "Settings",
        titleVi = "Hệ thống",
        headerTitleEn = "System",
        headerTitleVi = "Hệ thống",
        headerSubtitleEn = "Connect IQ device & background runtime",
        headerSubtitleVi = "Kết nối Connect IQ & Quyền chạy nền",
        icon = Icons.Default.Settings
    ),
    CONSOLE(
        titleEn = "Logs",
        titleVi = "Nhật ký",
        headerTitleEn = "Console Logs",
        headerTitleVi = "Nhật ký",
        headerSubtitleEn = "Real-time Bluetooth packet telemetry",
        headerSubtitleVi = "Luồng gói tin Bluetooth thời gian thực",
        icon = Icons.Default.Code
    );

    fun title(isVi: Boolean) = if (isVi) titleVi else titleEn
    fun headerTitle(isVi: Boolean) = if (isVi) headerTitleVi else headerTitleEn
    fun headerSubtitle(isVi: Boolean) = if (isVi) headerSubtitleVi else headerSubtitleEn
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        GarminManager.initSdk(this)
        setContent {
            MainScreen()
        }
    }

    override fun onResume() {
        super.onResume()
        GarminManager.loadDevices(this)
    }
}

// =============================================================================
// Root Apple Liquid Glass Scaffold & Page Host
// =============================================================================
@Composable
fun MainScreen() {
    val context = LocalContext.current
    val sharedPrefs = remember { context.getSharedPreferences("navigation_iq_prefs", Context.MODE_PRIVATE) }
    var isDarkTheme by remember { mutableStateOf(sharedPrefs.getBoolean("apple_dark_mode", false)) }
    val palette = if (isDarkTheme) DarkApplePalette else LightApplePalette

    val savedLangCode = remember { sharedPrefs.getString("app_language", "en") ?: "en" }
    var currentLanguage by remember { mutableStateOf(if (savedLangCode == "vi") AppLanguage.VI else AppLanguage.EN) }
    val isVi = currentLanguage == AppLanguage.VI

    var activePage by remember { mutableStateOf(AppPage.COCKPIT) }
    val pagerState = rememberPagerState(
        initialPage = activePage.ordinal,
        pageCount = { AppPage.entries.size }
    )
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(pagerState.currentPage) {
        activePage = AppPage.entries[pagerState.currentPage]
    }

    val navigateToPage: (AppPage) -> Unit = { targetPage ->
        activePage = targetPage
        coroutineScope.launch {
            pagerState.animateScrollToPage(targetPage.ordinal)
        }
    }
    var isNotificationPermissionGranted by remember { mutableStateOf(isNotificationServiceEnabled(context)) }
    var isBatteryOptIgnored by remember { mutableStateOf(isBatteryOptimizationIgnored(context)) }

    val lifecycleOwner = LocalLifecycleOwner.current
    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_RESUME) {
                isNotificationPermissionGranted = isNotificationServiceEnabled(context)
                isBatteryOptIgnored = isBatteryOptimizationIgnored(context)
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
        }
    }

    val currentNavInfo by NavNotificationService.currentNavigationInfo.collectAsState()
    val isHeartbeatLive by GarminManager.isHeartbeatLiveFlow.collectAsState()
    val isWatchFound by GarminManager.isWatchFoundFlow.collectAsState()
    val watchName by GarminManager.watchNameFlow.collectAsState()
    val sentCount by GarminManager.sentCountFlow.collectAsState()
    val logs by GarminManager.logsFlow.collectAsState()

    var simulatedNavInfo by remember { mutableStateOf<NavigationInfo?>(null) }
    val effectiveNavInfo = currentNavInfo?.takeIf { it.hasDirections() } ?: simulatedNavInfo

    CompositionLocalProvider(
        LocalApplePalette provides palette,
        LocalAppLanguage provides currentLanguage
    ) {
        MaterialTheme(
            colorScheme = if (isDarkTheme) {
                darkColorScheme(
                    primary = palette.blue,
                    background = palette.bg,
                    surface = palette.card,
                    onSurface = palette.textPrimary
                )
            } else {
                lightColorScheme(
                    primary = palette.blue,
                    background = palette.bg,
                    surface = palette.card,
                    onSurface = palette.textPrimary
                )
            }
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(palette.bg)
            ) {
                Column(modifier = Modifier.fillMaxSize()) {
                    // 1. TOP NAVIGATION HEADER
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(palette.bg)
                            .statusBarsPadding()
                            .padding(start = 18.dp, end = 18.dp, top = 8.dp, bottom = 10.dp)
                    ) {
                        AppleFloatingHeader(
                            page = activePage,
                            watchName = watchName,
                            isHeartbeatLive = isHeartbeatLive,
                            isDarkTheme = isDarkTheme,
                            isVi = isVi,
                            onRefreshWatch = {
                                GarminManager.loadDevices(context)
                                GarminManager.sendPing()
                            },
                            onOpenSettings = { navigateToPage(AppPage.SYSTEM) },
                            onToggleTheme = {
                                val next = !isDarkTheme
                                isDarkTheme = next
                                sharedPrefs.edit().putBoolean("apple_dark_mode", next).apply()
                            }
                        )
                    }

                    // 2. UNDERLYING CONTENT LAYER (SWIPEABLE HORIZONTAL PAGER)
                    HorizontalPager(
                        state = pagerState,
                        modifier = Modifier
                            .fillMaxWidth()
                            .weight(1f)
                    ) { pageIndex ->
                        when (AppPage.entries[pageIndex]) {
                            AppPage.COCKPIT -> CockpitPage(
                                effectiveNavInfo = effectiveNavInfo,
                                isLiveFromMaps = currentNavInfo?.hasDirections() == true,
                                isHeartbeatLive = isHeartbeatLive,
                                isWatchFound = isWatchFound,
                                watchName = watchName,
                                sentCount = sentCount,
                                isNotificationGranted = isNotificationPermissionGranted,
                                isBatteryOptIgnored = isBatteryOptIgnored,
                                isVi = isVi,
                                onSendSimulation = { mock ->
                                    simulatedNavInfo = mock
                                    GarminManager.sendNavigationInfo(context, mock)
                                },
                                onClearSimulation = {
                                    simulatedNavInfo = null
                                    GarminManager.sendNavigationEnd(context)
                                },
                                onNavigateToSystem = { navigateToPage(AppPage.SYSTEM) },
                                onNavigateToWatchStudio = { navigateToPage(AppPage.WATCH_STUDIO) }
                            )

                            AppPage.WATCH_STUDIO -> WatchStudioPage(
                                previewNavInfo = effectiveNavInfo,
                                isVi = isVi
                            )

                            AppPage.SYSTEM -> SystemSettingsPage(
                                isNotificationGranted = isNotificationPermissionGranted,
                                isBatteryOptIgnored = isBatteryOptIgnored,
                                isWatchFound = isWatchFound,
                                isHeartbeatLive = isHeartbeatLive,
                                watchName = watchName,
                                sentCount = sentCount,
                                currentLanguage = currentLanguage,
                                isVi = isVi,
                                onSelectLanguage = { lang ->
                                    currentLanguage = lang
                                    sharedPrefs.edit().putString("app_language", lang.code).apply()
                                }
                            )

                            AppPage.CONSOLE -> ConsoleLogPage(
                                logs = logs,
                                sentCount = sentCount,
                                isHeartbeatLive = isHeartbeatLive,
                                isVi = isVi
                            )
                        }
                    }
                }

                // 3. INSET FLOATING LIQUID GLASS TAB BAR
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .align(Alignment.BottomCenter)
                        .background(
                            Brush.verticalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    palette.bg.copy(alpha = 0.88f),
                                    palette.bg
                                )
                            )
                        )
                        .navigationBarsPadding()
                        .padding(horizontal = 4.dp, vertical = 0.dp)
                ) {
                    AppleFloatingBottomBar(
                        activePage = activePage,
                        pagerPosition = pagerState.currentPage + pagerState.currentPageOffsetFraction,
                        isPagerDragging = pagerState.interactionSource.collectIsDraggedAsState().value,
                        hasActiveNavigation = effectiveNavInfo != null,
                        isVi = isVi,
                        onSelectPage = navigateToPage,
                        onQuickAction = {
                            if (effectiveNavInfo != null) {
                                simulatedNavInfo = null
                                GarminManager.sendNavigationEnd(context)
                            } else {
                                val quickMock = NavigationInfo(
                                    isPublicTransport = true,
                                    units = "km",
                                    eta = "17:45",
                                    length = "4.6 km",
                                    duration = "12 min",
                                    distance = "350 m",
                                    signs = if (isVi) "Rẽ phải vào đường Nguyễn Huệ" else "Turn right onto Main Street",
                                    progress = 42
                                )
                                simulatedNavInfo = quickMock
                                GarminManager.sendNavigationInfo(context, quickMock)
                            }
                        }
                    )
                }
            }
        }
    }
}

// =============================================================================
// Liquid Glass Floating Components (Strictly for Navigation Layer)
// =============================================================================
@Composable
fun LiquidGlassSurface(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 999.dp,
    contentPadding: PaddingValues = PaddingValues(horizontal = 14.dp, vertical = 8.dp),
    content: @Composable RowScope.() -> Unit
) {
    val palette = LocalApplePalette.current
    val shape = RoundedCornerShape(cornerRadius)

    Row(
        modifier = modifier
            .shadow(
                elevation = 18.dp,
                shape = shape,
                ambientColor = palette.glassShadowColor,
                spotColor = palette.glassShadowColor
            )
            .clip(shape)
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(palette.glassFillTop, palette.glassFillBottom)
                ),
                shape = shape
            )
            .border(
                width = 0.8.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(palette.glassBorderLit, palette.glassBorderShadow)
                ),
                shape = shape
            )
            .padding(contentPadding),
        verticalAlignment = Alignment.CenterVertically,
        content = content
    )
}

@Composable
fun LiquidGlassCircleButton(
    icon: ImageVector,
    contentDescription: String?,
    tint: Color = LocalApplePalette.current.textPrimary,
    size: Dp = 42.dp,
    onClick: () -> Unit
) {
    val palette = LocalApplePalette.current
    val interactionSource = remember { MutableInteractionSource() }
    val isPressed by interactionSource.collectIsPressedAsState()
    val scale by animateFloatAsState(
        targetValue = if (isPressed) 0.92f else 1f,
        animationSpec = spring(stiffness = Spring.StiffnessMediumLow),
        label = "glass_btn_scale"
    )

    Box(
        modifier = Modifier
            .scale(scale)
            .size(size)
            .shadow(
                elevation = 12.dp,
                shape = CircleShape,
                ambientColor = palette.glassShadowColor,
                spotColor = palette.glassShadowColor
            )
            .clip(CircleShape)
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(palette.glassFillTop, palette.glassFillBottom)
                ),
                shape = CircleShape
            )
            .border(
                width = 0.8.dp,
                brush = Brush.verticalGradient(
                    colors = listOf(palette.glassBorderLit, palette.glassBorderShadow)
                ),
                shape = CircleShape
            )
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = contentDescription,
            tint = tint,
            modifier = Modifier.size(20.dp)
        )
    }
}

@Composable
fun AppleFloatingHeader(
    page: AppPage,
    watchName: String?,
    isHeartbeatLive: Boolean,
    isDarkTheme: Boolean,
    isVi: Boolean,
    onRefreshWatch: () -> Unit,
    onOpenSettings: () -> Unit,
    onToggleTheme: () -> Unit
) {
    val palette = LocalApplePalette.current
    var menu by remember { mutableStateOf(false) }
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text("WATCH COMPANION", fontSize = 9.sp, letterSpacing = 3.sp,
                fontWeight = FontWeight.Bold, color = palette.blue)
            Text(page.headerTitle(isVi), fontSize = 34.sp, lineHeight = 40.sp,
                fontWeight = FontWeight.ExtraBold, color = palette.textPrimary)
        }
        Box {
            FilledTonalIconButton(onClick = { menu = true },
                colors = IconButtonDefaults.filledTonalIconButtonColors(containerColor = palette.pillTrack, contentColor = palette.blue)) {
                Icon(Icons.Default.PersonOutline, contentDescription = if (isVi) "Tùy chọn" else "Options")
            }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(text = { Text(if (isVi) "Cài đặt" else "Settings") }, onClick = { menu = false; onOpenSettings() })
                DropdownMenuItem(text = { Text(if (isVi) "Quét lại đồng hồ" else "Rescan watch") }, onClick = { menu = false; onRefreshWatch() })
                DropdownMenuItem(text = { Text(if (isVi) "Đổi sáng / tối" else "Toggle light / dark") }, onClick = { menu = false; onToggleTheme() })
            }
        }
    }
}

@Composable
fun AppleFloatingBottomBar(
    activePage: AppPage,
    pagerPosition: Float,
    isPagerDragging: Boolean,
    hasActiveNavigation: Boolean,
    isVi: Boolean,
    onSelectPage: (AppPage) -> Unit,
    onQuickAction: () -> Unit
) {
    val palette = LocalApplePalette.current
    val pages = AppPage.entries
    val pageCount = pages.size

    val coroutineScope = rememberCoroutineScope()
    val indicatorOffset = remember { Animatable(activePage.ordinal.toFloat()) }
    var isBarDragging by remember { mutableStateOf(false) }

    // Chỉ đồng bộ real-time với pagerPosition khi người dùng ĐANG THỰC SỰ VUỐT TRÊN MÀN HÌNH NỘI DUNG
    LaunchedEffect(pagerPosition, isPagerDragging) {
        if (!isBarDragging && isPagerDragging) {
            indicatorOffset.snapTo(pagerPosition.coerceIn(0f, (pageCount - 1).toFloat()))
        }
    }

    // Khi activePage đổi từ bên ngoài (như Header menu) và không có cử chỉ vuốt nào đang diễn ra
    LaunchedEffect(activePage) {
        if (!isBarDragging && !isPagerDragging) {
            indicatorOffset.animateTo(
                targetValue = activePage.ordinal.toFloat(),
                animationSpec = spring(
                    dampingRatio = 0.85f,
                    stiffness = Spring.StiffnessMediumLow
                )
            )
        }
    }

    val currentPosition = indicatorOffset.value.coerceIn(0f, (pageCount - 1).toFloat())

    Surface(
        color = palette.card,
        shape = RoundedCornerShape(28.dp),
        border = BorderStroke(0.8.dp, palette.separator),
        shadowElevation = 8.dp
    ) {
        BoxWithConstraints(
            modifier = Modifier
                .fillMaxWidth()
                .padding(6.dp)
                .pointerInput(pageCount) {
                    val availableWidthPx = size.width.toFloat()
                    val tabWidthPx = availableWidthPx / pageCount.toFloat()
                    awaitEachGesture {
                        val down = awaitFirstDown(requireUnconsumed = false)
                        val downX = down.position.x
                        var isDrag = false
                        var lastX = downX

                        while (true) {
                            val event = awaitPointerEvent()
                            val change = event.changes.firstOrNull { it.id == down.id } ?: break
                            if (!change.pressed) {
                                // Thả ngón tay ra!
                                if (isDrag) {
                                    isBarDragging = false
                                    val targetIndex = (lastX / tabWidthPx).toInt().coerceIn(0, pageCount - 1)
                                    onSelectPage(pages[targetIndex])
                                    coroutineScope.launch {
                                        indicatorOffset.animateTo(
                                            targetValue = targetIndex.toFloat(),
                                            animationSpec = spring(
                                                dampingRatio = 0.85f,
                                                stiffness = Spring.StiffnessMediumLow
                                            )
                                        )
                                    }
                                } else {
                                    // Chạm nhẹ (Tap)
                                    val targetIndex = (downX / tabWidthPx).toInt().coerceIn(0, pageCount - 1)
                                    onSelectPage(pages[targetIndex])
                                    coroutineScope.launch {
                                        indicatorOffset.animateTo(
                                            targetValue = targetIndex.toFloat(),
                                            animationSpec = spring(
                                                dampingRatio = 0.85f,
                                                stiffness = Spring.StiffnessMediumLow
                                            )
                                        )
                                    }
                                }
                                break
                            } else {
                                val dx = kotlin.math.abs(change.position.x - downX)
                                if (dx > 8f || isDrag) {
                                    if (!isDrag) {
                                        isDrag = true
                                        isBarDragging = true
                                    }
                                    change.consume()
                                    lastX = change.position.x
                                    val rawProgress = ((lastX / tabWidthPx) - 0.5f).coerceIn(0f, (pageCount - 1).toFloat())
                                    coroutineScope.launch {
                                        indicatorOffset.snapTo(rawProgress)
                                    }
                                }
                            }
                        }
                    }
                }
        ) {
            val tabWidth = maxWidth / pageCount
            val pillOffset = tabWidth * currentPosition

            // 1. Sliding Pill Background
            Box(
                modifier = Modifier
                    .offset(x = pillOffset)
                    .width(tabWidth)
                    .height(52.dp)
                    .padding(horizontal = 2.dp)
                    .clip(RoundedCornerShape(26.dp))
                    .background(palette.blue)
            )

            // 2. Tab Items Layer
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                pages.forEachIndexed { index, page ->
                    val distance = kotlin.math.abs(currentPosition - index)
                    val activeFraction = (1f - distance).coerceIn(0f, 1f)
                    val activeColor = if (palette.isDark) palette.bg else Color.White
                    val inactiveColor = palette.textSecondary
                    val foreground = lerp(inactiveColor, activeColor, activeFraction)

                    Column(
                        modifier = Modifier
                            .weight(1f)
                            .padding(vertical = 4.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = page.icon,
                            contentDescription = null,
                            tint = foreground,
                            modifier = Modifier.size(24.dp)
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = page.title(isVi),
                            color = foreground,
                            fontSize = 10.sp,
                            fontWeight = if (activeFraction > 0.45f) FontWeight.Bold else FontWeight.Medium,
                            maxLines = 1
                        )
                    }
                }
            }
        }
    }
}

// =============================================================================
// PAGE 1: COCKPIT PAGE (Live Navigation & Quick Route Simulator)
// =============================================================================
private data class SimulatedRoutePreset(
    val labelEn: String,
    val labelVi: String,
    val subtitleEn: String,
    val subtitleVi: String,
    val distance: String,
    val signsEn: String,
    val signsVi: String,
    val eta: String,
    val duration: String,
    val length: String,
    val progress: Int
)

private val QuickSimulationPresets = listOf(
    SimulatedRoutePreset(
        labelEn = "City • Turn Right",
        labelVi = "Nội đô • Rẽ phải",
        subtitleEn = "Main Street (350 m)",
        subtitleVi = "Nguyễn Huệ (350 m)",
        distance = "350 m",
        signsEn = "Turn right onto Main Street",
        signsVi = "Rẽ phải vào đường Nguyễn Huệ",
        eta = "17:45",
        duration = "12 min",
        length = "4.6 km",
        progress = 45
    ),
    SimulatedRoutePreset(
        labelEn = "Highway • Straight",
        labelVi = "Cao tốc • Đi thẳng",
        subtitleEn = "Highway 1 (2.8 km)",
        subtitleVi = "Quốc lộ 1A (2.8 km)",
        distance = "2.8 km",
        signsEn = "Continue straight on Highway 1 towards City Center",
        signsVi = "Đi thẳng theo Quốc lộ 1A hướng Trung tâm",
        eta = "18:10",
        duration = "28 min",
        length = "19.4 km",
        progress = 68
    ),
    SimulatedRoutePreset(
        labelEn = "Roundabout • Exit 2",
        labelVi = "Vòng xuyến • Lối ra 2",
        subtitleEn = "Parkway (120 m)",
        subtitleVi = "Điện Biên Phủ (120 m)",
        distance = "120 m",
        signsEn = "At the roundabout, take the 2nd exit onto Parkway",
        signsVi = "Tại vòng xuyến, đi theo lối ra thứ 2 vào Điện Biên Phủ",
        eta = "17:38",
        duration = "6 min",
        length = "1.8 km",
        progress = 82
    )
)

@Composable
fun CockpitPage(
    effectiveNavInfo: NavigationInfo?,
    isLiveFromMaps: Boolean,
    isHeartbeatLive: Boolean,
    isWatchFound: Boolean,
    watchName: String?,
    sentCount: Int,
    isNotificationGranted: Boolean,
    isBatteryOptIgnored: Boolean,
    isVi: Boolean,
    onSendSimulation: (NavigationInfo) -> Unit,
    onClearSimulation: () -> Unit,
    onNavigateToSystem: () -> Unit,
    onNavigateToWatchStudio: () -> Unit
) {
    val context = LocalContext.current
    val p = LocalApplePalette.current
    var alerts by remember { mutableStateOf(false) }
    fun send(preset: SimulatedRoutePreset) {
        onSendSimulation(NavigationInfo(isPublicTransport = true, units = "km", eta = preset.eta,
            length = preset.length, duration = preset.duration, distance = preset.distance,
            signs = if (isVi) preset.signsVi else preset.signsEn, progress = preset.progress))
    }
    LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 4.dp, bottom = 112.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)) {
        if (!isNotificationGranted || !isBatteryOptIgnored) item {
            Surface(onClick = {
                if (!isNotificationGranted) context.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                else requestIgnoreBatteryOptimizations(context)
            }, color = if (p.isDark) Color(0xFF53331F) else Color(0xFFFFE5D0), shape = RoundedCornerShape(24.dp)) {
                Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Warning, null, tint = if (p.isDark) Color(0xFFFFB877) else Color(0xFFE7742E), modifier = Modifier.size(26.dp))
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(if (!isNotificationGranted) { if (isVi) "Cho phép đọc thông báo" else "Allow notification access" }
                            else { if (isVi) "Cho phép hoạt động nền" else "Allow background activity" }, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = p.textPrimary)
                        Text(if (isVi) "Giữ kết nối đồng hồ khi chạy nền." else "Keep your watch connected in the background.", fontSize = 11.sp, color = p.textSecondary)
                    }
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = p.orange)
                }
            }
        }
        item {
            ExpressivePanel(tonal = false, ornament = true) {
                Row(Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(72.dp).background(p.pillTrack, WatchBadgeShape), contentAlignment = Alignment.Center) {
                        Icon(Icons.Default.Watch, null, tint = p.blue, modifier = Modifier.size(38.dp))
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Text(watchName?.takeUnless { it.equals("Simulator", true) } ?: "Garmin Watch", fontSize = 18.sp, fontWeight = FontWeight.Bold, color = p.textPrimary)
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(8.dp).background(if (isHeartbeatLive) p.green else p.orange, CircleShape))
                            Spacer(Modifier.width(6.dp))
                            Text(when {
                                isHeartbeatLive -> if (isVi) "Đã kết nối" else "Connected"
                                isWatchFound -> if (isVi) "Chờ mở app đồng hồ" else "Waiting for watch app"
                                else -> if (isVi) "Chưa tìm thấy đồng hồ" else "No watch found"
                            }, fontSize = 12.sp, fontWeight = FontWeight.Medium, color = p.textPrimary)
                        }
                        Spacer(Modifier.height(4.dp))
                        Text(if (isHeartbeatLive) { if (isVi) "Đã gửi $sentCount gói tin." else "$sentCount packets sent." }
                            else if (isWatchFound) { if (isVi) "Mở app trên đồng hồ để kết nối." else "Open the app on your watch to connect." }
                            else { if (isVi) "Mở Garmin Connect để tìm thiết bị." else "Open Garmin Connect to find your watch." }, fontSize = 11.sp, color = p.textSecondary)
                    }
                }
                HorizontalDivider(Modifier.padding(horizontal = 16.dp), color = p.separator)
                Row(Modifier.fillMaxWidth().clickable(onClick = onNavigateToWatchStudio).padding(horizontal = 18.dp, vertical = 13.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Tune, null, tint = p.blue, modifier = Modifier.size(20.dp))
                    Text(if (isVi) "Tùy chỉnh HUD" else "Customize HUD", Modifier.weight(1f).padding(start = 14.dp), fontSize = 13.sp, fontWeight = FontWeight.Bold, color = p.textPrimary)
                    Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = p.blue)
                }
            }
        }
        item {
            ExpressivePanel(ornament = true) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(if (effectiveNavInfo == null) { if (isVi) "Sẵn sàng lên đường" else "Ready when you are" }
                        else { if (isLiveFromMaps) { if (isVi) "Đang dẫn đường" else "Live navigation" } else { if (isVi) "Đang mô phỏng" else "Route simulation" } },
                        fontSize = 23.sp, fontWeight = FontWeight.ExtraBold, color = p.textPrimary)
                    if (effectiveNavInfo != null) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            val bitmap = effectiveNavInfo.bitmap
                            if (bitmap != null) Image(bitmap.asImageBitmap(), "Turn direction", Modifier.size(48.dp))
                            else Icon(Icons.Default.TurnRight, null, tint = p.blue, modifier = Modifier.size(42.dp))
                            Column(Modifier.padding(start = 12.dp)) {
                                Text(effectiveNavInfo.distance, fontSize = 28.sp, fontWeight = FontWeight.Bold, color = p.textPrimary)
                                Text(effectiveNavInfo.signs, fontSize = 14.sp, color = p.textPrimary)
                            }
                        }
                        if (effectiveNavInfo.progress in 0..100) LinearProgressIndicator(progress = { effectiveNavInfo.progress / 100f }, modifier = Modifier.fillMaxWidth(), color = p.blue, trackColor = p.pillTrack)
                        Text("${effectiveNavInfo.eta}  ·  ${effectiveNavInfo.duration}  ·  ${effectiveNavInfo.length}", color = p.textSecondary, fontSize = 12.sp)
                        OutlinedButton(onClick = onClearSimulation, modifier = Modifier.fillMaxWidth(), border = BorderStroke(1.dp, p.blue)) {
                            Text(if (isVi) "Kết thúc chỉ đường" else "End navigation", color = p.blue)
                        }
                    } else {
                        Text(if (isVi) "Gửi chỉ đường thẳng đến cổ tay bạn." else "Send directions straight to your wrist.", fontSize = 13.sp, color = p.textSecondary)
                        Button(onClick = {
                            val launch = context.packageManager.getLaunchIntentForPackage("com.google.android.apps.maps")
                                ?: Intent(Intent.ACTION_VIEW, Uri.parse("https://maps.google.com"))
                            context.startActivity(launch)
                        }, modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp), shape = CircleShape,
                            colors = ButtonDefaults.buttonColors(containerColor = p.blue, contentColor = if (p.isDark) p.bg else Color.White)) {
                            Icon(Icons.Default.Navigation, null, modifier = Modifier.size(27.dp))
                            Spacer(Modifier.width(12.dp))
                            Text(if (isVi) "Mở Google Maps" else "Open Google Maps", fontWeight = FontWeight.Bold)
                        }
                        OutlinedButton(onClick = { send(QuickSimulationPresets.first()) }, modifier = Modifier.fillMaxWidth().heightIn(min = 40.dp), border = BorderStroke(1.dp, p.blue)) {
                            Icon(Icons.Default.PlayArrow, null, tint = p.blue, modifier = Modifier.size(20.dp))
                            Spacer(Modifier.width(8.dp))
                            Text(if (isVi) "Thử lộ trình" else "Test a route", color = p.blue, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
        item {
            ExpressivePanel {
                Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(if (isVi) "Mô phỏng" else "Simulator", Modifier.weight(1f), fontSize = 22.sp, fontWeight = FontWeight.ExtraBold, color = p.textPrimary)
                    Row(Modifier.background(p.pillTrack, CircleShape).padding(4.dp)) {
                        listOf(false, true).forEach { tab ->
                            Box(Modifier.clip(CircleShape).background(if (alerts == tab) p.blue else Color.Transparent)
                                .clickable { alerts = tab }.padding(horizontal = 16.dp, vertical = 9.dp)) {
                                Text(if (tab) { if (isVi) "Tin nhắn" else "Alerts" } else { if (isVi) "Lộ trình" else "Routes" },
                                    fontSize = 11.sp, fontWeight = FontWeight.Bold, color = if (alerts == tab) (if (p.isDark) p.bg else Color.White) else p.textSecondary)
                            }
                        }
                    }
                }
                if (alerts) {
                    ExpressiveRouteRow(Icons.AutoMirrored.Filled.Message, if (isVi) "Tin nhắn thử" else "Test chat alert",
                        if (isVi) "Biểu ngữ trên đồng hồ" else "Message banner on your watch") {
                        GarminManager.sendToastNotification(appName = "Chat", sender = "Alex", message = if (isVi) "Đang đến ngã tư!" else "Heading to the next crossroads now!", durationSec = 5)
                    }
                } else {
                    QuickSimulationPresets.forEachIndexed { index, preset ->
                        if (index > 0) HorizontalDivider(Modifier.padding(horizontal = 16.dp), color = p.separator)
                        ExpressiveRouteRow(if (index == 0) Icons.Default.TurnRight else if (index == 1) Icons.Default.ArrowUpward else Icons.Default.Route,
                            if (isVi) listOf("Nội đô", "Cao tốc", "Vòng xuyến")[index] else listOf("City route", "Highway route", "Roundabout")[index],
                            if (isVi) preset.subtitleVi else if (index == 0) "Turn right · Main Street" else if (index == 1) "Continue straight · ${preset.distance}" else preset.subtitleEn) { send(preset) }
                    }
                }
            }
        }
    }
}

private val WatchBadgeShape = GenericShape { size, _ ->
    val cx = size.width / 2; val cy = size.height / 2
    for (i in 0..120) {
        val angle = i * 2 * Math.PI / 120
        val radius = 0.46f + 0.035f * kotlin.math.cos(6 * angle).toFloat()
        val x = cx + size.width * radius * kotlin.math.cos(angle).toFloat()
        val y = cy + size.height * radius * kotlin.math.sin(angle).toFloat()
        if (i == 0) moveTo(x, y) else lineTo(x, y)
    }
    close()
}

@Composable
private fun ExpressivePanel(tonal: Boolean = false, ornament: Boolean = false, content: @Composable ColumnScope.() -> Unit) {
    val p = LocalApplePalette.current
    Box(Modifier.fillMaxWidth().clip(RoundedCornerShape(26.dp)).background(if (tonal) p.cardSubtle else p.card)) {
        if (ornament) androidx.compose.foundation.Canvas(Modifier.align(Alignment.TopEnd).size(100.dp, 66.dp)) {
            val path = androidx.compose.ui.graphics.Path().apply {
                moveTo(0f, 0f); lineTo(size.width, 0f); lineTo(size.width, size.height)
                cubicTo(size.width * .55f, size.height, size.width * .9f, size.height * .45f, size.width * .42f, size.height * .45f)
                cubicTo(size.width * .1f, size.height * .45f, size.width * .1f, size.height * .2f, 0f, 0f); close()
            }
            drawPath(path, if (p.isDark) Color(0xFF34482C) else Color(0xFFD7E4C6))
        }
        Column(Modifier.fillMaxWidth(), content = content)
    }
}

@Composable
private fun ExpressiveRouteRow(icon: ImageVector, title: String, subtitle: String, onClick: () -> Unit) {
    val p = LocalApplePalette.current
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 12.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(Modifier.size(46.dp).background(p.pillTrack, CircleShape), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = p.blue, modifier = Modifier.size(28.dp))
        }
        Column(Modifier.weight(1f).padding(horizontal = 12.dp)) {
            Text(title, fontSize = 15.sp, fontWeight = FontWeight.Bold, color = p.textPrimary)
            Text(subtitle, fontSize = 11.sp, color = p.textSecondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
        }
        Box(Modifier.size(40.dp).background(p.pillTrack, CircleShape), contentAlignment = Alignment.Center) {
            Icon(Icons.Default.PlayArrow, null, tint = p.blue, modifier = Modifier.size(22.dp))
        }
    }
}

@Composable
private fun TelemetryStatItem(
    label: String,
    value: String,
    valueColor: Color
) {
    val palette = LocalApplePalette.current
    Column {
        Text(
            text = label,
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold,
            color = palette.textSecondary
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = value,
            fontSize = 14.sp,
            fontWeight = FontWeight.Bold,
            color = valueColor
        )
    }
}

// =============================================================================
// PAGE 2: WATCH STUDIO PAGE (HUD Appearance, Layout Profile & Typography)
// =============================================================================
@Composable
fun WatchStudioPage(
    previewNavInfo: NavigationInfo?,
    isVi: Boolean
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .navigationBarsPadding(),
        contentPadding = PaddingValues(top = 6.dp, bottom = 112.dp, start = 16.dp, end = 16.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        item {
            WatchAppearanceCard(previewNavInfo = previewNavInfo, isVi = isVi)
        }
    }
}

// =============================================================================
// Watch Appearance Models & Presets
// =============================================================================
enum class WatchLayoutProfile(
    val id: Int,
    val titleEn: String,
    val titleVi: String,
    val subtitleEn: String,
    val subtitleVi: String
) {
    AUTO(0, "Auto", "Tự động", "Detect from device", "Nhận diện từ thiết bị"),
    RECT(1, "Square", "Square Watch", "Venu Sq, Venu 2 Sq, Venu X1", "Venu Sq, Venu 2 sq, Venu X1"),
    ROUND(2, "Round", "Tròn (Fenix)", "Sports round display", "Mặt tròn thể thao"),
    INSTINCT(3, "Instinct", "Instinct", "Monochrome / Rugged", "Đơn sắc / Gồ ghề");

    fun title(isVi: Boolean) = if (isVi) titleVi else titleEn
    fun subtitle(isVi: Boolean) = if (isVi) subtitleVi else subtitleEn
}

enum class WatchTextPreset(
    val id: Int,
    val titleEn: String,
    val titleVi: String,
    val descEn: String,
    val descVi: String,
    val distSp: Float,
    val streetSp: Float,
    val actionSp: Float
) {
    BALANCED(0, "Balanced", "Cân bằng", "Optimal proportions for most routes", "Tỷ lệ chuẩn tối ưu cho mọi cung đường", 34f, 14f, 15f),
    STREET_FOCUS(1, "Street Focus", "Ưu tiên tên đường", "Large street name, easy to glance while moving", "Chữ tên đường to rõ, dễ liếc khi chạy nhanh", 28f, 18f, 16f),
    DISTANCE_FOCUS(2, "Distance Focus", "Ưu tiên khoảng cách", "Huge distance digits, prominent from afar", "Số khoảng cách khổng lồ, nổi bật từ xa", 42f, 12f, 13f),
    LARGE_TEXT(3, "Large Text", "Chữ lớn toàn diện", "Maximum font size for distance and street", "Phóng to tối đa cả số và chữ cho mắt yếu", 38f, 16f, 17f);

    fun title(isVi: Boolean) = if (isVi) titleVi else titleEn
    fun description(isVi: Boolean) = if (isVi) descVi else descEn
}

@Composable
fun WatchAppearanceCard(
    previewNavInfo: NavigationInfo? = null,
    isVi: Boolean = false
) {
    val context = LocalContext.current
    val palette = LocalApplePalette.current
    val sharedPrefs = remember { context.getSharedPreferences("navigation_iq_prefs", Context.MODE_PRIVATE) }
    var selectedProfileId by remember { mutableStateOf(sharedPrefs.getInt("watch_layout_profile", 0)) }
    var selectedPresetId by remember { mutableStateOf(sharedPrefs.getInt("watch_text_preset", 0)) }
    var syncStatusText by remember { mutableStateOf<String?>(null) }
    var isSyncing by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    val currentProfile = WatchLayoutProfile.entries.find { it.id == selectedProfileId } ?: WatchLayoutProfile.AUTO
    val currentPreset = WatchTextPreset.entries.find { it.id == selectedPresetId } ?: WatchTextPreset.BALANCED

    val rawDist = previewNavInfo?.distance?.trim().orEmpty()
    val distTokens = if (rawDist.isNotEmpty()) rawDist.split(" ") else emptyList()
    val previewDistNumber = distTokens.firstOrNull()?.takeIf { it.isNotEmpty() } ?: "2.8"
    val previewDistUnit = distTokens.getOrNull(1)?.takeIf { it.isNotEmpty() } ?: "km"
    val previewEta = previewNavInfo?.eta?.takeIf { it.isNotEmpty() } ?: "17:48"
    val previewAction = if (!previewNavInfo?.signs.isNullOrBlank()) {
        previewNavInfo?.signs?.take(22) ?: "Continue straight"
    } else {
        "Continue straight"
    }

    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        // 1. Live Watch Face Preview Stage
        AppleFlatCard {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(18.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.FormatSize,
                            contentDescription = null,
                            tint = palette.blue,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (isVi) "Mô phỏng HUD thực tế" else "Live HUD Preview",
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 14.sp,
                            color = palette.textPrimary
                        )
                    }
                    Surface(
                        shape = RoundedCornerShape(50),
                        color = palette.blue.copy(alpha = 0.12f)
                    ) {
                        Text(
                            text = "${currentProfile.title(isVi)} • ${currentPreset.title(isVi)}",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            color = palette.blue,
                            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // Segmented Control for Watch Shape
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(palette.pillTrack, shape = RoundedCornerShape(10.dp))
                        .padding(3.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    WatchLayoutProfile.entries.forEach { profile ->
                        val isSelected = (selectedProfileId == profile.id)
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = if (isSelected) palette.pillThumb else Color.Transparent,
                            modifier = Modifier
                                .weight(1f)
                                .clickable {
                                    selectedProfileId = profile.id
                                    sharedPrefs.edit().putInt("watch_layout_profile", profile.id).apply()
                                    GarminManager.sendLayoutProfile(profile.id)
                                }
                        ) {
                            Text(
                                text = profile.title(isVi),
                                fontSize = 11.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                color = if (isSelected) (if (palette.isDark) palette.bg else Color.White) else palette.textSecondary,
                                modifier = Modifier
                                    .padding(vertical = 7.dp)
                                    .wrapContentWidth(Alignment.CenterHorizontally)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(18.dp))

                // Watch Hardware Bezel Preview
                val isInstinct = (selectedProfileId == WatchLayoutProfile.INSTINCT.id)
                val isRound = (selectedProfileId == WatchLayoutProfile.ROUND.id)

                if (isRound) {
                    Box(
                        modifier = Modifier
                            .size(240.dp)
                            .background(Color.Black, CircleShape)
                            .border(2.dp, Color(0xFF3A3A3C), CircleShape)
                            .padding(horizontal = 14.dp, vertical = 14.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            modifier = Modifier.fillMaxSize(),
                            verticalArrangement = Arrangement.SpaceBetween,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(42.dp)
                                    .background(Color(0xFF143B42), CircleShape)
                                    .padding(4.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(34.dp)
                                        .background(Color(0xFF4A8B99), CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.ArrowUpward,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(20.dp)
                                    )
                                }
                            }

                            Row(
                                verticalAlignment = Alignment.Bottom,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Text(
                                    text = previewDistNumber,
                                    fontSize = (currentPreset.distSp * 0.85f).sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    lineHeight = (currentPreset.distSp * 0.85f).sp
                                )
                                Spacer(modifier = Modifier.width(3.dp))
                                Text(
                                    text = previewDistUnit,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color(0xFF94A3B8),
                                    modifier = Modifier.padding(bottom = 2.dp)
                                )
                            }

                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = previewAction,
                                    fontSize = currentPreset.actionSp.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "on Highway 1 towards",
                                    fontSize = currentPreset.streetSp.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFFE4E4E7)
                                )
                                Text(
                                    text = "City Center",
                                    fontSize = (currentPreset.streetSp - 1).sp,
                                    fontWeight = FontWeight.Normal,
                                    color = Color(0xFFA1A1AA)
                                )
                            }

                            Surface(
                                shape = RoundedCornerShape(50),
                                color = Color(0xFF1A242B),
                                border = BorderStroke(1.dp, Color(0xFF2E3D47)),
                                modifier = Modifier.padding(bottom = 2.dp)
                            ) {
                                Text(
                                    text = "ETA $previewEta • 12:09",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 4.dp)
                                )
                            }
                        }
                    }
                } else if (isInstinct) {
                    Box(
                        modifier = Modifier
                            .size(236.dp)
                            .background(Color.Black, RoundedCornerShape(26.dp))
                            .border(3.dp, Color(0xFF384238), RoundedCornerShape(26.dp))
                            .padding(horizontal = 12.dp, vertical = 10.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            modifier = Modifier.fillMaxSize(),
                            verticalArrangement = Arrangement.SpaceBetween,
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column {
                                    Row(verticalAlignment = Alignment.Bottom) {
                                        Text(
                                            text = previewDistNumber,
                                            fontSize = 24.sp,
                                            fontWeight = FontWeight.Bold,
                                            fontFamily = FontFamily.Monospace,
                                            color = Color.White
                                        )
                                        Spacer(modifier = Modifier.width(2.dp))
                                        Text(
                                            text = previewDistUnit,
                                            fontSize = 13.sp,
                                            fontWeight = FontWeight.Bold,
                                            fontFamily = FontFamily.Monospace,
                                            color = Color.White
                                        )
                                    }
                                    Text(
                                        text = "ETA $previewEta",
                                        fontSize = 11.sp,
                                        fontFamily = FontFamily.Monospace,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White
                                    )
                                }

                                Box(
                                    modifier = Modifier
                                        .size(42.dp)
                                        .background(Color.Black, CircleShape)
                                        .border(2.dp, Color.White, CircleShape),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.ArrowUpward,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(24.dp)
                                    )
                                }
                            }

                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(1.dp)
                                    .background(Color.White)
                            )

                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(26.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth(0.9f)
                                        .height(10.dp)
                                        .background(Color(0xFF666666).copy(alpha = 0.5f), RoundedCornerShape(2.dp))
                                        .border(1.dp, Color(0xFF888888), RoundedCornerShape(2.dp))
                                )
                                Box(
                                    modifier = Modifier
                                        .size(24.dp)
                                        .background(Color(0xFF333333), CircleShape)
                                        .border(1.dp, Color(0xFFAAAAAA), CircleShape)
                                )
                            }

                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(1.dp)
                                    .background(Color.White)
                            )

                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = previewAction,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold,
                                    fontFamily = FontFamily.Monospace,
                                    color = Color.White,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Text(
                                    text = "on Highway 1",
                                    fontSize = 11.sp,
                                    fontFamily = FontFamily.Monospace,
                                    color = Color.White
                                )
                                Text(
                                    text = "towards City Center",
                                    fontSize = 10.sp,
                                    fontFamily = FontFamily.Monospace,
                                    color = Color(0xFFCCCCCC)
                                )
                            }
                        }
                    }
                } else {
                    Box(
                        modifier = Modifier
                            .size(width = 220.dp, height = 248.dp)
                            .background(Color.Black, RoundedCornerShape(28.dp))
                            .border(2.dp, Color(0xFF3A3A3C), RoundedCornerShape(28.dp))
                            .padding(horizontal = 14.dp, vertical = 12.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            modifier = Modifier.fillMaxSize(),
                            verticalArrangement = Arrangement.SpaceBetween,
                            horizontalAlignment = Alignment.Start
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Start
                            ) {
                                Box(
                                    modifier = Modifier
                                        .size(42.dp)
                                        .background(Color(0xFF143B42), CircleShape)
                                    .padding(4.dp),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(34.dp)
                                            .background(Color(0xFF4A8B99), CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.ArrowUpward,
                                            contentDescription = null,
                                            tint = Color.White,
                                            modifier = Modifier.size(20.dp)
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.width(10.dp))

                                Row(verticalAlignment = Alignment.Bottom) {
                                    Text(
                                        text = previewDistNumber,
                                        fontSize = currentPreset.distSp.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color.White,
                                        lineHeight = currentPreset.distSp.sp
                                    )
                                    Spacer(modifier = Modifier.width(3.dp))
                                    Text(
                                        text = previewDistUnit,
                                        fontSize = 15.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = Color(0xFF94A3B8),
                                        modifier = Modifier.padding(bottom = 3.dp)
                                    )
                                }
                            }

                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(1.dp)
                                    .background(Color(0xFF27272A))
                            )

                            Column(modifier = Modifier.fillMaxWidth()) {
                                Text(
                                    text = previewAction,
                                    fontSize = currentPreset.actionSp.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = Color.White,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                Text(
                                    text = "on Highway 1 towards",
                                    fontSize = currentPreset.streetSp.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = Color(0xFFE4E4E7)
                                )
                                Text(
                                    text = "City Center",
                                    fontSize = (currentPreset.streetSp - 1).sp,
                                    fontWeight = FontWeight.Normal,
                                    color = Color(0xFFA1A1AA)
                                )
                            }

                            Surface(
                                shape = RoundedCornerShape(16.dp),
                                color = Color(0xFF1A242B),
                                border = BorderStroke(1.dp, Color(0xFF2E3D47)),
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 8.dp, vertical = 5.dp),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Surface(
                                        shape = RoundedCornerShape(50),
                                        color = Color(0xFF163238),
                                        border = BorderStroke(1.dp, Color(0xFF2EC4B6))
                                    ) {
                                        Text(
                                            text = "ETA $previewEta",
                                            fontSize = 10.sp,
                                            fontWeight = FontWeight.Bold,
                                            color = Color.White,
                                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                                        )
                                    }

                                    Text(
                                        text = "•   12:09",
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold,
                                        color = Color(0xFFE4E4E7),
                                        modifier = Modifier.padding(end = 6.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Inset Grouped List for Typography Presets
        AppleSectionHeader(title = if (isVi) "BỐ CỤC & CỠ CHỮ HIỂN THỊ" else "LAYOUT & TYPOGRAPHY PRESETS")
        AppleFlatCard {
            Column(modifier = Modifier.fillMaxWidth()) {
                WatchTextPreset.entries.forEachIndexed { index, preset ->
                    val isSelected = (preset.id == selectedPresetId)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                selectedPresetId = preset.id
                                sharedPrefs.edit().putInt("watch_text_preset", preset.id).apply()
                                GarminManager.sendTextPreset(preset.id)
                            }
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = preset.title(isVi),
                                    fontSize = 15.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = if (isSelected) palette.blue else palette.textPrimary
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "${preset.distSp.toInt()}pt / ${preset.streetSp.toInt()}pt",
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = palette.textTertiary
                                )
                            }
                            Spacer(modifier = Modifier.height(2.dp))
                            Text(
                                text = preset.description(isVi),
                                fontSize = 12.sp,
                                color = palette.textSecondary
                            )
                        }
                        Spacer(modifier = Modifier.width(12.dp))
                        if (isSelected) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = if (isVi) "Đang chọn" else "Selected",
                                tint = palette.blue,
                                modifier = Modifier.size(20.dp)
                            )
                        }
                    }
                    if (index < WatchTextPreset.entries.lastIndex) {
                        HorizontalDivider(
                            modifier = Modifier.padding(start = 16.dp),
                            thickness = 0.5.dp,
                            color = palette.separator
                        )
                    }
                }
            }
        }

        // 3. Push Sync Button
        Button(
            onClick = {
                isSyncing = true
                syncStatusText = if (isVi) "Đang gửi cấu hình sang đồng hồ..." else "Syncing configuration with watch..."
                GarminManager.sendLayoutProfile(selectedProfileId)
                GarminManager.sendTextPreset(selectedPresetId) { success ->
                    scope.launch {
                        isSyncing = false
                        syncStatusText = if (success) {
                            if (isVi) "Đã đồng bộ giao diện sang đồng hồ thành công!" else "Successfully synced layout to watch!"
                        } else {
                            if (isVi) "Không thể kết nối đồng hồ hoặc ứng dụng trên đồng hồ chưa mở"
                            else "Unable to connect to watch or watch app is closed"
                        }
                        delay(4000L)
                        syncStatusText = null
                    }
                }
            },
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(containerColor = palette.blue),
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Sync,
                contentDescription = null,
                modifier = Modifier.size(18.dp),
                tint = Color.White
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = if (isSyncing) (if (isVi) "Đang đồng bộ..." else "Syncing...") else (if (isVi) "Đồng bộ giao diện & cỡ chữ sang đồng hồ" else "Sync Layout & Typography to Watch"),
                color = Color.White,
                fontWeight = FontWeight.SemiBold,
                fontSize = 14.sp
            )
        }

        if (syncStatusText != null) {
            Text(
                text = syncStatusText ?: "",
                fontSize = 12.sp,
                color = if (syncStatusText?.contains("thành công") == true || syncStatusText?.contains("Successfully") == true) palette.green else palette.orange,
                fontWeight = FontWeight.Medium,
                modifier = Modifier.padding(horizontal = 8.dp)
            )
        }
    }
}

// =============================================================================
// PAGE 3: SYSTEM SETTINGS PAGE (iOS Settings Inset Grouped Lists)
// =============================================================================
@Composable
fun SystemSettingsPage(
    isNotificationGranted: Boolean,
    isBatteryOptIgnored: Boolean,
    isWatchFound: Boolean,
    isHeartbeatLive: Boolean,
    watchName: String?,
    sentCount: Int,
    currentLanguage: AppLanguage,
    isVi: Boolean,
    onSelectLanguage: (AppLanguage) -> Unit
) {
    val context = LocalContext.current
    val palette = LocalApplePalette.current

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .navigationBarsPadding(),
        contentPadding = PaddingValues(top = 6.dp, bottom = 112.dp, start = 16.dp, end = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Section 1: Garmin Connect IQ
        item {
            AppleSectionHeader(title = if (isVi) "THIẾT BỊ GARMIN & CONNECT IQ SDK" else "GARMIN DEVICE & CONNECT IQ SDK")
            AppleFlatCard {
                Column(modifier = Modifier.fillMaxWidth()) {
                    AppleSettingsRow(
                        icon = Icons.Default.Watch,
                        iconTint = palette.blue,
                        title = watchName ?: if (isVi) "Chưa phát hiện đồng hồ" else "No watch detected",
                        subtitle = if (isHeartbeatLive) {
                            if (isVi) "Trực tuyến • Đã truyền $sentCount gói tin" else "Online • Transmitted $sentCount packets"
                        } else if (isWatchFound) {
                            if (isVi) "Đã ghép đôi trong Garmin Connect" else "Paired in Garmin Connect"
                        } else {
                            if (isVi) "Kiểm tra Bluetooth và ứng dụng Garmin Connect" else "Check Bluetooth and Garmin Connect app"
                        },
                        badgeText = if (isHeartbeatLive) "LIVE" else if (isWatchFound) "PAIRED" else "OFFLINE",
                        badgeColor = if (isHeartbeatLive) palette.green else if (isWatchFound) palette.blue else palette.orange
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 58.dp), thickness = 0.5.dp, color = palette.separator)

                    AppleSettingsRow(
                        icon = Icons.Default.Refresh,
                        iconTint = palette.blue,
                        title = if (isVi) "Quét lại danh sách thiết bị" else "Rescan Paired Devices",
                        subtitle = if (isVi) "Làm mới danh sách đồng hồ từ Garmin Connect IQ" else "Refresh watch list from Garmin Connect IQ",
                        showChevron = true,
                        onClick = { GarminManager.loadDevices(context) }
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 58.dp), thickness = 0.5.dp, color = palette.separator)

                    AppleSettingsRow(
                        icon = Icons.Default.WifiTethering,
                        iconTint = palette.green,
                        title = if (isVi) "Gửi tín hiệu kiểm tra (Ping)" else "Send Ping Signal",
                        subtitle = if (isVi) "Kiểm tra phản hồi hai chiều với ứng dụng trên đồng hồ" else "Verify two-way response with watch app",
                        showChevron = true,
                        onClick = { GarminManager.sendPing() }
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 58.dp), thickness = 0.5.dp, color = palette.separator)

                    AppleSettingsRow(
                        icon = Icons.Default.RestartAlt,
                        iconTint = palette.orange,
                        title = if (isVi) "Khởi động lại kết nối Bluetooth SDK" else "Restart Bluetooth SDK Connection",
                        subtitle = if (isVi) "Khôi phục phiên truyền dữ liệu khi đồng hồ bị kẹt" else "Recover transmission session if watch is unresponsive",
                        showChevron = true,
                        onClick = { GarminManager.restartConnection(context) }
                    )
                }
            }
        }

        // Section 2: Android Permissions
        item {
            AppleSectionHeader(title = if (isVi) "QUYỀN HỆ THỐNG & DUY TRÌ KẾT NỐI NỀN" else "SYSTEM PERMISSIONS & BACKGROUND RUNTIME")
            AppleFlatCard {
                Column(modifier = Modifier.fillMaxWidth()) {
                    AppleSettingsRow(
                        icon = Icons.Default.NotificationsActive,
                        iconTint = if (isNotificationGranted) palette.green else palette.orange,
                        title = if (isVi) "Quyền đọc thông báo" else "Notification Access",
                        subtitle = if (isNotificationGranted) {
                            if (isVi) "Đã bật • Đang lắng nghe chỉ đường từ Google Maps & OsmAnd"
                            else "Enabled • Capturing directions from Google Maps & OsmAnd"
                        } else {
                            if (isVi) "Chưa cấp quyền • Bấm để mở cài đặt hệ thống"
                            else "Not granted • Tap to open system settings"
                        },
                        badgeText = if (isNotificationGranted) (if (isVi) "ĐÃ BẬT" else "ENABLED") else (if (isVi) "CẦN BẬT" else "REQUIRED"),
                        badgeColor = if (isNotificationGranted) palette.green else palette.orange,
                        showChevron = true,
                        onClick = {
                            context.startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        }
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 58.dp), thickness = 0.5.dp, color = palette.separator)

                    AppleSettingsRow(
                        icon = Icons.Default.BatteryChargingFull,
                        iconTint = if (isBatteryOptIgnored) palette.green else palette.orange,
                        title = if (isVi) "Chạy nền không hạn chế pin" else "Unrestricted Background Battery",
                        subtitle = if (isBatteryOptIgnored) {
                            if (isVi) "Đã tắt tối ưu hóa pin • Không bị ngắt khi khóa màn hình"
                            else "Optimization disabled • Won't sleep when locked"
                        } else {
                            if (isVi) "Đang bị giới hạn pin • Bấm để chuyển sang Không hạn chế"
                            else "Battery restricted • Tap to set Unrestricted"
                        },
                        badgeText = if (isBatteryOptIgnored) (if (isVi) "ĐÃ TẮT" else "UNRESTRICTED") else (if (isVi) "CẦN TẮT" else "ACTION NEEDED"),
                        badgeColor = if (isBatteryOptIgnored) palette.green else palette.orange,
                        showChevron = true,
                        onClick = { requestIgnoreBatteryOptimizations(context) }
                    )
                }
            }
        }

        // Section 3: Supported Sources, Language & App Metadata
        item {
            AppleSectionHeader(title = if (isVi) "TƯƠNG THÍCH & THÔNG TIN ỨNG DỤNG" else "COMPATIBILITY & APP INFO")
            AppleFlatCard {
                Column(modifier = Modifier.fillMaxWidth()) {
                    // Language Switcher Row
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 13.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.weight(1f)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(32.dp)
                                    .background(palette.blue.copy(alpha = 0.14f), RoundedCornerShape(8.dp)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Language,
                                    contentDescription = null,
                                    tint = palette.blue,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column {
                                Text(
                                    text = if (isVi) "Ngôn ngữ giao diện" else "Interface Language",
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.SemiBold,
                                    color = palette.textPrimary
                                )
                                Spacer(modifier = Modifier.height(1.dp))
                                Text(
                                    text = if (isVi) "Đang dùng Tiếng Việt" else "Currently English (Default)",
                                    fontSize = 12.sp,
                                    color = palette.textSecondary
                                )
                            }
                        }

                        // Pill selector between EN and VI
                        Row(
                            modifier = Modifier
                                .background(palette.pillTrack, RoundedCornerShape(10.dp))
                                .padding(2.dp)
                        ) {
                            AppLanguage.entries.forEach { lang ->
                                val isSelected = currentLanguage == lang
                                Surface(
                                    shape = RoundedCornerShape(8.dp),
                                    color = if (isSelected) palette.pillThumb else Color.Transparent,
                                    modifier = Modifier.clickable { onSelectLanguage(lang) }
                                ) {
                                    Text(
                                        text = lang.name,
                                        fontSize = 11.sp,
                                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                        color = if (isSelected) (if (palette.isDark) palette.bg else Color.White) else palette.textSecondary,
                                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp)
                                    )
                                }
                            }
                        }
                    }

                    HorizontalDivider(modifier = Modifier.padding(start = 58.dp), thickness = 0.5.dp, color = palette.separator)

                    AppleSettingsRow(
                        icon = Icons.Default.Map,
                        iconTint = palette.blue,
                        title = if (isVi) "Nguồn bản đồ hỗ trợ" else "Supported Map Sources",
                        subtitle = if (isVi) "Google Maps & OsmAnd (Tự động giải mã mũi tên RLE)" else "Google Maps & OsmAnd (Auto RLE turn decoding)"
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 58.dp), thickness = 0.5.dp, color = palette.separator)

                    AppleSettingsRow(
                        icon = Icons.AutoMirrored.Filled.Message,
                        iconTint = palette.indigo,
                        title = if (isVi) "Chuyển tiếp tin nhắn khi dẫn đường" else "In-Navigation Chat Notification Forwarding",
                        subtitle = "Zalo, Messenger, Telegram, WhatsApp, SMS, Line, Viber"
                    )

                    HorizontalDivider(modifier = Modifier.padding(start = 58.dp), thickness = 0.5.dp, color = palette.separator)

                    AppleSettingsRow(
                        icon = Icons.Default.BluetoothConnected,
                        iconTint = palette.textSecondary,
                        title = "Watch App UUID",
                        subtitle = GarminManager.NAVIQ_APP_ID
                    )
                }
            }
        }
    }
}

@Composable
private fun AppleSettingsRow(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    subtitle: String,
    badgeText: String? = null,
    badgeColor: Color = IosBlue,
    showChevron: Boolean = false,
    onClick: (() -> Unit)? = null
) {
    val palette = LocalApplePalette.current
    val rowModifier = if (onClick != null) {
        Modifier
            .fillMaxWidth()
            .clickable { onClick() }
            .padding(horizontal = 16.dp, vertical = 13.dp)
    } else {
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 13.dp)
    }

    Row(
        modifier = rowModifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.weight(1f)
        ) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .background(iconTint.copy(alpha = 0.14f), RoundedCornerShape(8.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconTint,
                    modifier = Modifier.size(18.dp)
                )
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column {
                Text(
                    text = title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = palette.textPrimary
                )
                Spacer(modifier = Modifier.height(1.dp))
                Text(
                    text = subtitle,
                    fontSize = 12.sp,
                    color = palette.textSecondary
                )
            }
        }

        if (badgeText != null) {
            Spacer(modifier = Modifier.width(8.dp))
            Surface(
                shape = RoundedCornerShape(50),
                color = badgeColor.copy(alpha = 0.14f)
            ) {
                Text(
                    text = badgeText,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    color = badgeColor,
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp)
                )
            }
        }

        if (showChevron) {
            Spacer(modifier = Modifier.width(6.dp))
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = null,
                tint = palette.textTertiary,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

// =============================================================================
// PAGE 4: CONSOLE LOG PAGE (Live Telemetry & Filtered Monospace Logs)
// =============================================================================
private enum class LogFilter(val labelEn: String, val labelVi: String) {
    ALL("All", "Tất cả"),
    SEND("Send", "Gửi đi"),
    RECV("Recv", "Nhận về"),
    ALERT("Alerts", "Cảnh báo");

    fun label(isVi: Boolean) = if (isVi) labelVi else labelEn
}

@Composable
fun ConsoleLogPage(
    logs: List<String>,
    sentCount: Int,
    isHeartbeatLive: Boolean,
    isVi: Boolean
) {
    val palette = LocalApplePalette.current
    var selectedFilter by remember { mutableStateOf(LogFilter.ALL) }

    val filteredLogs = remember(logs, selectedFilter) {
        when (selectedFilter) {
            LogFilter.ALL -> logs
            LogFilter.SEND -> logs.filter {
                it.contains("[SEND") || it.contains("[PRESET]") || it.contains("[PROFILE]") || it.contains("[TOAST]")
            }
            LogFilter.RECV -> logs.filter {
                it.contains("[RECV") || it.contains("Device") || it.contains("Found")
            }
            LogFilter.ALERT -> logs.filter {
                it.contains("[WARN]") || it.contains("[FAIL]") || it.contains("[ERR]") || it.contains("error")
            }
        }
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .navigationBarsPadding(),
        contentPadding = PaddingValues(top = 6.dp, bottom = 112.dp, start = 16.dp, end = 16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        // Filter Bar & Quick Ping
        item {
            AppleFlatCard {
                Column(modifier = Modifier.padding(14.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = if (isVi) "${filteredLogs.size} bản ghi • Đã gửi $sentCount gói" else "${filteredLogs.size} entries • Sent $sentCount pkts",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = palette.textSecondary
                        )
                        Text(
                            text = if (isVi) "Gửi Ping" else "Send Ping",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = palette.blue,
                            modifier = Modifier.clickable { GarminManager.sendPing() }
                        )
                    }

                    Spacer(modifier = Modifier.height(10.dp))

                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(palette.pillTrack, RoundedCornerShape(10.dp))
                            .padding(3.dp),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        LogFilter.entries.forEach { filter ->
                            val isSelected = (selectedFilter == filter)
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = if (isSelected) palette.pillThumb else Color.Transparent,
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable { selectedFilter = filter }
                            ) {
                                Text(
                                    text = filter.label(isVi),
                                    fontSize = 11.sp,
                                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                                    color = if (isSelected) (if (palette.isDark) palette.bg else Color.White) else palette.textSecondary,
                                    modifier = Modifier
                                        .padding(vertical = 6.dp)
                                        .wrapContentWidth(Alignment.CenterHorizontally)
                                )
                            }
                        }
                    }
                }
            }
        }

        // Log Stream Card
        if (filteredLogs.isEmpty()) {
            item {
                AppleFlatCard {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 42.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = if (isVi) "Chưa có bản ghi nhật ký nào trong mục này" else "No log entries found in this category",
                            fontSize = 13.sp,
                            color = palette.textSecondary
                        )
                    }
                }
            }
        } else {
            item {
                AppleFlatCard {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        filteredLogs.forEachIndexed { index, entry ->
                            val tagColor = when {
                                entry.contains("[SEND") || entry.contains("[MAP]") -> palette.green
                                entry.contains("[FAIL]") || entry.contains("[ERR]") -> palette.red
                                entry.contains("[WARN]") -> palette.orange
                                entry.contains("[RECV") -> palette.blue
                                entry.contains("[PRESET]") || entry.contains("[PROFILE]") || entry.contains("[TOAST]") -> palette.indigo
                                else -> palette.textSecondary
                            }

                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 14.dp, vertical = 9.dp),
                                verticalAlignment = Alignment.Top
                            ) {
                                Surface(
                                    shape = CircleShape,
                                    color = tagColor,
                                    modifier = Modifier
                                        .padding(top = 5.dp)
                                        .size(6.dp)
                                ) {}
                                Spacer(modifier = Modifier.width(10.dp))
                                Text(
                                    text = entry,
                                    fontSize = 11.sp,
                                    lineHeight = 15.sp,
                                    color = palette.textPrimary,
                                    fontFamily = FontFamily.Monospace
                                )
                            }

                            if (index < filteredLogs.lastIndex) {
                                HorizontalDivider(
                                    modifier = Modifier.padding(start = 30.dp),
                                    thickness = 0.5.dp,
                                    color = palette.separator
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// =============================================================================
// Shared Flat Content Layer Primitives (No Glass on Content Layer)
// =============================================================================
@Composable
fun AppleFlatCard(
    modifier: Modifier = Modifier,
    content: @Composable () -> Unit
) {
    val palette = LocalApplePalette.current
    Surface(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(26.dp),
        color = palette.card,
        content = content
    )
}

@Composable
fun AppleSectionHeader(title: String) {
    val palette = LocalApplePalette.current
    Text(
        text = title,
        fontSize = 11.sp,
        fontWeight = FontWeight.SemiBold,
        color = palette.textSecondary,
        modifier = Modifier
            .fillMaxWidth()
            .padding(start = 12.dp, bottom = 6.dp)
    )
}

// =============================================================================
// System Helpers
// =============================================================================
private fun requestIgnoreBatteryOptimizations(context: Context) {
    try {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
        }
        context.startActivity(intent)
    } catch (e: Exception) {
        context.startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
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

fun isBatteryOptimizationIgnored(context: Context): Boolean {
    val pm = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
    return pm?.isIgnoringBatteryOptimizations(context.packageName) == true
}