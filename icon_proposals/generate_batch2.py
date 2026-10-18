import os
import math
from PIL import Image, ImageDraw

OUT_DIR = r"d:\Project\APKMod\NavigationIQ\icon_proposals\batch2"
os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 512
SCALE = 4
HI_SIZE = SIZE * SCALE  # 2048x2048

# Color Palette
COL_WHITE = (255, 255, 255, 255)
COL_CREAM = (248, 247, 242, 255)     # Sand Cream
COL_FOREST_DEEP = (20, 52, 38, 255)   # #143426
COL_FOREST_MID = (27, 67, 50, 255)    # #1B4332
COL_MINT_VIVID = (16, 185, 129, 255)  # #10B981 (Emerald Mint)
COL_MINT_LIGHT = (52, 211, 153, 255)  # #34D399
COL_DARK_BG = (16, 20, 24, 255)       # Titanium Dark

def create_base(bg_color):
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
# 01. MẪU CHÍNH USER YÊU CẦU: Mũi tên sạch trơn, bỏ hết vạch trên dưới (Nền Trắng)
# -------------------------------------------------------------
def make_01():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    # Large, bold, perfectly proportioned Arrowhead
    tip = (cx, cy - int(175 * SCALE))
    l_wing = (cx - int(130 * SCALE), cy + int(120 * SCALE))
    r_wing = (cx + int(130 * SCALE), cy + int(120 * SCALE))
    notch = (cx, cy + int(45 * SCALE))
    
    # Soft ambient drop shadow
    s_off = int(12 * SCALE)
    draw.polygon([(tip[0], tip[1] + s_off), (l_wing[0], l_wing[1] + s_off), (notch[0], notch[1] + s_off)], fill=(0, 0, 0, 35))
    draw.polygon([(tip[0], tip[1] + s_off), (notch[0], notch[1] + s_off), (r_wing[0], r_wing[1] + s_off)], fill=(0, 0, 0, 35))
    
    # Left Half: Deep Forest Green (#1B4332)
    draw.polygon([tip, l_wing, notch], fill=COL_FOREST_MID)
    # Right Half: Vivid Mint Emerald (#10B981)
    draw.polygon([tip, notch, r_wing], fill=COL_MINT_VIVID)
    # Spine Highlight
    draw.line([tip, notch], fill=(255, 255, 255, 120), width=int(3 * SCALE))
    
    save_icon(img, "01_pure_arrow_white")

# -------------------------------------------------------------
# 02. MẪU CHÍNH USER YÊU CẦU BẢN NỀN KEM (Warm Sand Cream)
# -------------------------------------------------------------
def make_02():
    img = create_base(COL_CREAM)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    tip = (cx, cy - int(175 * SCALE))
    l_wing = (cx - int(130 * SCALE), cy + int(120 * SCALE))
    r_wing = (cx + int(130 * SCALE), cy + int(120 * SCALE))
    notch = (cx, cy + int(45 * SCALE))
    
    s_off = int(12 * SCALE)
    draw.polygon([(tip[0], tip[1] + s_off), (l_wing[0], l_wing[1] + s_off), (notch[0], notch[1] + s_off)], fill=(0, 0, 0, 30))
    draw.polygon([(tip[0], tip[1] + s_off), (notch[0], notch[1] + s_off), (r_wing[0], r_wing[1] + s_off)], fill=(0, 0, 0, 30))
    
    draw.polygon([tip, l_wing, notch], fill=COL_FOREST_DEEP)
    draw.polygon([tip, notch, r_wing], fill=COL_MINT_VIVID)
    draw.line([tip, notch], fill=(255, 255, 255, 100), width=int(3 * SCALE))
    
    save_icon(img, "02_pure_arrow_cream")

# -------------------------------------------------------------
# 03. FULL WATCH BEZEL RING (Vòng tròn la bàn liền mạch, không bị đứt 2 lằn)
# -------------------------------------------------------------
def make_03():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    # Complete closed thin compass ring
    r_ring = int(240 * SCALE)
    draw.ellipse([cx - r_ring, cy - r_ring, cx + r_ring, cy + r_ring], outline=(220, 225, 222, 255), width=int(6 * SCALE))
    
    # 4 Subtle Cardinal Dots
    d_r = int(8 * SCALE)
    draw.ellipse([cx - d_r, cy - r_ring - d_r, cx + d_r, cy - r_ring + d_r], fill=COL_MINT_VIVID) # North Green Dot
    draw.ellipse([cx + r_ring - d_r, cy - d_r, cx + r_ring + d_r, cy + d_r], fill=(180, 190, 185, 255))
    draw.ellipse([cx - d_r, cy + r_ring - d_r, cx + d_r, cy + r_ring + d_r], fill=(180, 190, 185, 255))
    draw.ellipse([cx - r_ring - d_r, cy - d_r, cx - r_ring + d_r, cy + d_r], fill=(180, 190, 185, 255))
    
    # 45-degree Angled GPS Arrowhead (Moving Forward Northeast)
    ang = -math.pi / 4
    tip = (cx + int(140 * math.cos(ang) * SCALE), cy + int(140 * math.sin(ang) * SCALE))
    l_wing = (cx + int(135 * math.cos(ang + 2.4) * SCALE), cy + int(135 * math.sin(ang + 2.4) * SCALE))
    r_wing = (cx + int(135 * math.cos(ang - 2.4) * SCALE), cy + int(135 * math.sin(ang - 2.4) * SCALE))
    notch = (cx + int(35 * math.cos(ang + math.pi) * SCALE), cy + int(35 * math.sin(ang + math.pi) * SCALE))
    
    draw.polygon([tip, l_wing, notch], fill=COL_FOREST_MID)
    draw.polygon([tip, notch, r_wing], fill=COL_MINT_VIVID)
    save_icon(img, "03_compass_ring_northeast")

# -------------------------------------------------------------
# 04. CURVED ROUTE TRAIL (Lộ trình bo cong dẫn đến mũi tên rẽ)
# -------------------------------------------------------------
def make_04():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    # Route track: Starts bottom left, curves up-right
    w = int(36 * SCALE)
    # Origin circle
    r_dot = int(32 * SCALE)
    p_start = (cx - int(100 * SCALE), cy + int(130 * SCALE))
    draw.ellipse([p_start[0] - r_dot, p_start[1] - r_dot, p_start[0] + r_dot, p_start[1] + r_dot], fill=COL_FOREST_MID)
    
    # Route curve
    draw.arc([cx - int(120 * SCALE), cy - int(80 * SCALE), cx + int(120 * SCALE), cy + int(160 * SCALE)], start=90, end=0, fill=COL_MINT_VIVID, width=w)
    draw.line([p_start[0], p_start[1], p_start[0], cy + int(40 * SCALE)], fill=COL_FOREST_MID, width=w)
    draw.line([cx + int(40 * SCALE), cy - int(20 * SCALE), cx + int(90 * SCALE), cy - int(70 * SCALE)], fill=COL_MINT_VIVID, width=w)
    
    # Turn Arrow Head
    tip = (cx + int(145 * SCALE), cy - int(125 * SCALE))
    l = (cx + int(60 * SCALE), cy - int(125 * SCALE))
    b = (cx + int(145 * SCALE), cy - int(40 * SCALE))
    draw.polygon([tip, l, b], fill=COL_MINT_VIVID)
    
    save_icon(img, "04_curved_route_trail")

# -------------------------------------------------------------
# 05. NORDIC COMPASS STAR (Kim la bàn hình học tối giản)
# -------------------------------------------------------------
def make_05():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    # 4-Point Compass Star
    h_n = int(220 * SCALE)  # North is long
    h_s = int(140 * SCALE)  # South
    w_ew = int(130 * SCALE) # East/West
    thick = int(45 * SCALE)
    
    tip_n = (cx, cy - h_n)
    tip_s = (cx, cy + h_s)
    tip_e = (cx + w_ew, cy)
    tip_w = (cx - w_ew, cy)
    
    # North Needle (Mint + Forest)
    draw.polygon([tip_n, (cx - thick, cy), (cx, cy)], fill=COL_FOREST_MID)
    draw.polygon([tip_n, (cx, cy), (cx + thick, cy)], fill=COL_MINT_VIVID)
    
    # South Needle (Muted Grey)
    draw.polygon([tip_s, (cx - thick, cy), (cx, cy)], fill=(200, 205, 202, 255))
    draw.polygon([tip_s, (cx, cy), (cx + thick, cy)], fill=(160, 168, 164, 255))
    
    # East/West Wings
    draw.polygon([tip_e, (cx, cy - thick), (cx, cy)], fill=COL_MINT_VIVID)
    draw.polygon([tip_e, (cx, cy), (cx, cy + thick)], fill=COL_FOREST_MID)
    draw.polygon([tip_w, (cx, cy - thick), (cx, cy)], fill=(200, 205, 202, 255))
    draw.polygon([tip_w, (cx, cy), (cx, cy + thick)], fill=(160, 168, 164, 255))
    
    save_icon(img, "05_nordic_compass_star")

# -------------------------------------------------------------
# 06. VENU SQ SMARTWATCH BEZEL (Mặt đồng hồ Venu Sq bo cong)
# -------------------------------------------------------------
def make_06():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    # Outer Smartwatch Frame (Soft Grey Slate)
    bw = int(360 * SCALE) // 2
    draw.rounded_rectangle([cx - bw, cy - bw, cx + bw, cy + bw], radius=int(60 * SCALE), outline=(215, 220, 218, 255), width=int(10 * SCALE))
    
    # Direct Navigation Arrow inside
    tip = (cx, cy - int(120 * SCALE))
    l_wing = (cx - int(95 * SCALE), cy + int(90 * SCALE))
    r_wing = (cx + int(95 * SCALE), cy + int(90 * SCALE))
    notch = (cx, cy + int(35 * SCALE))
    
    draw.polygon([tip, l_wing, notch], fill=COL_FOREST_MID)
    draw.polygon([tip, notch, r_wing], fill=COL_MINT_VIVID)
    save_icon(img, "06_smartwatch_bezel_frame")

# -------------------------------------------------------------
# 07. SOLID VIBRANT EMERALD (Nền xanh ngọc, mũi tên trắng tinh khôi)
# -------------------------------------------------------------
def make_07():
    img = create_base((16, 140, 85, 255)) # Rich Emerald Green
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    tip = (cx, cy - int(175 * SCALE))
    l_wing = (cx - int(130 * SCALE), cy + int(120 * SCALE))
    r_wing = (cx + int(130 * SCALE), cy + int(120 * SCALE))
    notch = (cx, cy + int(45 * SCALE))
    
    # Left: Pure White, Right: Light Mint Pastel
    draw.polygon([tip, l_wing, notch], fill=(255, 255, 255, 255))
    draw.polygon([tip, notch, r_wing], fill=(167, 243, 208, 255))
    draw.line([tip, notch], fill=(255, 255, 255, 180), width=int(3 * SCALE))
    
    save_icon(img, "07_solid_emerald_white_arrow")

# -------------------------------------------------------------
# 08. GEOMETRIC DOUBLE ARROW (Mũi tên lồng 2 lớp thể thao)
# -------------------------------------------------------------
def make_08():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    # Outer Arrow Base (Forest Green)
    tip1 = (cx, cy - int(175 * SCALE))
    l1 = (cx - int(130 * SCALE), cy + int(120 * SCALE))
    r1 = (cx + int(130 * SCALE), cy + int(120 * SCALE))
    n1 = (cx, cy + int(45 * SCALE))
    draw.polygon([tip1, l1, n1, r1], fill=COL_FOREST_MID)
    
    # Inner Arrow Inset (Mint Green)
    scale_in = 0.62
    tip2 = (cx, cy - int(175 * scale_in * SCALE))
    l2 = (cx - int(130 * scale_in * SCALE), cy + int(120 * scale_in * SCALE))
    r2 = (cx + int(130 * scale_in * SCALE), cy + int(120 * scale_in * SCALE))
    n2 = (cx, cy + int(45 * scale_in * SCALE))
    draw.polygon([tip2, l2, n2, r2], fill=COL_MINT_VIVID)
    
    save_icon(img, "08_double_inset_arrow")

# -------------------------------------------------------------
# 09. MONOGRAM 'N' WAYPOINT (Chữ N cách điệu hiện đại tối giản)
# -------------------------------------------------------------
def make_09():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    w = int(36 * SCALE)
    spacing_x = int(90 * SCALE)
    h_y = int(115 * SCALE)
    
    # Left pillar (Forest)
    draw.line([cx - spacing_x, cy + h_y, cx - spacing_x, cy - h_y], fill=COL_FOREST_MID, width=w)
    # Diagonal line (Mint)
    draw.line([cx - spacing_x, cy - h_y, cx + spacing_x, cy + h_y], fill=COL_MINT_VIVID, width=w)
    # Right pillar turning into arrow (Mint)
    draw.line([cx + spacing_x, cy + h_y, cx + spacing_x, cy - int(80 * SCALE)], fill=COL_MINT_VIVID, width=w)
    
    tip = (cx + spacing_x, cy - int(160 * SCALE))
    l = (cx + spacing_x - int(55 * SCALE), cy - int(75 * SCALE))
    r = (cx + spacing_x + int(55 * SCALE), cy - int(75 * SCALE))
    draw.polygon([tip, l, r], fill=COL_MINT_VIVID)
    
    save_icon(img, "09_monogram_n_modern")

# -------------------------------------------------------------
# 10. CLEAN RADAR CROSS (Chỉ 1 vòng tròn radar mỏng kín với 4 tick)
# -------------------------------------------------------------
def make_10():
    img = create_base(COL_WHITE)
    draw = ImageDraw.Draw(img)
    cx, cy = HI_SIZE // 2, HI_SIZE // 2
    
    r_c = int(210 * SCALE)
    draw.ellipse([cx - r_c, cy - r_c, cx + r_c, cy + r_c], outline=(225, 232, 228, 255), width=int(5 * SCALE))
    
    # Reticle ticks
    t_len = int(30 * SCALE)
    draw.line([cx, cy - r_c - t_len//2, cx, cy - r_c + t_len//2], fill=COL_MINT_VIVID, width=int(8 * SCALE))
    draw.line([cx + r_c - t_len//2, cy, cx + r_c + t_len//2, cy], fill=(200, 210, 205, 255), width=int(6 * SCALE))
    draw.line([cx, cy + r_c - t_len//2, cx, cy + r_c + t_len//2], fill=(200, 210, 205, 255), width=int(6 * SCALE))
    draw.line([cx - r_c - t_len//2, cy, cx - r_c + t_len//2, cy], fill=(200, 210, 205, 255), width=int(6 * SCALE))
    
    tip = (cx, cy - int(140 * SCALE))
    l = (cx - int(105 * SCALE), cy + int(95 * SCALE))
    r = (cx + int(105 * SCALE), cy + int(95 * SCALE))
    n = (cx, cy + int(35 * SCALE))
    
    draw.polygon([tip, l, n], fill=COL_FOREST_MID)
    draw.polygon([tip, n, r], fill=COL_MINT_VIVID)
    save_icon(img, "10_clean_radar_reticle")

# Run all
make_01()
make_02()
make_03()
make_04()
make_05()
make_06()
make_07()
make_08()
make_09()
make_10()

# -------------------------------------------------------------
# CREATE OVERVIEW GALLERY (2 ROWS x 5 COLS)
# -------------------------------------------------------------
GRID_W = 5
GRID_H = 2
ITEM_SIZE = 360
PADDING = 48
HEADER_H = 150
FOOTER_H = 40

CANVAS_W = GRID_W * ITEM_SIZE + (GRID_W + 1) * PADDING
CANVAS_H = HEADER_H + GRID_H * (ITEM_SIZE + 90) + FOOTER_H

sheet = Image.new("RGBA", (CANVAS_W, CANVAS_H), (20, 22, 25, 255))
draw_sheet = ImageDraw.Draw(sheet)

title = "Navigation IQ - Batch 2 Icon Proposals (No Radar Arcs / Light & Fresh Series)"
sub = "Featuring Option 01 & 02 (User Request: Pure Arrowhead, No Arcs) + 8 Fresh Variants"
draw_sheet.text((PADDING, 45), title, fill=(255, 255, 255, 255))
draw_sheet.text((PADDING, 85), sub, fill=(160, 170, 175, 255))

items = [
    ("01_pure_arrow_white", "01. Pure Arrow (White)", "Requested: Clean Arrow, No Arcs"),
    ("02_pure_arrow_cream", "02. Pure Arrow (Sand Cream)", "Matches In-App Jetpack Background"),
    ("03_compass_ring_northeast", "03. 45° Compass Ring", "Full Circle Bezel + Angled Arrow"),
    ("04_curved_route_trail", "04. Curved Route Trail", "Turn-by-turn Road Curve"),
    ("05_nordic_compass_star", "05. Nordic Compass Star", "Geometric Minimal 4-Point Star"),
    ("06_smartwatch_bezel_frame", "06. Smartwatch Bezel", "Venu Sq Squircle Hardware Match"),
    ("07_solid_emerald_white_arrow", "07. Solid Emerald Green", "Vibrant Sports Identity (Strava Style)"),
    ("08_double_inset_arrow", "08. Double Inset Arrow", "Layered Forest + Mint Chevron"),
    ("09_monogram_n_modern", "09. Monogram 'N' Waypoint", "Modern 'N' Route Brand Mark"),
    ("10_clean_radar_reticle", "10. Full Radar Reticle", "Closed Circle with North Tick"),
]

for idx, (fn, lbl, desc) in enumerate(items):
    col = idx % GRID_W
    row = idx // GRID_W
    x = PADDING + col * (ITEM_SIZE + PADDING)
    y = HEADER_H + row * (ITEM_SIZE + 90)
    
    p = os.path.join(OUT_DIR, f"{fn}.png")
    if os.path.exists(p):
        ic = Image.open(p).convert("RGBA").resize((ITEM_SIZE, ITEM_SIZE), Image.Resampling.LANCZOS)
        sheet.paste(ic, (x, y), ic)
    
    draw_sheet.text((x + 10, y + ITEM_SIZE + 14), lbl, fill=(240, 240, 240, 255))
    draw_sheet.text((x + 10, y + ITEM_SIZE + 38), desc, fill=(140, 150, 155, 255))

gal_p = os.path.join(OUT_DIR, "00_batch2_overview_gallery.png")
sheet.save(gal_p, "PNG")
print(f"Batch 2 gallery saved to {gal_p}")
