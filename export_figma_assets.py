import os
import shutil

BASE_DIR = r"d:\Project\APKMod\NavigationIQ"
OUTPUT_DIR = os.path.join(BASE_DIR, "design", "figma_assets")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# 1. Generate 512x512 App Icon SVGs
# NavigationIQ Arrow: Left Wing (#1B4332), Right Wing (#10B981), Spine (#FFFFFF, stroke-width=0.6, stroke-opacity=0.8)

SVG_SQUIRCLE = '''<svg width="512" height="512" viewBox="0 0 108 108" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="108" height="108" rx="24" fill="#FFFFFF"/>
  <path d="M 54 28 L 33 73 L 54 61.5 Z" fill="#1B4332"/>
  <path d="M 54 28 L 54 61.5 L 75 73 Z" fill="#10B981"/>
  <path d="M 54 28 L 54 61.5" stroke="#FFFFFF" stroke-width="0.6" stroke-opacity="0.8"/>
</svg>
'''

SVG_ROUND = '''<svg width="512" height="512" viewBox="0 0 108 108" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="54" cy="54" r="54" fill="#FFFFFF"/>
  <path d="M 54 28 L 33 73 L 54 61.5 Z" fill="#1B4332"/>
  <path d="M 54 28 L 54 61.5 L 75 73 Z" fill="#10B981"/>
  <path d="M 54 28 L 54 61.5" stroke="#FFFFFF" stroke-width="0.6" stroke-opacity="0.8"/>
</svg>
'''

SVG_ARROW_ONLY = '''<svg width="512" height="512" viewBox="0 0 108 108" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M 54 28 L 33 73 L 54 61.5 Z" fill="#1B4332"/>
  <path d="M 54 28 L 54 61.5 L 75 73 Z" fill="#10B981"/>
  <path d="M 54 28 L 54 61.5" stroke="#FFFFFF" stroke-width="0.6" stroke-opacity="0.8"/>
</svg>
'''

with open(os.path.join(OUTPUT_DIR, "01_app_icon_squircle_512.svg"), "w", encoding="utf-8") as f:
    f.write(SVG_SQUIRCLE)

with open(os.path.join(OUTPUT_DIR, "02_app_icon_round_512.svg"), "w", encoding="utf-8") as f:
    f.write(SVG_ROUND)

with open(os.path.join(OUTPUT_DIR, "03_nav_arrow_vector_transparent.svg"), "w", encoding="utf-8") as f:
    f.write(SVG_ARROW_ONLY)

# 2. Copy Existing Screen SVGs from design/
svg_sources = {
    "04_smartwatch_ui_suite.svg": os.path.join(BASE_DIR, "design", "smartwatch_ui_suite.svg"),
    "05_arrived_screen_round.svg": os.path.join(BASE_DIR, "design", "arrived_screen.svg"),
    "06_arrived_screen_square.svg": os.path.join(BASE_DIR, "design", "arrived_screen_square.svg"),
    "07_standby_init_screen.svg": os.path.join(BASE_DIR, "design", "init_screen.svg"),
}

for dest_name, src_path in svg_sources.items():
    if os.path.exists(src_path):
        shutil.copy2(src_path, os.path.join(OUTPUT_DIR, dest_name))

# 3. Copy Key High-Res Images & Screenshots
img_sources = {
    "08_hero_image_1440x720.png": os.path.join(BASE_DIR, "garmin_app", "store_assets", "hero_image_1440x720.png"),
    "09_store_cover_500x500.png": os.path.join(BASE_DIR, "garmin_app", "store_assets", "cover_image_500x500.png"),
    "10_navigation_iq_showcase_banner.png": os.path.join(BASE_DIR, "screenshots", "00_navigation_iq_showcase_banner.png"),
    "11_arrived_showcase.png": os.path.join(BASE_DIR, "screenshots", "arrived_showcase.png"),
    "12_round_navigation_hud.png": os.path.join(BASE_DIR, "garmin_app", "store_assets", "01_round_navigation_hud.png"),
    "13_square_navigation_hud.png": os.path.join(BASE_DIR, "garmin_app", "store_assets", "02_square_navigation_hud.png"),
}

for dest_name, src_path in img_sources.items():
    if os.path.exists(src_path):
        shutil.copy2(src_path, os.path.join(OUTPUT_DIR, dest_name))

print("Figma assets export completed successfully:")
for item in sorted(os.listdir(OUTPUT_DIR)):
    print(f" - {item} ({os.path.getsize(os.path.join(OUTPUT_DIR, item))} bytes)")
