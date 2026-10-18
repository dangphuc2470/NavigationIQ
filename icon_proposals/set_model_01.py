import os
from PIL import Image, ImageDraw

RES_DIR = r"d:\Project\APKMod\NavigationIQ\app\src\main\res"
SRC_ICON = r"d:\Project\APKMod\NavigationIQ\icon_proposals\batch2\01_pure_arrow_white.png"
GARMIN_DIR = r"d:\Project\APKMod\NavigationIQ\garmin_app\resources\drawables"

master = Image.open(SRC_ICON).convert("RGBA")

# 1. Update Android Vector XMLs
bg_xml = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M0,0h108v108h-108z" />
</vector>
"""
with open(os.path.join(RES_DIR, "drawable", "ic_launcher_background.xml"), "w", encoding="utf-8") as f:
    f.write(bg_xml)

fg_xml = """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Navigation Arrowhead (Left Wing - Deep Forest Green) -->
    <path
        android:fillColor="#1B4332"
        android:pathData="M 54,34 L 40,64 L 54,56 Z" />

    <!-- Navigation Arrowhead (Right Wing - Vivid Mint Emerald) -->
    <path
        android:fillColor="#10B981"
        android:pathData="M 54,34 L 54,56 L 68,64 Z" />

    <!-- Center Spine Divider -->
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="0.5"
        android:strokeAlpha="0.6"
        android:pathData="M 54,34 L 54,56" />
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
        android:pathData="M 54,34 L 40,64 L 54,56 L 68,64 Z" />
</vector>
"""
with open(os.path.join(RES_DIR, "drawable", "ic_launcher_monochrome.xml"), "w", encoding="utf-8") as f:
    f.write(mono_xml)

# 2. Update Legacy WebP Mipmaps
legacy_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

SIZE = 512
circle_img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
c_mask = Image.new("L", (SIZE, SIZE), 0)
c_draw = ImageDraw.Draw(c_mask)
c_draw.ellipse([0, 0, SIZE, SIZE], fill=255)
circle_img.paste(master, (0, 0), c_mask)

for folder, dim in legacy_sizes.items():
    t_dir = os.path.join(RES_DIR, folder)
    sq_res = master.resize((dim, dim), Image.Resampling.LANCZOS)
    sq_res.save(os.path.join(t_dir, "ic_launcher.webp"), "WEBP")
    
    rd_res = circle_img.resize((dim, dim), Image.Resampling.LANCZOS)
    rd_res.save(os.path.join(t_dir, "ic_launcher_round.webp"), "WEBP")

# 3. Update Garmin Icons
garmin_svg = """<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect width="40" height="40" rx="8" fill="#0C1C14"/>
    <path d="M 20 9 L 14 26 L 20 22 Z" fill="#FFFFFF"/>
    <path d="M 20 9 L 20 22 L 26 26 Z" fill="#10B981"/>
</svg>
"""
with open(os.path.join(GARMIN_DIR, "launcher_icon.svg"), "w", encoding="utf-8") as f:
    f.write(garmin_svg)

g_40 = master.resize((40, 40), Image.Resampling.LANCZOS)
g_40.save(os.path.join(GARMIN_DIR, "launcher_icon_40.png"), "PNG")
g_33 = master.resize((33, 33), Image.Resampling.LANCZOS)
g_33.save(os.path.join(GARMIN_DIR, "launcher_icon_33.png"), "PNG")

print("Model 01 applied as official launcher icon successfully!")
