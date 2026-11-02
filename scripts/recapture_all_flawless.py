import os
import sys
import time
import shutil
import subprocess
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

PROJECT_ROOT = r"d:\Project\APKMod\NavigationIQ"
GARMIN_DIR = os.path.join(PROJECT_ROOT, "garmin_app")
NORMAL_DIR = os.path.join(GARMIN_DIR, "screenshots", "normal")
GALLERY_DIR = os.path.join(PROJECT_ROOT, "screenshots", "gallery")

DEVICE_MAPPING = {
    # fenix_epix_enduro
    'enduro3': 'fenix_epix_enduro',
    'epix2pro47mm': 'fenix_epix_enduro',
    'epix2pro51mm': 'fenix_epix_enduro',
    'fenix7': 'fenix_epix_enduro',
    'fenix7s': 'fenix_epix_enduro',
    'fenix847mm': 'fenix_epix_enduro',
    'fenix8solar47mm': 'fenix_epix_enduro',
    'fenixe': 'fenix_epix_enduro',
    # forerunner
    'fr255s': 'forerunner',
    # instinct
    'instinct2s': 'instinct',
    'instincte45mm': 'instinct',
    # specialty
    'd2mach2': 'specialty',
    # venu_vivoactive
    'venu2plus': 'venu_vivoactive',
    'venu3': 'venu_vivoactive',
    'venu3s': 'venu_vivoactive',
}

def verify_hud_image(path):
    if not os.path.exists(path) or os.path.getsize(path) < 30000:
        return False, "FILE_MISSING_OR_TOO_SMALL"
        
    im = Image.open(path).convert('RGB')
    w, h = im.size
    
    # Scan vertical line at cx
    cx = w // 2
    col = [im.getpixel((cx, y))[:3] for y in range(h)]
    
    # 1. Blank white screen check:
    # A blank white screen has long continuous run of pure white pixels (255, 255, 255)
    white_run = 0
    max_white_run = 0
    for r, g, b in col:
        if r > 245 and g > 245 and b > 245:
            white_run += 1
            if white_run > max_white_run:
                max_white_run = white_run
        else:
            white_run = 0
            
    if max_white_run > 120:
        return False, f"BLANK_WHITE_SCREEN (white_run={max_white_run})"
        
    # 2. Garmin Blue Boot Triangle check:
    # Triangle has cyan-blue pixels (r < 50, g > 70, b > 120)
    blue_triangle_px = 0
    for y in range(int(h * 0.25), int(h * 0.75), 2):
        for x in range(int(w * 0.25), int(w * 0.75), 2):
            r, g, b = im.getpixel((x, y))[:3]
            if r < 50 and g > 60 and b > 110:
                blue_triangle_px += 1
                
    if blue_triangle_px > 300:
        return False, f"GARMIN_BOOT_TRIANGLE (blue_px={blue_triangle_px})"
        
    # 3. Check for text in lower screen (street name and ETA):
    # In both AMOLED and MIP, "Turn right onto" and "Main Street" are white text (r>180, g>180, b>180)
    lower_text_px = 0
    for y in range(int(h * 0.40), int(h * 0.75), 2):
        for x in range(int(w * 0.20), int(w * 0.80), 2):
            r, g, b = im.getpixel((x, y))[:3]
            if r > 180 and g > 180 and b > 180:
                lower_text_px += 1
                
    if lower_text_px < 15:
        return False, f"NO_LOWER_STREET_TEXT (text_px={lower_text_px})"
        
    # 4. Check for top badge or distance number:
    upper_active_px = 0
    for y in range(int(h * 0.20), int(h * 0.48), 2):
        for x in range(int(w * 0.20), int(w * 0.80), 2):
            r, g, b = im.getpixel((x, y))[:3]
            # White text or green turn icon
            if (r > 170 and g > 170 and b > 170) or (g > 80 and g > r + 20 and g > b):
                upper_active_px += 1
                
    if upper_active_px < 15:
        return False, f"NO_UPPER_CONTENT (active_px={upper_active_px})"
        
    return True, f"VALID_HUD (upper={upper_active_px}, lower={lower_text_px}, white_run={max_white_run})"

print(f"Starting dedicated flawless recapture for {len(DEVICE_MAPPING)} devices...")

for idx, (dev, folder) in enumerate(DEVICE_MAPPING.items(), 1):
    print(f"\n[{idx}/{len(DEVICE_MAPPING)}] Processing device: {dev} (Category: {folder})...")
    
    shot_path = os.path.join(NORMAL_DIR, f"{dev}.png")
    dest_path = os.path.join(GALLERY_DIR, folder, f"{dev}.png")
    
    # Check if fenixe was already captured successfully in normal dir
    if dev == 'fenixe' and os.path.exists(shot_path):
        ok, msg = verify_hud_image(shot_path)
        if ok:
            print(f"  [ALREADY_OK] fenixe verified: {msg}")
            shutil.copy2(shot_path, dest_path)
            continue

    # Attempt capture with 12s, if needed retry with 15s
    for attempt, wait_s in enumerate([12, 16], 1):
        print(f"  Attempt {attempt}: Capturing with {wait_s}s settle time...")
        ps_cmd = [
            "powershell", "-ExecutionPolicy", "Bypass",
            "-File", os.path.join(GARMIN_DIR, "preview_fleet.ps1"),
            "-DeviceList", dev,
            "-Mode", "normal",
            "-WaitSeconds", str(wait_s),
            "-KeepSimulatorOpen"
        ]
        
        subprocess.run(ps_cmd, cwd=GARMIN_DIR, capture_output=True, text=True)
        time.sleep(1)
        
        ok, msg = verify_hud_image(shot_path)
        if ok:
            print(f"  [SUCCESS] {dev} is VALID Navigation HUD on attempt {attempt}: {msg}")
            shutil.copy2(shot_path, dest_path)
            print(f"  [OK] Copied to gallery: {dest_path}")
            break
        else:
            print(f"  [RETRY] Attempt {attempt} failed ({msg}). Retrying...")
            time.sleep(2)
            
print("\nAll target devices processed. Running full gallery audit across all 53 devices...")

# Final verification across all 53 devices in gallery
all_gallery = []
for root, dirs, files in os.walk(GALLERY_DIR):
    for f in files:
        if f.endswith('.png'):
            all_gallery.append(os.path.join(root, f))

all_gallery.sort()
failed = []
passed = 0

print(f"\n=======================================================")
print(f" FINAL COMPREHENSIVE AUDIT OF ALL {len(all_gallery)} GALLERY IMAGES")
print(f"=======================================================")

for p in all_gallery:
    dname = os.path.basename(p)[:-4]
    ok, msg = verify_hud_image(p)
    if ok:
        passed += 1
        print(f" [PASS] {dname:25} | {msg}")
    else:
        failed.append((dname, msg, p))
        print(f" [FAIL] {dname:25} | {msg}")

print(f"\nAudit complete: {passed} / {len(all_gallery)} VALID")
if failed:
    print(f"WARNING: {len(failed)} devices still failed:")
    for f in failed:
        print(f"  - {f[0]}: {f[1]}")
else:
    print("ALL 53 DEVICES CONFIRMED 100% FLAWLESS NAVIGATION HUD!")
