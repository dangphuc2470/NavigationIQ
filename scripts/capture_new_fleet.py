import os, subprocess, shutil, time, sys
from PIL import Image

sys.stdout.reconfigure(encoding="utf-8")

PROJECT_ROOT = r"d:\Project\APKMod\NavigationIQ"
GARMIN_DIR = os.path.join(PROJECT_ROOT, "garmin_app")
NORMAL_DIR = os.path.join(GARMIN_DIR, "screenshots", "normal")
GALLERY_DIR = os.path.join(PROJECT_ROOT, "screenshots", "gallery")

# Device to folder mapping
NEW_DEVICES = {
    # venu_vivoactive
    "venu": "venu_vivoactive",
    # forerunner
    "fr245": "forerunner",
    "fr745": "forerunner",
    "fr945": "forerunner",
    # fenix_epix_enduro
    "fenix6": "fenix_epix_enduro",
    "fenix6s": "fenix_epix_enduro",
    "fenix6xpro": "fenix_epix_enduro",
    # specialty
    "d2airx10": "specialty",
    "descentmk2": "specialty",
    "marqathlete": "specialty"
}

def verify_hud_image(path):
    if not os.path.exists(path) or os.path.getsize(path) < 25000:
        return False, "FILE_MISSING_OR_TOO_SMALL"
    im = Image.open(path).convert("RGB")
    w, h = im.size
    cx = w // 2
    col = [im.getpixel((cx, y))[:3] for y in range(h)]
    
    # 1. White screen check
    white_run = 0
    max_white_run = 0
    for r, g, b in col:
        if r > 245 and g > 245 and b > 245:
            white_run += 1
            if white_run > max_white_run:
                max_white_run = white_run
        else:
            white_run = 0
    if max_white_run > (h * 0.40):
        return False, f"BLANK_WHITE_SCREEN (white_run={max_white_run})"

    # 2. Blue boot triangle
    blue_triangle_px = 0
    for y in range(int(h * 0.35), int(h * 0.65), 2):
        for x in range(int(w * 0.35), int(w * 0.65), 2):
            r, g, b = im.getpixel((x, y))[:3]
            if r < 50 and g > 60 and b > 110:
                blue_triangle_px += 1
    if blue_triangle_px > 300:
        return False, f"GARMIN_BOOT_TRIANGLE (blue_px={blue_triangle_px})"

    # 3. Text in lower screen
    lower_text_px = 0
    for y in range(int(h * 0.40), int(h * 0.75), 2):
        for x in range(int(w * 0.20), int(w * 0.80), 2):
            r, g, b = im.getpixel((x, y))[:3]
            if r > 180 and g > 180 and b > 180:
                lower_text_px += 1
    if lower_text_px < 10:
        return False, f"NO_LOWER_STREET_TEXT (text_px={lower_text_px})"

    # 4. Upper active content
    upper_active_px = 0
    for y in range(int(h * 0.20), int(h * 0.48), 2):
        for x in range(int(w * 0.20), int(w * 0.80), 2):
            r, g, b = im.getpixel((x, y))[:3]
            if (r > 170 and g > 170 and b > 170) or (g > 80 and g > r + 20 and g > b):
                upper_active_px += 1
    if upper_active_px < 10:
        return False, f"NO_UPPER_CONTENT (active_px={upper_active_px})"

    return True, f"VALID_HUD (upper={upper_active_px}, lower={lower_text_px})"

print(f"Starting capture for {len(NEW_DEVICES)} new devices...")

for idx, (dev, folder) in enumerate(NEW_DEVICES.items(), 1):
    print(f"\n[{idx}/{len(NEW_DEVICES)}] Processing {dev} ({folder})...")
    shot_path = os.path.join(NORMAL_DIR, f"{dev}.png")
    dest_path = os.path.join(GALLERY_DIR, folder, f"{dev}.png")
    
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
            print(f"  [SUCCESS] {dev} is VALID HUD on attempt {attempt}: {msg}")
            shutil.copy2(shot_path, dest_path)
            print(f"  [SAVED] {dest_path}")
            break
        else:
            print(f"  [RETRY] Attempt {attempt} failed ({msg}). Retrying...")

print("\nAll new fleet devices captured and verified successfully!")
