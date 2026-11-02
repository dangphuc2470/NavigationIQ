import os
import glob
from PIL import Image

SCREENSHOTS_DIR = r"d:\Project\APKMod\NavigationIQ\garmin_app\screenshots\normal"

def analyze_image(path):
    size = os.path.getsize(path)
    if size < 40000:
        return "TOO_SMALL"
        
    try:
        im = Image.open(path).convert("RGB")
        w, h = im.size
        # Sample center region (watch screen)
        cx, cy = w // 2, h // 2
        center_box = im.crop((cx - 40, cy - 40, cx + 40, cy + 40))
        colors = center_box.getcolors(maxcolors=10000)
        
        # Check if screen is mostly uniform grey (empty simulator window)
        # Empty simulator grey is around (210-230, 210-230, 210-230)
        dominant_color = max(colors, key=lambda item: item[0])
        dom_rgb = dominant_color[1]
        dom_count = dominant_color[0]
        total_pixels = 80 * 80
        
        if dom_count > total_pixels * 0.85 and 200 <= dom_rgb[0] <= 245 and 200 <= dom_rgb[1] <= 245:
            return "WHITE_OR_GREY_WINDOW"
            
        # Check for Garmin blue logo splash: RGB around (0, 110-140, 180-220)
        has_garmin_blue = False
        for count, rgb in colors:
            if rgb[0] < 30 and 100 <= rgb[1] <= 160 and 170 <= rgb[2] <= 230:
                has_garmin_blue = True
                break
                
        if has_garmin_blue and dom_count > total_pixels * 0.5 and (dom_rgb[0] < 30 or dom_rgb[0] > 200):
            return "GARMIN_SPLASH_LOGO"
            
        return "OK"
    except Exception as e:
        return f"ERROR: {e}"

files = sorted(glob.glob(os.path.join(SCREENSHOTS_DIR, "*.png")))
print(f"Total screenshots analyzed: {len(files)}\n")

bad_devices = []
for f in files:
    dev = os.path.basename(f)[:-4]
    status = analyze_image(f)
    if status != "OK":
        bad_devices.append((dev, status, os.path.getsize(f)))
        print(f"[X] {dev:25} | Status: {status:22} | Size: {os.path.getsize(f)} bytes")
    else:
        print(f"[V] {dev:25} | OK ({os.path.getsize(f)} bytes)")

print(f"\nTotal BAD devices: {len(bad_devices)} / {len(files)}")
print("Bad device IDs:", [b[0] for b in bad_devices])
