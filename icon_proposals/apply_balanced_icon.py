import os
from PIL import Image, ImageDraw

RES_DIR = r"d:\Project\APKMod\NavigationIQ\app\src\main\res"
GARMIN_DIR = r"d:\Project\APKMod\NavigationIQ\garmin_app\resources\drawables"

# Precise Optical Centering (Lowered by another 1dp to y=27):
# tip: (54.0, 27.0)
# l_wing: (33.0, 72.0)
# r_wing: (75.0, 72.0)
# notch: (54.0, 60.5)

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
        android:pathData="M 54,27 L 33,72 L 54,60.5 Z" />

    <!-- Navigation Arrowhead (Right Wing - Vivid Mint Emerald) -->
    <path
        android:fillColor="#10B981"
        android:pathData="M 54,27 L 54,60.5 L 75,72 Z" />

    <!-- Center Spine Divider -->
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="0.6"
        android:strokeAlpha="0.7"
        android:pathData="M 54,27 L 54,60.5" />
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
        android:pathData="M 54,27 L 33,72 L 54,60.5 L 75,72 Z" />
</vector>
"""
with open(os.path.join(RES_DIR, "drawable", "ic_launcher_monochrome.xml"), "w", encoding="utf-8") as f:
    f.write(mono_xml)

# 2. Generate Master Bitmap (1024x1024)
SIZE = 1024
SCALE = SIZE / 108.0
cx = 54.0 * SCALE
tip = (cx, 27.0 * SCALE)
l_wing = (33.0 * SCALE, 72.0 * SCALE)
r_wing = (75.0 * SCALE, 72.0 * SCALE)
notch = (cx, 60.5 * SCALE)

master = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 255))
draw = ImageDraw.Draw(master)
draw.polygon([tip, l_wing, notch], fill="#1B4332")
draw.polygon([tip, notch, r_wing], fill="#10B981")
draw.line([tip, notch], fill=(255, 255, 255, 160), width=int(0.6 * SCALE))

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
    <rect width="40" height="40" rx="8" fill="#0C1C14"/>
    <path d="M 20 8.5 L 12 27 L 20 22.5 Z" fill="#FFFFFF"/>
    <path d="M 20 8.5 L 20 22.5 L 28 27 Z" fill="#10B981"/>
</svg>
"""
with open(os.path.join(GARMIN_DIR, "launcher_icon.svg"), "w", encoding="utf-8") as f:
    f.write(garmin_svg)

g_40 = master.resize((40, 40), Image.Resampling.LANCZOS)
g_40.save(os.path.join(GARMIN_DIR, "launcher_icon_40.png"), "PNG")
g_33 = master.resize((33, 33), Image.Resampling.LANCZOS)
g_33.save(os.path.join(GARMIN_DIR, "launcher_icon_33.png"), "PNG")

print("SUCCESS: Lowered arrow by another 1dp (tip=27, wings=72, notch=60.5)!")
