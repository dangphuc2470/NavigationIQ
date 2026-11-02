import os
import glob
from PIL import Image

SCREENSHOTS_DIR = r"d:\Project\APKMod\NavigationIQ\garmin_app\screenshots\normal"

def check_nav_hud(path):
    size = os.path.getsize(path)
    if size < 40000:
        return False, "EMPTY_OR_WHITE_WINDOW"
        
    try:
        im = Image.open(path).convert("RGB")
        w, h = im.size
        # Crop center screen area
        cx, cy = w // 2, h // 2
        
        # In real Navigation HUD:
        # 1. There is white text "1.4" and "Turn right onto" or "Main Street"
        # 2. There are multiple bright colors: White text, Green accent/circle, Grey pill, etc.
        # In Garmin boot splash:
        # Screen is pitch black except for a blue triangle in the center.
        
        # Check area around Y = cy + 30 to cy + 90 (where "Main Street" or "Turn right onto" should be)
        box_text = im.crop((cx - 80, cy + 20, cx + 80, cy + 90))
        colors_text = box_text.getcolors(maxcolors=10000)
        
        # Look for white/light pixels in text area (R > 180, G > 180, B > 180)
        white_pixel_count = 0
        for count, rgb in colors_text:
            if rgb[0] > 180 and rgb[1] > 180 and rgb[2] > 180:
                white_pixel_count += count
                
        # Look for green navigation circle or arrow (G > 100, R < 100, B < 150)
        box_icon = im.crop((cx - 60, cy - 120, cx + 60, cy - 20))
        colors_icon = box_icon.getcolors(maxcolors=10000)
        has_nav_icon = False
        for count, rgb in colors_icon:
            # White arrow (for MIP) or Green circle (for AMOLED)
            if (rgb[0] > 180 and rgb[1] > 180 and rgb[2] > 180 and count > 30) or \
               (rgb[1] > 90 and rgb[0] < 80 and count > 50):
                has_nav_icon = True
                break
                
        if white_pixel_count < 25:
            # Check if it has Garmin boot triangle (Cyan/Blue pixels)
            has_blue_triangle = False
            for count, rgb in box_text.getcolors(maxcolors=10000):
                if rgb[2] > 150 and rgb[0] < 50:
                    has_blue_triangle = True
                    break
            if has_blue_triangle:
                return False, "GARMIN_BOOT_TRIANGLE"
            return False, "NO_NAVIGATION_TEXT"
            
        return True, "VALID_NAV_HUD"
    except Exception as e:
        return False, f"ERROR: {e}"

files = sorted(glob.glob(os.path.join(SCREENSHOTS_DIR, "*.png")))
valid_count = 0
invalid_devices = []

for f in files:
    dev = os.path.basename(f)[:-4]
    ok, reason = check_nav_hud(f)
    if ok:
        valid_count += 1
        print(f"[V] {dev:25} | OK")
    else:
        invalid_devices.append((dev, reason))
        print(f"[X] {dev:25} | FAILED ({reason})")

print(f"\nAudit Result: {valid_count} / {len(files)} VALID")
print("Devices to re-capture:", [d[0] for d in invalid_devices])
