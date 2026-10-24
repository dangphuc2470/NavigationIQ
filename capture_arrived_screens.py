import os
import sys
import subprocess
import time
import ctypes
from ctypes import wintypes

user32 = ctypes.windll.user32
WM_SETTEXT = 0x000C
BM_CLICK = 0x00F5
WM_COMMAND = 0x0111

java_bin = r'C:\Program Files\Android\Android Studio\jbr\bin'
sdk_bin = r'C:\Users\phucdnh\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2\bin'
sim_exe = os.path.join(sdk_bin, 'simulator.exe')
monkeyc_bat = os.path.join(sdk_bin, 'monkeyc.bat')
monkeydo_bat = os.path.join(sdk_bin, 'monkeydo.bat')

project_root = r'D:\Project\APKMod\NavigationIQ'
garmin_app = os.path.join(project_root, 'garmin_app')
jungle = os.path.join(garmin_app, 'monkey.jungle')
key = os.path.join(garmin_app, 'developer_key.der')
bin_dir = os.path.join(garmin_app, 'bin')
screenshots_dir = os.path.join(project_root, 'screenshots')

os.makedirs(bin_dir, exist_ok=True)
os.makedirs(screenshots_dir, exist_ok=True)

env = os.environ.copy()
env['PATH'] = java_bin + ';' + env.get('PATH', '')
env['JAVA_HOME'] = r'C:\Program Files\Android\Android Studio\jbr'

devices = [
    {
        'id': 'venu2',
        'out_png': os.path.join(screenshots_dir, 'arrived_venu2.png'),
        'desc': 'Round AMOLED 416x416 (Venu 2)'
    },
    {
        'id': 'venusq2',
        'out_png': os.path.join(screenshots_dir, 'arrived_venusq2.png'),
        'desc': 'Square AMOLED 320x360 (Venu Sq 2)'
    }
]

def compile_device(dev_id):
    prg_path = os.path.join(bin_dir, f'arrived_{dev_id}.prg')
    cmd = [
        'cmd', '/c', monkeyc_bat,
        '-o', prg_path,
        '-f', jungle,
        '-y', key,
        '-d', dev_id
    ]
    print(f"Compiling for {dev_id}...", flush=True)
    res = subprocess.run(cmd, cwd=garmin_app, env=env, capture_output=True, text=True)
    if res.returncode == 0:
        print(f"  [OK] Compile {dev_id} successful: {prg_path}", flush=True)
        return prg_path
    else:
        print(f"  [ERR] Failed to compile {dev_id}:\n{res.stdout}\n{res.stderr}", flush=True)
        return None

def capture_sim_screenshot(sim_proc, target_png):
    target_hwnd = None
    def enum_cb(hwnd, lparam):
        nonlocal target_hwnd
        pid = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        if pid.value == sim_proc.pid and user32.IsWindowVisible(hwnd):
            buf = ctypes.create_unicode_buffer(256)
            user32.GetWindowTextW(hwnd, buf, 256)
            if 'CIQ Simulator' in buf.value:
                target_hwnd = hwnd
        return True

    WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
    for _ in range(20):
        user32.EnumWindows(WNDENUMPROC(enum_cb), 0)
        if target_hwnd:
            break
        time.sleep(0.5)

    if not target_hwnd:
        print("Could not find CIQ Simulator window!", flush=True)
        return False

    # Send Save Screen Capture command (ID 5003)
    user32.PostMessageW(target_hwnd, WM_COMMAND, 5003, 0)
    time.sleep(1.5)

    # Find Save Screenshot dialog
    dlg_hwnd = None
    def find_dlg(hwnd, lparam):
        nonlocal dlg_hwnd
        pid = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
        if pid.value == sim_proc.pid and user32.IsWindowVisible(hwnd):
            buf = ctypes.create_unicode_buffer(256)
            user32.GetWindowTextW(hwnd, buf, 256)
            if 'Save Screenshot' in buf.value:
                dlg_hwnd = hwnd
        return True

    for _ in range(10):
        user32.EnumWindows(WNDENUMPROC(find_dlg), 0)
        if dlg_hwnd:
            break
        time.sleep(0.5)

    if not dlg_hwnd:
        print("Save Screenshot dialog did not appear!", flush=True)
        return False

    edit_hwnd = None
    save_btn = None
    def find_ctrls(hwnd, _):
        nonlocal edit_hwnd, save_btn
        cls_buf = ctypes.create_unicode_buffer(256)
        user32.GetClassNameW(hwnd, cls_buf, 256)
        ctrl_id = user32.GetDlgCtrlID(hwnd)
        if cls_buf.value == 'Edit' and ctrl_id == 1001:
            edit_hwnd = hwnd
        if cls_buf.value == 'Button' and ctrl_id == 1:
            save_btn = hwnd
        return True

    user32.EnumChildWindows(dlg_hwnd, WNDENUMPROC(find_ctrls), 0)
    if not (edit_hwnd and save_btn):
        print(f"Could not locate controls: edit={edit_hwnd}, save={save_btn}", flush=True)
        return False

    abs_target = os.path.abspath(target_png)
    if os.path.exists(abs_target):
        try: os.remove(abs_target)
        except: pass

    user32.SendMessageW(edit_hwnd, WM_SETTEXT, 0, abs_target)
    time.sleep(0.5)
    user32.SendMessageW(save_btn, BM_CLICK, 0, 0)
    time.sleep(2.0)

    if os.path.exists(abs_target) and os.path.getsize(abs_target) > 500:
        print(f"  [V] Captured {abs_target} ({os.path.getsize(abs_target)} bytes)", flush=True)
        return True
    else:
        print(f"  [!] Failed to save {abs_target}", flush=True)
        return False

def main():
    print("=== STARTING ARRIVED SCREENSHOT CAPTURE ===", flush=True)

    # Temporary swap step 0 in PreviewManager.mc to DIR_ARRIVED
    pm_file = os.path.join(garmin_app, 'source', 'PreviewManager.mc')
    with open(pm_file, 'r', encoding='utf-8') as f:
        orig_pm = f.read()

    arrived_pm = orig_pm.replace(
        'DIR_STRAIGHT,\n            "2.8 km",\n            "Continue straight on Highway 1 towards City Center",\n            "17:48",\n            0',
        'DIR_ARRIVED,\n            "22 m",\n            "123 Nguyen Thi Minh Khai, Q.1",\n            "Arrived",\n            0'
    )
    with open(pm_file, 'w', encoding='utf-8') as f:
        f.write(arrived_pm)

    try:
        # 1. Compile PRGs
        compiled_prgs = {}
        for d in devices:
            prg = compile_device(d['id'])
            if prg:
                compiled_prgs[d['id']] = prg
    finally:
        with open(pm_file, 'w', encoding='utf-8') as f:
            f.write(orig_pm)

    # 2. Run simulator & capture each
    for d in devices:
        dev_id = d['id']
        prg = compiled_prgs.get(dev_id)
        if not prg:
            continue

        print(f"\n--- Running simulator for {dev_id} ({d['desc']}) ---", flush=True)
        sim_proc = subprocess.Popen([sim_exe], cwd=sdk_bin, env=env)
        time.sleep(3.5)

        app_proc = subprocess.Popen(['cmd', '/c', monkeydo_bat, prg, dev_id], cwd=garmin_app, env=env)
        time.sleep(4.0)

        capture_sim_screenshot(sim_proc, d['out_png'])

        # Cleanup
        try:
            app_proc.terminate()
            time.sleep(0.5)
            sim_proc.terminate()
            time.sleep(1.0)
        except:
            pass

        subprocess.run(['taskkill', '/F', '/IM', 'simulator.exe'], capture_output=True)
        time.sleep(1.0)

    print("\n=== ALL CAPTURES COMPLETE ===", flush=True)

if __name__ == '__main__':
    main()
