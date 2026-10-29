#!/usr/bin/env python3
"""
NavigationIQ - Unified Garmin Connect IQ Build Script
Builds official store package (.iq) and debug/sideload binaries (.prg)
for both Beta and Release (Production) editions.

Usage:
    python build_garmin.py beta
    python build_garmin.py release
    python build_garmin.py all
"""

import os
import sys
import re
import glob
import subprocess
import argparse

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
GARMIN_DIR = os.path.join(PROJECT_ROOT, "garmin_app")
MANIFEST_FILE = os.path.join(GARMIN_DIR, "manifest.xml")
JUNGLE_FILE = os.path.join(GARMIN_DIR, "monkey.jungle")
KEY_FILE = os.path.join(GARMIN_DIR, "developer_key.der")
BIN_DIR = os.path.join(GARMIN_DIR, "bin")

# Edition Configurations
CONFIGS = {
    "beta": {
        "name": "Beta Edition",
        "app_id": "e24767ea-b254-4f25-9391-ff4c409a037c",
        "output_iq": os.path.join(BIN_DIR, "NavigationIQ_Beta_v1.0.4.iq"),
        "description": "Garmin Connect IQ Store - Beta Testers Channel",
    },
    "release": {
        "name": "Official Release Edition",
        "app_id": "0da65dc3-6e66-4072-bd03-802b2b9c3807",
        "output_iq": os.path.join(BIN_DIR, "NavigationIQ_Release_v1.0.4.iq"),
        "description": "Garmin Connect IQ Store - Production Channel",
    }
}

def resolve_java():
    """Locate Android Studio JBR or system Java runtime."""
    candidates = [
        r"C:\Program Files\Android\Android Studio\jbr",
        r"C:\Program Files\Android\Android Studio1\jbr",
        os.environ.get("JAVA_HOME", "")
    ]
    for c in candidates:
        if c and os.path.exists(os.path.join(c, "bin", "java.exe")):
            return c
    return None

def resolve_garmin_sdk():
    """Locate the latest Garmin Connect IQ SDK monkeyc compiler."""
    appdata = os.environ.get("APPDATA", "")
    sdks_root = os.path.join(appdata, "Garmin", "ConnectIQ", "Sdks")
    if not os.path.exists(sdks_root):
        return None

    # Search for all connectiq-sdk-win-* folders, sorted descending by version
    matches = glob.glob(os.path.join(sdks_root, "connectiq-sdk-win-*", "bin", "monkeyc.bat"))
    if matches:
        matches.sort(reverse=True)
        return matches[0]
    return None

def set_manifest_app_id(target_app_id):
    """Update application id in manifest.xml while preserving XML formatting."""
    with open(MANIFEST_FILE, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = r'(<iq:application\s+id=")[^"]+(")'
    match = re.search(pattern, content)
    if not match:
        raise RuntimeError("Could not find <iq:application id=\"...\"> in manifest.xml")

    updated = re.sub(pattern, rf'\g<1>{target_app_id}\g<2>', content)
    with open(MANIFEST_FILE, "w", encoding="utf-8") as f:
        f.write(updated)
    return target_app_id

def get_manifest_app_id():
    """Read current application id from manifest.xml."""
    with open(MANIFEST_FILE, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r'<iq:application\s+id="([^"]+)"', content)
    return match.group(1) if match else None

def build_edition(edition_key, monkeyc_path, java_home, build_sideload_devices=None):
    cfg = CONFIGS[edition_key]
    print("=" * 70)
    print(f"Building: {cfg['name']}")
    print(f"Channel : {cfg['description']}")
    print(f"App UUID: {cfg['app_id']}")
    print("=" * 70)

    # 1. Update manifest.xml with the target App UUID
    print(f"[*] Applying App UUID to manifest.xml...")
    set_manifest_app_id(cfg["app_id"])
    print(f"    [OK] manifest.xml updated with ID: {cfg['app_id']}")

    # Prepare environment
    env = os.environ.copy()
    if java_home:
        env["JAVA_HOME"] = java_home
        env["PATH"] = os.path.join(java_home, "bin") + ";" + env.get("PATH", "")

    os.makedirs(BIN_DIR, exist_ok=True)

    # 2. Build .iq package for Connect IQ Store
    out_iq = cfg["output_iq"]
    print(f"\n[*] Packaging Connect IQ Store file (.iq)...")
    print(f"    Output: {out_iq}")
    
    cmd_iq = [
        "cmd", "/c", monkeyc_path,
        "-e",
        "-r",
        "-w",
        "-o", out_iq,
        "-f", JUNGLE_FILE,
        "-y", KEY_FILE
    ]

    res = subprocess.run(cmd_iq, cwd=GARMIN_DIR, env=env, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"    [ERROR] Build failed (code {res.returncode}):")
        if res.stdout:
            print(res.stdout)
        if res.stderr:
            print(res.stderr)
        return False

    size_mb = os.path.getsize(out_iq) / (1024 * 1024)
    print(f"    [SUCCESS] Package generated: {os.path.basename(out_iq)} ({size_mb:.2f} MB)")
    
    artifact_dir = r"C:\Users\phucdnh\.gemini\antigravity-ide\brain\3d2eab4b-8ff7-434d-8f30-db3ed9546551"
    if os.path.isdir(artifact_dir):
        import shutil
        dst = os.path.join(artifact_dir, os.path.basename(out_iq))
        shutil.copyfile(out_iq, dst)
        print(f"    [OK] Copied to artifact directory: {dst}")

    # 3. Optional: build sideload .prg for specific devices (e.g. venu2, venusq2)
    if build_sideload_devices:
        print(f"\n[*] Compiling sideload binaries (.prg)...")
        for dev_id in build_sideload_devices:
            suffix = "_beta" if edition_key == "beta" else ""
            out_prg = os.path.join(BIN_DIR, f"NavigationIQ_{dev_id}{suffix}.prg")
            cmd_prg = [
                "cmd", "/c", monkeyc_path,
                "-o", out_prg,
                "-f", JUNGLE_FILE,
                "-y", KEY_FILE,
                "-d", dev_id
            ]
            r = subprocess.run(cmd_prg, cwd=GARMIN_DIR, env=env, capture_output=True, text=True)
            if r.returncode == 0:
                p_size = os.path.getsize(out_prg) / 1024
                print(f"    [+] {dev_id:10} -> {os.path.basename(out_prg)} ({p_size:.1f} KB)")
            else:
                print(f"    [-] Failed to compile .prg for {dev_id}")

    return True

def main():
    parser = argparse.ArgumentParser(description="Build Garmin Connect IQ NavigationIQ packages.")
    parser.add_argument("target", choices=["beta", "release", "all"], default="beta", nargs="?",
                        help="Target edition to build: 'beta', 'release', or 'all' (default: beta)")
    parser.add_argument("--sideload", "-s", action="store_true",
                        help="Also compile sideload PRG binaries for venu2 and venusq2")
    args = parser.parse_args()

    java_home = resolve_java()
    if not java_home:
        print("[ERROR] Java runtime (JBR) not found. Please install Android Studio or set JAVA_HOME.")
        sys.exit(1)

    monkeyc_path = resolve_garmin_sdk()
    if not monkeyc_path:
        print("[ERROR] Garmin Connect IQ SDK monkeyc.bat not found in %APPDATA%/Garmin/ConnectIQ/Sdks")
        sys.exit(1)

    print(f"Environment detected:")
    print(f"  Java Home : {java_home}")
    print(f"  MonkeyC   : {monkeyc_path}")
    print(f"  Current ID: {get_manifest_app_id()}\n")

    sideload_devs = ["venu2", "venusq2"] if args.sideload else None

    if args.target == "all":
        targets = ["beta", "release"]
    else:
        targets = [args.target]

    success = True
    for t in targets:
        if not build_edition(t, monkeyc_path, java_home, sideload_devs):
            success = False
            break

    print("\n" + "=" * 70)
    if success:
        print("ALL BUILDS COMPLETED SUCCESSFULLY!")
        for t in targets:
            out_iq = CONFIGS[t]["output_iq"]
            if os.path.exists(out_iq):
                size_mb = os.path.getsize(out_iq) / (1024 * 1024)
                print(f"  - [{t.upper()}] {out_iq} ({size_mb:.2f} MB)")
        print("=" * 70)
        sys.exit(0)
    else:
        print("BUILD FAILED. Please review error log above.")
        print("=" * 70)
        sys.exit(1)

if __name__ == "__main__":
    main()
