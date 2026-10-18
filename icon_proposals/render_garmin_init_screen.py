import os
import math
from datetime import datetime
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = r"d:\Project\APKMod\NavigationIQ\screenshots"
os.makedirs(OUT_DIR, exist_ok=True)

# Exact colors from UiConstants.mc
COLOR_BG_AMOLED = (0, 0, 0, 255)
COLOR_BG_CARD = (24, 24, 27, 255)         # 0x18181B
COLOR_BORDER_CARD = (39, 39, 42, 255)     # 0x27272A
COLOR_TEXT_WHITE = (255, 255, 255, 255)
COLOR_TEXT_SILVER = (228, 228, 231, 255)  # 0xE4E4E7
COLOR_TEXT_MUTED = (113, 113, 122, 255)   # 0x71717A
COLOR_GREEN_ACCENT = (16, 185, 129, 255)  # 0x10B981
GLOW_RGB_GREEN = (16, 144, 85)            # [0x10, 0x90, 0x55]

SCALE = 4  # 4x supersampling for high fidelity

def draw_ambient_glow(img, cx, cy, radius, rgb_glow):
    """Replicates VectorArrowRenderer.drawAmbientGlow."""
    glow_layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow_layer)
    steps = 45
    for i in range(steps, 0, -1):
        cur_r = radius * (i / steps) * 2.2
        alpha = int(45 * (1.0 - (i / steps)) ** 1.8)
        color = (rgb_glow[0], rgb_glow[1], rgb_glow[2], alpha)
        draw.ellipse([cx - cur_r, cy - cur_r, cx + cur_r, cy + cur_r], fill=color)
    img.alpha_composite(glow_layer)

def render_idle_screen(target_w, target_h, is_round, output_filename, time_str="20:35"):
    w = target_w * SCALE
    h = target_h * SCALE
    
    img = Image.new("RGBA", (w, h), COLOR_BG_AMOLED)
    
    # Clip for circular watches
    if is_round:
        mask = Image.new("L", (w, h), 0)
        draw_m = ImageDraw.Draw(mask)
        draw_m.ellipse([0, 0, w, h], fill=255)
    
    cx = w // 2
    cy = int(h * 0.38)
    r = int(w * 0.13)
    if r < 24 * SCALE: r = 24 * SCALE
    if r > 50 * SCALE: r = 50 * SCALE
    
    # 1. Ambient Glow (Green)
    draw_ambient_glow(img, cx, cy, r, GLOW_RGB_GREEN)
    
    draw = ImageDraw.Draw(img)
    
    # 2. Top Status Pill ("Ready" / "Connected")
    pill_h = int(h * 0.082)
    if pill_h < 24 * SCALE: pill_h = 24 * SCALE
    if pill_h > 32 * SCALE: pill_h = 32 * SCALE
    pill_w = int(105 * SCALE)
    pill_x = (w - pill_w) // 2
    pill_y = int(h * 0.08) if is_round else int(h * 0.05)
    
    draw.rounded_rectangle([pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=pill_h//2, fill=COLOR_BG_CARD, outline=COLOR_BORDER_CARD, width=int(1.5 * SCALE))
    # Green status dot
    dot_x = pill_x + int(14 * SCALE)
    dot_y = pill_y + pill_h // 2
    dot_r = int(3.5 * SCALE)
    draw.ellipse([dot_x - dot_r, dot_y - dot_r, dot_x + dot_r, dot_y + dot_r], fill=COLOR_GREEN_ACCENT)
    
    # Status text
    try:
        font_micro = ImageFont.truetype("arial.ttf", int(11 * SCALE))
        font_bold = ImageFont.truetype("arialbd.ttf", int(18 * SCALE))
        font_street = ImageFont.truetype("arial.ttf", int(13 * SCALE))
    except:
        font_micro = ImageFont.load_default()
        font_bold = ImageFont.load_default()
        font_street = ImageFont.load_default()
        
    draw.text((pill_x + int(24 * SCALE), dot_y), "Ready", fill=COLOR_TEXT_WHITE, font=font_micro, anchor="lm")
    
    # 3. Center Circle Frame
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=COLOR_BG_CARD, outline=COLOR_BORDER_CARD, width=int(1.5 * SCALE))
    
    # 4. 2-Tone Navigation Arrowhead
    arrow_scale = (r / SCALE) / 46.0
    aY1 = int(26 * arrow_scale * SCALE)
    aX2 = int(20 * arrow_scale * SCALE)
    aY2 = int(20 * arrow_scale * SCALE)
    aY3 = int(10 * arrow_scale * SCALE)
    
    # Left wing (Pure White)
    draw.polygon([
        (cx, cy - aY1),
        (cx, cy + aY3),
        (cx - aX2, cy + aY2)
    ], fill=COLOR_TEXT_WHITE)
    
    # Right wing (Vivid Mint Green)
    draw.polygon([
        (cx, cy - aY1),
        (cx + aX2, cy + aY2),
        (cx, cy + aY3)
    ], fill=COLOR_GREEN_ACCENT)
    
    # Divider line
    draw.line([(cx, cy - aY1), (cx, cy + aY3)], fill=(255, 255, 255, 160), width=int(1.5 * SCALE))
    
    # 5. Titles
    title_y = cy + r + int(h * 0.07)
    sub_title_y = title_y + int(h * 0.075)
    
    draw.text((cx, title_y), "Navigation IQ", fill=COLOR_TEXT_WHITE, font=font_bold, anchor="mm")
    draw.text((cx, sub_title_y), "Waiting for navigation", fill=COLOR_TEXT_SILVER, font=font_street, anchor="mm")
    
    # 6. Bottom Time Pill
    bottom_w = int(85 * SCALE)
    bottom_h = pill_h
    bottom_x = (w - bottom_w) // 2
    bottom_y = int(h * 0.82) if is_round else int(h - bottom_h - h * 0.04)
    
    draw.rounded_rectangle([bottom_x, bottom_y, bottom_x + bottom_w, bottom_y + bottom_h], radius=bottom_h//2, fill=COLOR_BG_CARD, outline=COLOR_BORDER_CARD, width=int(1.5 * SCALE))
    draw.text((cx, bottom_y + bottom_h // 2), time_str, fill=COLOR_TEXT_SILVER, font=font_micro, anchor="mm")
    
    # Apply circular mask if round
    if is_round:
        final_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        final_img.paste(img, (0, 0), mask)
        res = final_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
    else:
        res = img.resize((target_w, target_h), Image.Resampling.LANCZOS)
        
    out_file = os.path.join(OUT_DIR, output_filename)
    res.save(out_file, "PNG")
    print(f"Saved init screen: {out_file}")
    return res

now_str = datetime.now().strftime("%H:%M")
# 1. Square AMOLED (Garmin Venu Sq 2 - 320x360)
render_idle_screen(320, 360, False, "garmin_init_venusq2_square.png", now_str)

# 2. Round AMOLED (Garmin Forerunner 965 / Fenix 7 - 454x454)
render_idle_screen(454, 454, True, "garmin_init_fr965_round.png", now_str)

# 3. Create Side-by-Side Comparison Exhibition Sheet
W, H = 1000, 560
sheet = Image.new("RGBA", (W, H), (15, 17, 20, 255))
d = ImageDraw.Draw(sheet)

d.text((40, 30), "Navigation IQ - Garmin Watch Idle Standby / Init Screen", fill=(255, 255, 255, 255))
d.text((40, 60), "Synchronized Green Mint Glow & 2-Tone Navigation Arrowhead across Square & Round displays", fill=(160, 170, 180, 255))

sq_img = Image.open(os.path.join(OUT_DIR, "garmin_init_venusq2_square.png"))
rd_img = Image.open(os.path.join(OUT_DIR, "garmin_init_fr965_round.png"))

# Paste Square
sheet.paste(sq_img, (120, 120))
d.text((280, 500), "Garmin Venu Sq 2 (Square AMOLED)", fill=(230, 230, 230, 255), anchor="mm")

# Paste Round
# Scale round down slightly to fit height nicely
rd_scaled = rd_img.resize((360, 360), Image.Resampling.LANCZOS)
sheet.paste(rd_scaled, (520, 120), rd_scaled)
d.text((700, 500), "Garmin FR965 / Fenix 7 (Round AMOLED/MIP)", fill=(230, 230, 230, 255), anchor="mm")

exhibit_path = os.path.join(OUT_DIR, "00_garmin_init_screen_showcase.png")
sheet.save(exhibit_path, "PNG")
print(f"Exhibit saved to: {exhibit_path}")
