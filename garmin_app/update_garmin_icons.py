import os
from PIL import Image, ImageDraw

GARMIN_DRAWABLES = r"d:\Project\APKMod\NavigationIQ\garmin_app\resources\drawables"
GARMIN_ROOT = r"d:\Project\APKMod\NavigationIQ\garmin_app"

# 1. Update launcher_icon.svg
svg_content = """<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
    <!-- Pure White Rounded Background -->
    <rect width="40" height="40" rx="8" fill="#FFFFFF"/>
    
    <!-- Navigation Arrow Left Wing (Deep Forest Green) -->
    <path d="M 20 10 L 12 27 L 20 23 Z" fill="#1B4332"/>
    
    <!-- Navigation Arrow Right Wing (Vivid Mint Emerald) -->
    <path d="M 20 10 L 20 23 L 28 27 Z" fill="#10B981"/>
    
    <!-- Center Spine Divider -->
    <path d="M 20 10 L 20 23" stroke="#FFFFFF" stroke-width="0.5" stroke-opacity="0.8"/>
</svg>
"""

with open(os.path.join(GARMIN_DRAWABLES, "launcher_icon.svg"), "w", encoding="utf-8") as f:
    f.write(svg_content)

# 2. Render High-Res Master Bitmap (1024x1024)
SIZE = 1024
SCALE = SIZE / 40.0

img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
mask = Image.new("L", (SIZE, SIZE), 0)
mdraw = ImageDraw.Draw(mask)
mdraw.rounded_rectangle([0, 0, SIZE, SIZE], radius=int(8 * SCALE), fill=255)

bg = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 255))
img.paste(bg, (0, 0), mask)

draw = ImageDraw.Draw(img)
tip = (20 * SCALE, 10 * SCALE)
l_wing = (12 * SCALE, 27 * SCALE)
r_wing = (28 * SCALE, 27 * SCALE)
notch = (20 * SCALE, 23 * SCALE)

draw.polygon([tip, l_wing, notch], fill="#1B4332")
draw.polygon([tip, notch, r_wing], fill="#10B981")
draw.line([tip, notch], fill=(255, 255, 255, 200), width=int(0.5 * SCALE))

# 3. Save Garmin Watch Drawables (40x40 and 33x33 PNGs)
g_40 = img.resize((40, 40), Image.Resampling.LANCZOS)
g_40.save(os.path.join(GARMIN_DRAWABLES, "launcher_icon_40.png"), "PNG")

g_33 = img.resize((33, 33), Image.Resampling.LANCZOS)
g_33.save(os.path.join(GARMIN_DRAWABLES, "launcher_icon_33.png"), "PNG")

# 4. Save 512x512 Store Listing Icon for Garmin Developer Dashboard
store_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
store_512.save(os.path.join(GARMIN_ROOT, "garmin_store_icon_512.png"), "PNG")

print("SUCCESS: Garmin launcher icons synchronized with Android app palette!")
