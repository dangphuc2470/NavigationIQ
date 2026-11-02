import os
import sys
import time
import subprocess
from PIL import Image

sys.stdout.reconfigure(encoding='utf-8')

PROJECT_ROOT = r"d:\Project\APKMod\NavigationIQ"
GARMIN_DIR = os.path.join(PROJECT_ROOT, "garmin_app")
SCREENSHOTS_DIR = os.path.join(GARMIN_DIR, "screenshots", "normal")
SDK_BIN = os.path.expandvars(r"%APPDATA%\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin")
MONKEYC = os.path.join(SDK_BIN, "monkeyc.bat")
KEY = os.path.join(GARMIN_DIR, "developer_key.der")
JUNGLE = os.path.join(GARMIN_DIR, "monkey.jungle")
BIN_DIR = os.path.join(GARMIN_DIR, "bin")

from deep_audit import check_nav_hud

DEVICES_TO_FIX = [
    'd2mach1', 'd2mach2pro', 'descentmk343mm', 'enduro', 'epix2', 
    'epix2pro42mm', 'fenix843mm', 'fenix8solar51mm', 'fr165', 'fr255', 
    'fr265', 'fr265s', 'fr965', 'instinctcrossover', 'venu2', 
    'venu2s', 'venusq', 'venusq2', 'venux1', 'vivoactive5'
]

print(f"Starting dedicated re-capture with 6s settle time for {len(DEVICES_TO_FIX)} devices...")

for idx, dev in enumerate(DEVICES_TO_FIX, 1):
    print(f"\n[{idx}/{len(DEVICES_TO_FIX)}] Processing {dev}...")
    shot_path = os.path.join(SCREENSHOTS_DIR, f"{dev}.png")
    
    # We call preview_fleet.ps1 for single device with 6 seconds wait time
    ps_cmd = [
        "powershell", "-ExecutionPolicy", "Bypass",
        "-File", os.path.join(GARMIN_DIR, "preview_fleet.ps1"),
        "-DeviceList", dev,
        "-Mode", "normal",
        "-WaitSeconds", "6"
    ]
    
    # Retry loop (up to 2 attempts)
    success = False
    for attempt in range(1, 3):
        res = subprocess.run(ps_cmd, cwd=GARMIN_DIR, capture_output=True, text=True)
        time.sleep(1)
        
        if os.path.exists(shot_path):
            ok, reason = check_nav_hud(shot_path)
            if ok:
                print(f"  [SUCCESS] {dev} is VALID Navigation HUD on attempt {attempt}")
                success = True
                break
            else:
                print(f"  [RETRY] Attempt {attempt} failed ({reason}), retrying with longer delay...")
                time.sleep(2)
        else:
            print(f"  [RETRY] Screenshot file not found, retrying...")
            time.sleep(2)
            
    if not success:
        print(f"  [WARNING] {dev} could not achieve valid HUD after 2 attempts.")

print("\nRe-capture loop finished. Running final audit...")
