"""
Generate and update the 1440x720 Hero Banner for Garmin Connect IQ Store and GitHub README.

Composites:
1. Left marketing copy with customizable bullets and Inter-Medium typography.
2. Center Android Companion phone mockup.
3. Background Square watch (e.g. Venu Sq 2 Destination Reached screen).
4. Foreground Round watch (e.g. Forerunner 965 Green HUD screen) with bezel and drop shadows.
"""

import os
import shutil
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Asset Paths
HERO_BASE_PATH = os.path.join(BASE_DIR, "screenshots", "hero_image_1440x720.png")
ROUND_HUD_PATH = os.path.join(BASE_DIR, "screenshots", "real_sim", "real_fr965_02_hud.png")
SQUARE_HUD_PATH = os.path.join(BASE_DIR, "screenshots", "arrived_venusq2.png")

# Output destinations
TARGETS = [
    os.path.join(BASE_DIR, "screenshots", "hero_image_1440x720.png"),
    os.path.join(BASE_DIR, "garmin_app", "store_assets", "hero_image_1440x720.png"),
    os.path.join(BASE_DIR, "docs", "assets", "hero_image_1440x720.png"),
    os.path.join(BASE_DIR, "design", "figma_assets", "08_hero_image_1440x720.png"),
]

def generate_hero_banner(
    bullet_4_text="Trip summary screen with arrival statistics",
    round_hud_path=ROUND_HUD_PATH,
    square_hud_path=SQUARE_HUD_PATH,
):
    if not os.path.exists(HERO_BASE_PATH):
        raise FileNotFoundError(f"Base hero image not found: {HERO_BASE_PATH}")

    hero = Image.open(HERO_BASE_PATH).convert("RGBA")
    result = hero.copy()

    # 1. Update Bullet 4 text on the left panel
    draw = ImageDraw.Draw(result)
    font_path = "C:/Windows/Fonts/Inter-Medium.ttf"
    if not os.path.exists(font_path):
        font_path = "C:/Windows/Fonts/segoeui.ttf"
    font = ImageFont.truetype(font_path, 17)

    # Clear old bullet 4 text area
    draw.rectangle([(80, 440), (510, 472)], fill=(10, 13, 12, 255))
    draw.text((83, 445), bullet_4_text, font=font, fill=(228, 228, 231, 255))

    # 2. Square watch (Venu Sq 2)
    if os.path.exists(square_hud_path):
        vsq2 = Image.open(square_hud_path).convert("RGBA")
        sw_x, sw_y = 738, 189
        sw_w, sw_h = 318, 356
        vsq2_resized = vsq2.resize((sw_w, sw_h), Image.Resampling.LANCZOS)
        mask_sq = Image.new("L", (sw_w, sw_h), 0)
        draw_sq_mask = ImageDraw.Draw(mask_sq)
        draw_sq_mask.rounded_rectangle([(0, 0), (sw_w, sw_h)], radius=32, fill=255)

        # Apply soft radial shadow from the round watch rim onto the square watch
        cx, cy = 1160, 360
        r_bezel = 229

        vsq2_arr = np.array(vsq2_resized, dtype=float)
        Y_sq, X_sq = np.ogrid[:sw_h, :sw_w]
        X_hero = X_sq + sw_x
        Y_hero = Y_sq + sw_y
        dist_sq = np.sqrt((X_hero - cx) ** 2 + (Y_hero - cy) ** 2)

        shadow_mask = (dist_sq >= r_bezel) & (dist_sq < r_bezel + 45)
        t = (dist_sq[shadow_mask] - r_bezel) / 45.0
        shadow_alpha = (1.0 - t) ** 1.8 * 0.70

        for c in range(3):
            vsq2_arr[:, :, c][shadow_mask] *= 1.0 - shadow_alpha

        vsq2_shaded = Image.fromarray(np.clip(vsq2_arr, 0, 255).astype(np.uint8))
        result.paste(vsq2_shaded, (sw_x, sw_y), mask_sq)

    # 3. Round watch (Forerunner 965 / Fenix 7)
    if os.path.exists(round_hud_path):
        fr965 = Image.open(round_hud_path).convert("RGBA")
        cx, cy = 1160, 360
        r_screen = 217
        r_bezel = 229

        # Resize HUD to fit circular display area
        fr965_resized = fr965.resize((r_screen * 2, r_screen * 2), Image.Resampling.LANCZOS)
        mask_round = Image.new("L", (r_screen * 2, r_screen * 2), 0)
        draw_mask = ImageDraw.Draw(mask_round)
        draw_mask.ellipse((0, 0, r_screen * 2, r_screen * 2), fill=255)
        mask_round = mask_round.filter(ImageFilter.GaussianBlur(0.6))

        # Re-apply original metal bezel ring (r between r_screen-1 and r_bezel+1)
        Y, X = np.ogrid[:720, :1440]
        dist = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
        bezel_mask = ((dist >= r_screen - 1) & (dist <= r_bezel + 1)).astype(np.uint8) * 255
        bezel_mask_img = Image.fromarray(bezel_mask)

        result.paste(hero, (0, 0), bezel_mask_img)
        result.paste(fr965_resized, (cx - r_screen, cy - r_screen), mask_round)

    # Save to all target paths
    for target in TARGETS:
        target_dir = os.path.dirname(target)
        if os.path.exists(target_dir):
            result.save(target, format="PNG")
            print(f"Saved: {target}")

    return result

if __name__ == "__main__":
    generate_hero_banner()
