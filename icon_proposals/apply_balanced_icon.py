import os
from PIL import Image, ImageDraw

RES_DIR = r"d:\Project\APKMod\NavigationIQ\app\src\main\res"
GARMIN_DIR = r"d:\Project\APKMod\NavigationIQ\garmin_app\resources\drawables"

# Precise Optical Centering (Lowered by another 1dp to y=28):
# tip: (54.0, 28.0)
# l_wing: (33.0, 73.0)
# r_wing: (75.0, 73.0)
# notch: (54.0, 61.5)

# 1. Update Android Vector XMLs
fg_xml = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Navigation Arrowhead (Left Wing - Deep Forest Green) -->
    <path
        android:fillColor="#1B4332"
        android:pathData="M 54,28 L 33,73 L 54,61.5 Z" />

    <!-- Navigation Arrowhead (Right Wing - Vivid Mint Emerald) -->
    <path
        android:fillColor="#10B981"
        android:pathData="M 54,28 L 54,61.5 L 75,73 Z" />

    <!-- Center Spine Divider -->
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="0.6"
        android:strokeAlpha="0.7"
        android:pathData="M 54,28 L 54,61.5" />
</vector>
"""
with open(os.path.join(RES_DIR, "drawable", "ic_launcher_foreground.xml"), "w", encoding="utf-8") as f:
    f.write(fg_xml)

mono_xml = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M 54,28 L 33,73 L 54,61.5 L 75,73 Z" />
</vector>
"""
with open(os.path.join(RES_DIR, "drawable", "ic_launcher_monochrome.xml"), "w", encoding="utf-8") as f:
    f.write(mono_xml)

# 2. Generate Master Bitmap (2048x2048 with supersampling)
SIZE = 2048
SCALE = SIZE / 108.0
cx = 54.0 * SCALE
tip = (cx, 28.0 * SCALE)
l_wing = (33.0 * SCALE, 73.0 * SCALE)
r_wing = (75.0 * SCALE, 73.0 * SCALE)
notch = (cx, 61.5 * SCALE)

master = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 255))
draw = ImageDraw.Draw(master)
draw.polygon([tip, l_wing, notch], fill="#1B4332")
draw.polygon([tip, notch, r_wing], fill="#10B981")
draw.line([tip, notch], fill=(255, 255, 255, 180), width=max(2, int(0.6 * SCALE)))

# Master high-res
master.save(r"d:\Project\APKMod\NavigationIQ\scratch\modern_icon_2048.png", "PNG")

# 512x512 Store Icons (Full Square with solid white background)
store_512 = master.resize((512, 512), Image.Resampling.LANCZOS)
store_512.save(r"d:\Project\APKMod\NavigationIQ\playstore_icon_512.png", "PNG")
store_512.save(r"d:\Project\APKMod\NavigationIQ\garmin_app\garmin_store_icon_512.png", "PNG")

# Circular version for round mipmap
circle_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
c_mask = Image.new("L", (SIZE, SIZE), 0)
cdraw = ImageDraw.Draw(c_mask)
cdraw.ellipse([0, 0, SIZE, SIZE], fill=255)
circle_img.paste(master, (0, 0), c_mask)

# Save to WebP mipmaps
legacy_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

for folder, dim in legacy_sizes.items():
    t_dir = os.path.join(RES_DIR, folder)
    sq_res = master.resize((dim, dim), Image.Resampling.LANCZOS)
    sq_res.save(os.path.join(t_dir, "ic_launcher.webp"), "WEBP")
    
    rd_res = circle_img.resize((dim, dim), Image.Resampling.LANCZOS)
    rd_res.save(os.path.join(t_dir, "ic_launcher_round.webp"), "WEBP")

# 3. Garmin Icons
garmin_svg = """<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#FFFFFF"/>
    <path d="M 20 10.37 L 12.22 27.04 L 20 22.78 Z" fill="#1B4332"/>
    <path d="M 20 10.37 L 20 22.78 L 27.78 27.04 Z" fill="#10B981"/>
    <line x1="20" y1="10.37" x2="20" y2="22.78" stroke="#FFFFFF" stroke-width="0.3" stroke-opacity="0.8"/>
</svg>
"""
with open(os.path.join(GARMIN_DIR, "launcher_icon.svg"), "w", encoding="utf-8") as f:
    f.write(garmin_svg)

g_40 = master.resize((40, 40), Image.Resampling.LANCZOS)
g_40.save(os.path.join(GARMIN_DIR, "launcher_icon_40.png"), "PNG")
g_33 = master.resize((33, 33), Image.Resampling.LANCZOS)
g_33.save(os.path.join(GARMIN_DIR, "launcher_icon_33.png"), "PNG")

print("SUCCESS: Clean, crisp navigation arrow icons generated across all stores, drawables, and mipmaps!")

