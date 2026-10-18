import os
import math
from PIL import Image, ImageDraw

OUT_DIR = r"d:\Project\APKMod\NavigationIQ\icon_proposals"
RES_DIR = r"d:\Project\APKMod\NavigationIQ\app\src\main\res"
GARMIN_DIR = r"d:\Project\APKMod\NavigationIQ\garmin_app\resources\drawables"

SIZE = 512
SCALE = 4
HI_SIZE = SIZE * SCALE  # 2048x2048

# Color Palette
BG_COLOR = (12, 28, 20, 255)       # Deep Obsidian Forest Green
ARROW_WHITE = (245, 245, 242, 255)  # Crisp Pure Off-White
ARROW_GREEN = (34, 197, 94, 255)    # Vibrant Mint / Navigation Emerald
RADAR_GREEN = (34, 197, 94, 255)    # BLE Pulse Ring
RADAR_ALPHA_1 = 180                 # Bold inner ring alpha
RADAR_ALPHA_2 = 110                 # Outer ring alpha

def draw_radar_nav_content(draw, cx, cy, s_scale, is_monochrome=False):
    """Draws the refined 2-ring bold radar and GPS arrowhead."""
    # Colors
    c_white = (255, 255, 255, 255) if is_monochrome else ARROW_WHITE
    c_green = (255, 255, 255, 200) if is_monochrome else ARROW_GREEN
    
    # 2 Bold Concentric Radar Arcs
    r1 = int(190 * s_scale)
    r2 = int(285 * s_scale)
    w_arc = int(12 * s_scale)
    
    # Inner ring (top arc 110 deg, bottom arc 70 deg)
    a1 = 255 if is_monochrome else RADAR_ALPHA_1
    a2 = 180 if is_monochrome else RADAR_ALPHA_2
    
    col1 = (c_green[0], c_green[1], c_green[2], a1)
    col2 = (c_green[0], c_green[1], c_green[2], a2)
    
    draw.arc([cx - r1, cy - r1, cx + r1, cy + r1], start=215, end=325, fill=col1, width=w_arc)
    draw.arc([cx - r1, cy - r1, cx + r1, cy + r1], start=45, end=135, fill=(col1[0], col1[1], col1[2], a1//2), width=int(w_arc * 0.8))
    
    # Outer ring
    draw.arc([cx - r2, cy - r2, cx + r2, cy + r2], start=225, end=315, fill=col2, width=int(w_arc * 0.9))
    draw.arc([cx - r2, cy - r2, cx + r2, cy + r2], start=55, end=125, fill=(col2[0], col2[1], col2[2], a2//2), width=int(w_arc * 0.7))
    
    # 2 Satellite BLE Pulse Dots on radar ring
    d_r = int(11 * s_scale)
    d1_x = cx + int(r1 * math.cos(-math.pi / 3))
    d1_y = cy + int(r1 * math.sin(-math.pi / 3))
    draw.ellipse([d1_x - d_r, d1_y - d_r, d1_x + d_r, d1_y + d_r], fill=col1)
    
    d2_x = cx - int(r2 * math.cos(math.pi / 4))
    d2_y = cy - int(r2 * math.sin(math.pi / 4))
    draw.ellipse([d2_x - int(d_r*0.8), d2_y - int(d_r*0.8), d2_x + int(d_r*0.8), d2_y + int(d_r*0.8)], fill=col2)
    
    # Center Navigation Arrowhead (Bold, proportioned for glanceability)
    tip = (cx, cy - int(145 * s_scale))
    l_wing = (cx - int(105 * s_scale), cy + int(95 * s_scale))
    r_wing = (cx + int(105 * s_scale), cy + int(95 * s_scale))
    notch = (cx, cy + int(35 * s_scale))
    
    # Subtle drop shadow for depth
    s_off = int(8 * s_scale)
    draw.polygon([(tip[0], tip[1] + s_off), (l_wing[0], l_wing[1] + s_off), (notch[0], notch[1] + s_off)], fill=(0, 0, 0, 90))
    draw.polygon([(tip[0], tip[1] + s_off), (notch[0], notch[1] + s_off), (r_wing[0], r_wing[1] + s_off)], fill=(0, 0, 0, 90))
    
    # Left Half: Crisp Off-White
    draw.polygon([tip, l_wing, notch], fill=c_white)
    # Right Half: Vibrant Mint Green
    draw.polygon([tip, notch, r_wing], fill=c_green)
    # Divider line
    draw.line([tip, notch], fill=(255, 255, 255, 120), width=int(3 * s_scale))

def generate_master_icon():
    """Generates the master 512x512 squircle icon."""
    img = Image.new("RGBA", (HI_SIZE, HI_SIZE), (0, 0, 0, 0))
    mask = Image.new("L", (HI_SIZE, HI_SIZE), 0)
    draw_mask = ImageDraw.Draw(mask)
    r = int(HI_SIZE * 0.22)
    draw_mask.rounded_rectangle([0, 0, HI_SIZE, HI_SIZE], radius=r, fill=255)
    
    bg = Image.new("RGBA", (HI_SIZE, HI_SIZE), BG_COLOR)
    img.paste(bg, (0, 0), mask)
    
    draw = ImageDraw.Draw(img)
    draw_radar_nav_content(draw, HI_SIZE // 2, HI_SIZE // 2, SCALE)
    
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    out_path = os.path.join(OUT_DIR, "icon_05_ble_radar_nav_final.png")
    res.save(out_path, "PNG")
    print(f"Master icon saved to {out_path}")
    return res

def generate_android_adaptive_assets():
    """Generates Android vector drawables and mipmap PNGs."""
    # 1. Background Vector Drawable
    bg_xml = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#0C1C14"
        android:pathData="M0,0h108v108h-108z" />
</vector>
"""
    with open(os.path.join(RES_DIR, "drawable", "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
        f.write(bg_xml)
        
    # 2. Foreground Vector Drawable
    fg_xml = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    
    <!-- Outer BLE Radar Arc (Upper) -->
    <path
        android:strokeColor="#22C55E"
        android:strokeWidth="1.8"
        android:strokeAlpha="0.45"
        android:strokeLineCap="round"
        android:pathData="M 32.5,43 A 28.5,28.5 0 0,1 75.5,43" />
        
    <!-- Outer BLE Radar Arc (Lower) -->
    <path
        android:strokeColor="#22C55E"
        android:strokeWidth="1.4"
        android:strokeAlpha="0.25"
        android:strokeLineCap="round"
        android:pathData="M 72,66 A 28.5,28.5 0 0,1 36,66" />

    <!-- Inner BLE Radar Arc (Upper) -->
    <path
        android:strokeColor="#22C55E"
        android:strokeWidth="2.4"
        android:strokeAlpha="0.75"
        android:strokeLineCap="round"
        android:pathData="M 38.5,45.5 A 19,19 0 0,1 69.5,45.5" />
        
    <!-- Inner BLE Radar Arc (Lower) -->
    <path
        android:strokeColor="#22C55E"
        android:strokeWidth="1.8"
        android:strokeAlpha="0.35"
        android:strokeLineCap="round"
        android:pathData="M 66,62.5 A 19,19 0 0,1 42,62.5" />

    <!-- Satellite BLE Dot -->
    <path
        android:fillColor="#22C55E"
        android:fillAlpha="0.8"
        android:pathData="M 64.5,37.5 a 1.8,1.8 0 1,0 0.01,0 Z" />

    <!-- Navigation Arrowhead (Left Wing - Pure Off-White) -->
    <path
        android:fillColor="#F5F5F2"
        android:pathData="M 54,38 L 41.5,63.5 L 54,56.5 Z" />

    <!-- Navigation Arrowhead (Right Wing - Vibrant Mint Green) -->
    <path
        android:fillColor="#22C55E"
        android:pathData="M 54,38 L 54,56.5 L 66.5,63.5 Z" />

    <!-- Center Spine Divider -->
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="0.5"
        android:strokeAlpha="0.6"
        android:pathData="M 54,38 L 54,56.5" />
</vector>
"""
    with open(os.path.join(RES_DIR, "drawable", "ic_launcher_foreground.xml"), "w", encoding="utf-8") as f:
        f.write(fg_xml)
        
    # 3. Monochrome Vector Drawable (For Android 13+ Themed Icons)
    mono_xml = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="2.2"
        android:strokeAlpha="0.5"
        android:strokeLineCap="round"
        android:pathData="M 38.5,45.5 A 19,19 0 0,1 69.5,45.5" />
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="1.6"
        android:strokeAlpha="0.3"
        android:strokeLineCap="round"
        android:pathData="M 32.5,43 A 28.5,28.5 0 0,1 75.5,43" />
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M 54,38 L 41.5,63.5 L 54,56.5 L 66.5,63.5 Z" />
</vector>
"""
    with open(os.path.join(RES_DIR, "drawable", "ic_launcher_monochrome.xml"), "w", encoding="utf-8") as f:
        f.write(mono_xml)

    # 4. Generate Legacy Mipmaps
    legacy_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    
    # Square & Round Base Hi-Res
    master = Image.open(os.path.join(OUT_DIR, "icon_05_ble_radar_nav_final.png")).convert("RGBA")
    
    # Create circular version
    circle_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    c_mask = Image.new("L", (SIZE, SIZE), 0)
    c_draw = ImageDraw.Draw(c_mask)
    c_draw.ellipse([0, 0, SIZE, SIZE], fill=255)
    
    bg_circle = Image.new("RGBA", (SIZE, SIZE), BG_COLOR)
    circle_img.paste(bg_circle, (0, 0), c_mask)
    draw_c = ImageDraw.Draw(circle_img)
    draw_radar_nav_content(draw_c, SIZE // 2, SIZE // 2, 1)
    
    for folder, dim in legacy_sizes.items():
        t_dir = os.path.join(RES_DIR, folder)
        os.makedirs(t_dir, exist_ok=True)
        # ic_launcher.png (Squircle)
        sq_res = master.resize((dim, dim), Image.Resampling.LANCZOS)
        sq_res.save(os.path.join(t_dir, "ic_launcher.png"), "PNG")
        # ic_launcher_round.png (Circular)
        rd_res = circle_img.resize((dim, dim), Image.Resampling.LANCZOS)
        rd_res.save(os.path.join(t_dir, "ic_launcher_round.png"), "PNG")
        
    print("Android Adaptive Icons & Legacy Mipmaps generated!")

def generate_garmin_assets():
    """Generates Garmin Connect IQ launcher icon SVG and high-res PNG."""
    garmin_svg = """<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
    <!-- Dark Background -->
    <rect width="40" height="40" rx="8" fill="#0C1C14"/>
    
    <!-- BLE Radar Wave Inner -->
    <path d="M 14 17 A 7.5 7.5 0 0 1 26 17" stroke="#22C55E" stroke-width="1.8" stroke-linecap="round" stroke-opacity="0.8"/>
    <!-- BLE Radar Wave Outer -->
    <path d="M 11 15 A 11 11 0 0 1 29 15" stroke="#22C55E" stroke-width="1.4" stroke-linecap="round" stroke-opacity="0.45"/>
    
    <!-- Nav Arrow Left Wing (White) -->
    <path d="M 20 12 L 15 24 L 20 21 Z" fill="#F5F5F2"/>
    <!-- Nav Arrow Right Wing (Mint Green) -->
    <path d="M 20 12 L 20 21 L 25 24 Z" fill="#22C55E"/>
</svg>
"""
    with open(os.path.join(GARMIN_DIR, "launcher_icon.svg"), "w", encoding="utf-8") as f:
        f.write(garmin_svg)
        
    # Generate Garmin 40x40 and 33x33 PNG
    master = Image.open(os.path.join(OUT_DIR, "icon_05_ble_radar_nav_final.png")).convert("RGBA")
    g_40 = master.resize((40, 40), Image.Resampling.LANCZOS)
    g_40.save(os.path.join(GARMIN_DIR, "launcher_icon_40.png"), "PNG")
    g_33 = master.resize((33, 33), Image.Resampling.LANCZOS)
    g_33.save(os.path.join(GARMIN_DIR, "launcher_icon_33.png"), "PNG")
    print("Garmin Connect IQ launcher icon updated!")

def generate_mockup_preview():
    """Creates a comprehensive preview sheet showing the icon in real environments."""
    W = 1200
    H = 680
    canvas = Image.new("RGBA", (W, H), (18, 20, 23, 255))
    draw = ImageDraw.Draw(canvas)
    
    # Title
    draw.text((50, 40), "Navigation IQ - Final Launcher Icon Design (Concept 05 Refined)", fill=(255, 255, 255, 255))
    draw.text((50, 75), "Telemetry BLE Radar Pulse + Navigation Arrowhead across Android & Garmin Watch", fill=(160, 170, 180, 255))
    
    # 1. Master Icon (300x300)
    master = Image.open(os.path.join(OUT_DIR, "icon_05_ble_radar_nav_final.png")).convert("RGBA")
    m_300 = master.resize((300, 300), Image.Resampling.LANCZOS)
    canvas.paste(m_300, (60, 140), m_300)
    draw.text((60, 460), "Master 512x512 (Google Play / Store)", fill=(230, 230, 230, 255))
    draw.text((60, 485), "Deep Obsidian Forest (#0C1C14) + Mint Green", fill=(140, 150, 160, 255))
    
    # 2. Android Phone Launcher Mockup
    # Draw simulated dark phone screen card
    draw.rounded_rectangle([440, 140, 760, 560], radius=32, fill=(28, 31, 35, 255), outline=(255, 255, 255, 25), width=2)
    # Simulated top status bar dots
    draw.ellipse([460, 160, 470, 170], fill=(255, 255, 255, 60))
    draw.ellipse([480, 160, 490, 170], fill=(255, 255, 255, 60))
    # Simulated app grid
    m_100 = master.resize((100, 100), Image.Resampling.LANCZOS)
    canvas.paste(m_100, (550, 240), m_100)
    draw.text((545, 355), "Navigation IQ", fill=(240, 240, 240, 255))
    
    # Fake neighboring icons (gray placeholders)
    for ox, oy, name in [(470, 410, "Maps"), (590, 410, "Connect"), (710, 410, "Strava")]:
        if ox + 64 <= 740:
            draw.rounded_rectangle([ox, oy, ox + 64, oy + 64], radius=16, fill=(45, 48, 54, 255))
            draw.text((ox + 8, oy + 72), name, fill=(120, 130, 140, 255))
            
    draw.text((455, 580), "Android Launcher (Adaptive Squircle)", fill=(230, 230, 230, 255))
    
    # 3. Garmin Watch Launcher Mockup
    # Watch circular bezel
    watch_cx = 960
    watch_cy = 280
    watch_r = 140
    draw.ellipse([watch_cx - watch_r, watch_cy - watch_r, watch_cx + watch_r, watch_cy + watch_r], fill=(10, 10, 10, 255), outline=(255, 255, 255, 50), width=4)
    # Bezel tick marks
    for i in range(12):
        ang = i * (math.pi / 6)
        x1 = watch_cx + int((watch_r - 8) * math.cos(ang))
        y1 = watch_cy + int((watch_r - 8) * math.sin(ang))
        x2 = watch_cx + int(watch_r * math.cos(ang))
        y2 = watch_cy + int(watch_r * math.sin(ang))
        draw.line([x1, y1, x2, y2], fill=(255, 255, 255, 100), width=2)
        
    # App icon in watch menu
    m_80 = master.resize((84, 84), Image.Resampling.LANCZOS)
    canvas.paste(m_80, (watch_cx - 42, watch_cy - 52), m_80)
    draw.text((watch_cx - 40, watch_cy + 42), "NavIQ", fill=(34, 197, 94, 255))
    
    draw.text((830, 460), "Garmin Watch Menu (33x33 - 40x40)", fill=(230, 230, 230, 255))
    draw.text((830, 485), "High-contrast glanceability on AMOLED & MIP", fill=(140, 150, 160, 255))
    
    prev_path = os.path.join(OUT_DIR, "00_icon_final_preview.png")
    canvas.save(prev_path, "PNG")
    print(f"Mockup preview saved to {prev_path}")

# Run all
generate_master_icon()
generate_android_adaptive_assets()
generate_garmin_assets()
generate_mockup_preview()
