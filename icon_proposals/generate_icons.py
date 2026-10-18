import os
import math
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = r"d:\Project\APKMod\NavigationIQ\icon_proposals"
os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 512
SCALE = 4
HI_SIZE = SIZE * SCALE  # 2048x2048

def create_base_canvas(bg_color):
    """Creates a clean rounded squircle icon canvas with 22% corner radius."""
    img = Image.new("RGBA", (HI_SIZE, HI_SIZE), (0, 0, 0, 0))
    mask = Image.new("L", (HI_SIZE, HI_SIZE), 0)
    draw_mask = ImageDraw.Draw(mask)
    r = int(HI_SIZE * 0.22)
    draw_mask.rounded_rectangle([0, 0, HI_SIZE, HI_SIZE], radius=r, fill=255)
    bg = Image.new("RGBA", (HI_SIZE, HI_SIZE), bg_color)
    img.paste(bg, (0, 0), mask)
    return img

def save_icon(img, name):
    res = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    png_path = os.path.join(OUT_DIR, f"{name}.png")
    res.save(png_path, "PNG")
    return res

# -------------------------------------------------------------
# ICON 01: Compass Chevron (Minimal Nordic Outdoor)
# -------------------------------------------------------------
def make_icon_01():
    img = create_base_canvas((15, 38, 28, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    r_outer = int(440 * SCALE) // 2
    
    # Subtle Compass Track
    draw.ellipse([cx - r_outer, cy - r_outer, cx + r_outer, cy + r_outer], outline=(255, 255, 255, 35), width=int(8 * SCALE))
    
    # 4 Cardinal tick marks
    tick_len = int(22 * SCALE)
    draw.line([cx, cy - r_outer - tick_len//2, cx, cy - r_outer + tick_len//2], fill=(34, 197, 94, 255), width=int(12 * SCALE))
    draw.line([cx + r_outer - tick_len//2, cy, cx + r_outer + tick_len//2, cy], fill=(255, 255, 255, 90), width=int(8 * SCALE))
    draw.line([cx, cy + r_outer - tick_len//2, cx, cy + r_outer + tick_len//2], fill=(255, 255, 255, 90), width=int(8 * SCALE))
    draw.line([cx - r_outer - tick_len//2, cy, cx - r_outer + tick_len//2, cy], fill=(255, 255, 255, 90), width=int(8 * SCALE))
    
    # Navigation Chevron
    angle = -math.pi / 4
    tip = (cx + int(160 * math.cos(angle) * SCALE), cy + int(160 * math.sin(angle) * SCALE))
    left = (cx + int(135 * math.cos(angle + 2.35) * SCALE), cy + int(135 * math.sin(angle + 2.35) * SCALE))
    right = (cx + int(135 * math.cos(angle - 2.35) * SCALE), cy + int(135 * math.sin(angle - 2.35) * SCALE))
    notch = (cx + int(42 * math.cos(angle + math.pi) * SCALE), cy + int(42 * math.sin(angle + math.pi) * SCALE))
    
    draw.polygon([tip, left, notch], fill=(245, 245, 240, 255))
    draw.polygon([tip, notch, right], fill=(34, 197, 94, 255))
    save_icon(img, "icon_01_compass_chevron")

# -------------------------------------------------------------
# ICON 02: Garmin Tactical Bezel (Fenix / Rugged Outdoor)
# -------------------------------------------------------------
def make_icon_02():
    img = create_base_canvas((18, 20, 24, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    r_bezel = int(450 * SCALE) // 2
    
    draw.ellipse([cx - r_bezel, cy - r_bezel, cx + r_bezel, cy + r_bezel], outline=(255, 255, 255, 25), width=int(12 * SCALE))
    
    for i in range(12):
        a = i * (math.pi / 6)
        r_in = r_bezel - int(15 * SCALE)
        r_out = r_bezel + int(15 * SCALE)
        x1 = cx + int(r_in * math.cos(a))
        y1 = cy + int(r_in * math.sin(a))
        x2 = cx + int(r_out * math.cos(a))
        y2 = cy + int(r_out * math.sin(a))
        color = (16, 185, 129, 255) if i == 0 else (255, 255, 255, 75)
        draw.line([x1, y1, x2, y2], fill=color, width=int(8 * SCALE))
        
    tip = (cx, cy - int(145 * SCALE))
    l_wing = (cx - int(110 * SCALE), cy + int(95 * SCALE))
    r_wing = (cx + int(110 * SCALE), cy + int(95 * SCALE))
    inner = (cx, cy + int(35 * SCALE))
    
    draw.polygon([tip, l_wing, inner], fill=(16, 185, 129, 255))
    draw.polygon([tip, inner, r_wing], fill=(52, 211, 153, 255))
    draw.line([tip, inner], fill=(255, 255, 255, 200), width=int(5 * SCALE))
    save_icon(img, "icon_02_garmin_tactical_bezel")

# -------------------------------------------------------------
# ICON 03: The "N" Turn Route (Brand Monogram + Route Path)
# -------------------------------------------------------------
def make_icon_03():
    img = create_base_canvas((20, 52, 38, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    w = int(34 * SCALE)
    spacing_x = int(95 * SCALE)
    h_y = int(110 * SCALE)
    
    r_dot = int(28 * SCALE)
    draw.ellipse([cx - spacing_x - r_dot, cy + h_y - r_dot, cx - spacing_x + r_dot, cy + h_y + r_dot], fill=(34, 197, 94, 255))
    
    draw.line([cx - spacing_x, cy + h_y, cx - spacing_x, cy - h_y], fill=(255, 255, 255, 140), width=w)
    draw.line([cx - spacing_x, cy - h_y, cx + spacing_x, cy + h_y], fill=(34, 197, 94, 255), width=w)
    draw.line([cx + spacing_x, cy + h_y, cx + spacing_x, cy - int(80 * SCALE)], fill=(255, 255, 255, 255), width=w)
    
    tip = (cx + spacing_x, cy - int(160 * SCALE))
    l_arrow = (cx + spacing_x - int(50 * SCALE), cy - int(75 * SCALE))
    r_arrow = (cx + spacing_x + int(50 * SCALE), cy - int(75 * SCALE))
    draw.polygon([tip, l_arrow, r_arrow], fill=(255, 255, 255, 255))
    save_icon(img, "icon_03_stylized_n_route")

# -------------------------------------------------------------
# ICON 04: Venu Sq Cockpit (Clean Square AMOLED Turn)
# -------------------------------------------------------------
def make_icon_04():
    img = create_base_canvas((18, 24, 22, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    box_r = int(380 * SCALE) // 2
    draw.rounded_rectangle([cx - box_r, cy - box_r, cx + box_r, cy + box_r], radius=int(38 * SCALE), outline=(255, 255, 255, 28), width=int(8 * SCALE))
    
    w = int(38 * SCALE)
    p_start = (cx - int(60 * SCALE), cy + int(110 * SCALE))
    p_corner = (cx - int(60 * SCALE), cy - int(25 * SCALE))
    p_horiz = (cx + int(40 * SCALE), cy - int(25 * SCALE))
    
    draw.line([p_start[0], p_start[1], p_corner[0], p_corner[1]], fill=(255, 255, 255, 220), width=w)
    draw.arc([p_corner[0] - w//2, p_corner[1] - int(60 * SCALE), p_corner[0] + int(60 * SCALE), p_corner[1] + w//2], start=180, end=270, fill=(255, 255, 255, 220), width=w)
    draw.line([p_corner[0] + int(30 * SCALE), p_corner[1] - int(30 * SCALE), p_horiz[0], p_corner[1] - int(30 * SCALE)], fill=(255, 255, 255, 220), width=w)
    
    tip = (cx + int(125 * SCALE), cy - int(30 * SCALE))
    top = (cx + int(45 * SCALE), cy - int(85 * SCALE))
    bot = (cx + int(45 * SCALE), cy + int(25 * SCALE))
    draw.polygon([tip, top, bot], fill=(34, 197, 94, 255))
    save_icon(img, "icon_04_venu_sq_cockpit")

# -------------------------------------------------------------
# ICON 05: Bluetooth Radar Pulse (Connected Telemetry)
# -------------------------------------------------------------
def make_icon_05():
    img = create_base_canvas((12, 28, 20, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    for i, r in enumerate([int(140 * SCALE), int(210 * SCALE), int(280 * SCALE)]):
        alpha = 45 + i * 35
        draw.arc([cx - r, cy - r, cx + r, cy + r], start=215, end=325, fill=(34, 197, 94, alpha), width=int(8 * SCALE))
        draw.arc([cx - r, cy - r, cx + r, cy + r], start=35, end=145, fill=(34, 197, 94, alpha // 2), width=int(6 * SCALE))
        
    tip = (cx, cy - int(135 * SCALE))
    l = (cx - int(95 * SCALE), cy + int(80 * SCALE))
    r = (cx + int(95 * SCALE), cy + int(80 * SCALE))
    n = (cx, cy + int(25 * SCALE))
    draw.polygon([tip, l, n], fill=(255, 255, 255, 255))
    draw.polygon([tip, n, r], fill=(34, 197, 94, 255))
    save_icon(img, "icon_05_bluetooth_radar_pulse")

# -------------------------------------------------------------
# ICON 06: Aero Speed Chevrons (Cycling & Commute)
# -------------------------------------------------------------
def make_icon_06():
    img = create_base_canvas((24, 26, 29, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    r_tr = int(450 * SCALE) // 2
    draw.ellipse([cx - r_tr, cy - r_tr, cx + r_tr, cy + r_tr], outline=(255, 255, 255, 20), width=int(7 * SCALE))
    
    w = int(32 * SCALE)
    offset_y = int(45 * SCALE)
    pts1 = [
        (cx - int(105 * SCALE), cy - offset_y + int(50 * SCALE)),
        (cx, cy - offset_y - int(50 * SCALE)),
        (cx + int(105 * SCALE), cy - offset_y + int(50 * SCALE))
    ]
    draw.line(pts1, fill=(255, 255, 255, 255), width=w, joint="curve")
    
    offset_y2 = int(80 * SCALE)
    pts2 = [
        (cx - int(105 * SCALE), cy + offset_y2 + int(50 * SCALE)),
        (cx, cy + offset_y2 - int(50 * SCALE)),
        (cx + int(105 * SCALE), cy + offset_y2 + int(50 * SCALE))
    ]
    draw.line(pts2, fill=(34, 197, 94, 255), width=w, joint="curve")
    save_icon(img, "icon_06_aero_speed_chevrons")

# -------------------------------------------------------------
# ICON 07: Precision Waypoint Crosshair (Trail Marker)
# -------------------------------------------------------------
def make_icon_07():
    img = create_base_canvas((20, 48, 36, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    r = int(440 * SCALE) // 2
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 255, 255, 38), width=int(8 * SCALE))
    
    c_len = int(42 * SCALE)
    draw.line([cx, cy - r - c_len//2, cx, cy - r + c_len//2], fill=(255, 255, 255, 160), width=int(7 * SCALE))
    draw.line([cx, cy + r - c_len//2, cx, cy + r + c_len//2], fill=(255, 255, 255, 160), width=int(7 * SCALE))
    draw.line([cx - r - c_len//2, cy, cx - r + c_len//2, cy], fill=(255, 255, 255, 160), width=int(7 * SCALE))
    draw.line([cx + r - c_len//2, cy, cx + r + c_len//2, cy], fill=(255, 255, 255, 160), width=int(7 * SCALE))
    
    ang = -math.pi / 2.8
    tip_n = (cx + int(155 * math.cos(ang) * SCALE), cy + int(155 * math.sin(ang) * SCALE))
    tip_s = (cx - int(155 * math.cos(ang) * SCALE), cy - int(155 * math.sin(ang) * SCALE))
    side_w = int(44 * SCALE)
    p_left = (cx + int(side_w * math.cos(ang + math.pi/2)), cy + int(side_w * math.sin(ang + math.pi/2)))
    p_right = (cx + int(side_w * math.cos(ang - math.pi/2)), cy + int(side_w * math.sin(ang - math.pi/2)))
    
    draw.polygon([tip_n, p_left, (cx, cy)], fill=(34, 197, 94, 255))
    draw.polygon([tip_n, p_right, (cx, cy)], fill=(20, 150, 75, 255))
    draw.polygon([tip_s, p_left, (cx, cy)], fill=(240, 240, 240, 255))
    draw.polygon([tip_s, p_right, (cx, cy)], fill=(160, 160, 160, 255))
    save_icon(img, "icon_07_precision_waypoint_crosshair")

# -------------------------------------------------------------
# ICON 08: Liquid Glass Dial (Modern Translucent Lens)
# -------------------------------------------------------------
def make_icon_08():
    img = create_base_canvas((14, 34, 24, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    r_disc = int(450 * SCALE) // 2
    draw.ellipse([cx - r_disc, cy - r_disc, cx + r_disc, cy + r_disc], fill=(255, 255, 255, 15), outline=(255, 255, 255, 45), width=int(7 * SCALE))
    
    r_in = r_disc - int(18 * SCALE)
    draw.ellipse([cx - r_in, cy - r_in, cx + r_in, cy + r_in], outline=(34, 197, 94, 35), width=int(5 * SCALE))
    
    tip = (cx, cy - int(140 * SCALE))
    l = (cx - int(100 * SCALE), cy + int(90 * SCALE))
    r = (cx + int(100 * SCALE), cy + int(90 * SCALE))
    n = (cx, cy + int(30 * SCALE))
    
    s_off = int(8 * SCALE)
    draw.polygon([(tip[0], tip[1] + s_off), (l[0], l[1] + s_off), (n[0], n[1] + s_off), (r[0], r[1] + s_off)], fill=(0, 0, 0, 80))
    draw.polygon([tip, l, n, r], fill=(255, 255, 255, 255))
    draw.line([tip, n], fill=(34, 197, 94, 255), width=int(7 * SCALE))
    save_icon(img, "icon_08_liquid_glass_dial")

# -------------------------------------------------------------
# ICON 09: Instinct Dual-Zone (Monochrome Rugged Contrast)
# -------------------------------------------------------------
def make_icon_09():
    img = create_base_canvas((10, 10, 12, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    sub_cx = cx + int(70 * SCALE)
    sub_cy = cy - int(70 * SCALE)
    sub_r = int(120 * SCALE)
    draw.ellipse([sub_cx - sub_r, sub_cy - sub_r, sub_cx + sub_r, sub_cy + sub_r], outline=(255, 255, 255, 255), width=int(12 * SCALE))
    
    tip_sub = (sub_cx, sub_cy - int(70 * SCALE))
    l_sub = (sub_cx - int(50 * SCALE), sub_cy + int(45 * SCALE))
    r_sub = (sub_cx + int(50 * SCALE), sub_cy + int(45 * SCALE))
    n_sub = (sub_cx, sub_cy + int(12 * SCALE))
    draw.polygon([tip_sub, l_sub, n_sub, r_sub], fill=(255, 255, 255, 255))
    
    draw.rounded_rectangle([cx - int(150 * SCALE), cy + int(35 * SCALE), cx + int(120 * SCALE), cy + int(60 * SCALE)], radius=int(6 * SCALE), fill=(255, 255, 255, 200))
    draw.rounded_rectangle([cx - int(150 * SCALE), cy + int(80 * SCALE), cx + int(50 * SCALE), cy + int(105 * SCALE)], radius=int(6 * SCALE), fill=(255, 255, 255, 120))
    draw.rounded_rectangle([cx - int(150 * SCALE), cy - int(60 * SCALE), cx - int(20 * SCALE), cy - int(10 * SCALE)], radius=int(8 * SCALE), fill=(34, 197, 94, 255))
    save_icon(img, "icon_09_instinct_dualzone")

# -------------------------------------------------------------
# ICON 10: Turn Junction Arrow (Infotainment / Road Geometry)
# -------------------------------------------------------------
def make_icon_10():
    img = create_base_canvas((16, 36, 26, 255))
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    w = int(32 * SCALE)
    draw.line([cx - int(60 * SCALE), cy + int(140 * SCALE), cx - int(60 * SCALE), cy - int(120 * SCALE)], fill=(255, 255, 255, 40), width=w)
    
    draw.line([cx - int(60 * SCALE), cy + int(140 * SCALE), cx - int(60 * SCALE), cy + int(15 * SCALE)], fill=(34, 197, 94, 255), width=w)
    draw.arc([cx - int(60 * SCALE) - w//2, cy - int(50 * SCALE), cx + int(60 * SCALE), cy + int(70 * SCALE)], start=90, end=0, fill=(34, 197, 94, 255), width=w)
    draw.line([cx + int(30 * SCALE), cy - int(15 * SCALE), cx + int(80 * SCALE), cy - int(65 * SCALE)], fill=(34, 197, 94, 255), width=w)
    
    tip = (cx + int(135 * SCALE), cy - int(115 * SCALE))
    l = (cx + int(55 * SCALE), cy - int(115 * SCALE))
    b = (cx + int(135 * SCALE), cy - int(35 * SCALE))
    draw.polygon([tip, l, b], fill=(34, 197, 94, 255))
    save_icon(img, "icon_10_turn_junction_arrow")

# -------------------------------------------------------------
# RUN ALL
# -------------------------------------------------------------
make_icon_01()
make_icon_02()
make_icon_03()
make_icon_04()
make_icon_05()
make_icon_06()
make_icon_07()
make_icon_08()
make_icon_09()
make_icon_10()

# -------------------------------------------------------------
# CREATE OVERVIEW GALLERY SHEET
# -------------------------------------------------------------
GRID_W = 5
GRID_H = 2
ITEM_SIZE = 360
PADDING = 48
HEADER_H = 150
FOOTER_H = 40

CANVAS_W = GRID_W * ITEM_SIZE + (GRID_W + 1) * PADDING
CANVAS_H = HEADER_H + GRID_H * (ITEM_SIZE + 90) + FOOTER_H

sheet = Image.new("RGBA", (CANVAS_W, CANVAS_H), (15, 17, 20, 255))
draw_sheet = ImageDraw.Draw(sheet)

title = "Navigation IQ - 10 App Icon Proposals (Minimalist Series)"
sub = "Select your preferred concept for Android Adaptive Icon & Garmin Connect IQ watch launcher"
draw_sheet.text((PADDING, 45), title, fill=(255, 255, 255, 255))
draw_sheet.text((PADDING, 85), sub, fill=(160, 170, 175, 255))

icon_names = [
    ("icon_01_compass_chevron", "01. Compass Chevron", "Nordic Minimalist"),
    ("icon_02_garmin_tactical_bezel", "02. Garmin Tactical", "Fenix Rugged Bezel"),
    ("icon_03_stylized_n_route", "03. 'N' Turn Route", "Brand Monogram"),
    ("icon_04_venu_sq_cockpit", "04. Venu Sq Cockpit", "Square AMOLED Match"),
    ("icon_05_bluetooth_radar_pulse", "05. Radar BLE Pulse", "Connected Telemetry"),
    ("icon_06_aero_speed_chevrons", "06. Aero Chevrons", "Cycling / Speed"),
    ("icon_07_precision_waypoint_crosshair", "07. Waypoint Crosshair", "Outdoor Reticle"),
    ("icon_08_liquid_glass_dial", "08. Liquid Glass Dial", "Translucent Lens"),
    ("icon_09_instinct_dualzone", "09. Instinct DualZone", "High-Contrast MIP"),
    ("icon_10_turn_junction_arrow", "10. Turn Junction", "Infotainment Path"),
]

for idx, (filename, label, desc) in enumerate(icon_names):
    col = idx % GRID_W
    row = idx // GRID_W
    
    x = PADDING + col * (ITEM_SIZE + PADDING)
    y = HEADER_H + row * (ITEM_SIZE + 90)
    
    icon_p = os.path.join(OUT_DIR, f"{filename}.png")
    if os.path.exists(icon_p):
        ic = Image.open(icon_p).convert("RGBA").resize((ITEM_SIZE, ITEM_SIZE), Image.Resampling.LANCZOS)
        sheet.paste(ic, (x, y), ic)
    
    draw_sheet.text((x + 10, y + ITEM_SIZE + 14), label, fill=(240, 240, 240, 255))
    draw_sheet.text((x + 10, y + ITEM_SIZE + 38), desc, fill=(140, 150, 155, 255))

gallery_path = os.path.join(OUT_DIR, "00_all_10_icon_proposals.png")
sheet.save(gallery_path, "PNG")
print("Perfected 10 icon proposals generated!")
