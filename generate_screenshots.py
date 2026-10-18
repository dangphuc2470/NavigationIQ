import os
from PIL import Image, ImageDraw, ImageFont

font_bold_path = "app/src/main/res/font/sf_pro_display_semibold.otf"
font_reg_path = "app/src/main/res/font/sf_pro_text_medium.otf"

def draw_turn_arrow(draw, cx, cy, dir_type, color=(255, 255, 255), scale=1.0):
    if dir_type == "right":
        pen_w = max(int(7 * scale), 2)
        p1 = (cx - int(10 * scale), cy + int(16 * scale))
        p2 = (cx - int(10 * scale), cy - int(2 * scale))
        p3 = (cx + int(6 * scale), cy - int(2 * scale))
        draw.line([p1, p2, p3], fill=color, width=pen_w)
        h1 = (cx + int(6 * scale), cy - int(14 * scale))
        h2 = (cx + int(20 * scale), cy - int(2 * scale))
        h3 = (cx + int(6 * scale), cy + int(10 * scale))
        draw.polygon([h1, h2, h3], fill=color)
    elif dir_type == "left":
        pen_w = max(int(7 * scale), 2)
        p1 = (cx + int(10 * scale), cy + int(16 * scale))
        p2 = (cx + int(10 * scale), cy - int(2 * scale))
        p3 = (cx - int(6 * scale), cy - int(2 * scale))
        draw.line([p1, p2, p3], fill=color, width=pen_w)
        h1 = (cx - int(6 * scale), cy - int(14 * scale))
        h2 = (cx - int(20 * scale), cy - int(2 * scale))
        h3 = (cx - int(6 * scale), cy + int(10 * scale))
        draw.polygon([h1, h2, h3], fill=color)
    elif dir_type == "straight":
        pen_w = max(int(7 * scale), 2)
        p1 = (cx, cy + int(16 * scale))
        p2 = (cx, cy - int(6 * scale))
        draw.line([p1, p2], fill=color, width=pen_w)
        h1 = (cx - int(12 * scale), cy - int(4 * scale))
        h2 = (cx, cy - int(20 * scale))
        h3 = (cx + int(12 * scale), cy - int(4 * scale))
        draw.polygon([h1, h2, h3], fill=color)
    elif dir_type == "roundabout":
        round_r = int(12 * scale)
        draw.ellipse([cx - round_r, cy - round_r, cx + round_r, cy + round_r], outline=(63, 63, 70), width=max(int(2 * scale), 1))
        draw.line([cx - int(4 * scale), cy + round_r + int(10 * scale), cx - int(4 * scale), cy + round_r], fill=color, width=max(int(5 * scale), 2))
        draw.line([cx, cy - round_r, cx, cy - round_r - int(10 * scale)], fill=color, width=max(int(5 * scale), 2))
        h1 = (cx - int(7 * scale), cy - round_r - int(8 * scale))
        h2 = (cx, cy - round_r - int(18 * scale))
        h3 = (cx + int(7 * scale), cy - round_r - int(8 * scale))
        draw.polygon([h1, h2, h3], fill=color)

def render_true_round_hud(w, h):
    # Pure AMOLED Black 416x416
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # In _drawRoundHUD:
    # isLarge = (w >= 400) -> true for 416x416
    # badgeR = (h * 0.082) = 34
    # badgeCy = (h * 0.125) = 52
    # badgeCx = w / 2 = 208
    badge_cx = w // 2
    badge_cy = int(h * 0.125)
    badge_r = int(h * 0.082) # 34

    # Ambient glow subtle bloom
    glow_r = int(w * 0.18)
    draw.ellipse([badge_cx - glow_r, badge_cy - glow_r, badge_cx + glow_r, badge_cy + glow_r], fill=(16, 50, 30, 255))
    
    # Badge (Milky jade green for Turn Right / 1.2 km or Amber for Turn Left)
    draw.ellipse([badge_cx - badge_r, badge_cy - badge_r, badge_cx + badge_r, badge_cy + badge_r], fill=(92, 142, 116, 255))
    draw_turn_arrow(draw, badge_cx, badge_cy - 4, "left", color=(255, 255, 255), scale=1.0)

    # Distance Row (Exactly centered horizontally under the badge)
    # distYVal = badgeCy + badgeR + (h * 0.075) = 52 + 34 + 31 = 117
    dist_y = badge_cy + badge_r + int(h * 0.075)
    f_num = ImageFont.truetype(font_bold_path, 54)
    f_unit = ImageFont.truetype(font_bold_path, 32)

    dist_str = "1.2"
    unit_str = "km"
    num_w = int(draw.textlength(dist_str, font=f_num))
    unit_w = int(draw.textlength(unit_str, font=f_unit))
    gap = 6
    total_dist_w = num_w + gap + unit_w
    start_dist_x = (w - total_dist_w) // 2

    draw.text((start_dist_x, dist_y - 30), dist_str, font=f_num, fill=(255, 255, 255, 255))
    draw.text((start_dist_x + num_w + gap, dist_y - 12), unit_str, font=f_unit, fill=(148, 163, 184, 255))

    # Street Text (Centered horizontally with high optical density)
    # minTextY = distYVal + (h * 0.080) = 117 + 33 = 150
    # maxTextH = pillY - 6 - minTextY = 337 - 6 - 150 = 181
    min_text_y = dist_y + int(h * 0.080)
    pill_y = int(h * 0.81) # 336
    pill_h = int(h * 0.082) # 34

    f_act = ImageFont.truetype(font_bold_path, 32)
    f_str = ImageFont.truetype(font_reg_path, 25)

    act_text = "TURN LEFT"
    str_line1 = "onto Market Street"
    str_line2 = "towards Downtown"

    act_w = int(draw.textlength(act_text, font=f_act))
    str1_w = int(draw.textlength(str_line1, font=f_str))
    str2_w = int(draw.textlength(str_line2, font=f_str))

    draw.text(((w - act_w) // 2, min_text_y + 10), act_text, font=f_act, fill=(255, 255, 255, 255))
    draw.text(((w - str1_w) // 2, min_text_y + 54), str_line1, font=f_str, fill=(228, 228, 231, 255))
    draw.text(((w - str2_w) // 2, min_text_y + 90), str_line2, font=f_str, fill=(161, 161, 170, 255))

    # Bottom Pill Bar (Floating Capsule with ETA and Live Clock)
    # pillY = 336, pillH = 34
    pill_w = 210
    pill_x = (w - pill_w) // 2
    draw.rounded_rectangle([pill_x, pill_y, pill_x + pill_w, pill_y + pill_h], radius=pill_h // 2, fill=(24, 24, 27, 255), outline=(39, 39, 42, 255), width=1)

    f_micro = ImageFont.truetype(font_bold_path, 19)
    draw.text((pill_x + 16, pill_y + 7), "ETA 17:38", font=f_micro, fill=(255, 255, 255, 255))
    
    # Center dot in pill
    dot_x = pill_x + (pill_w // 2)
    draw.ellipse([dot_x - 2, pill_y + (pill_h // 2) - 2, dot_x + 2, pill_y + (pill_h // 2) + 2], fill=(113, 113, 122, 255))

    draw.text((pill_x + pill_w - 62, pill_y + 7), "17:30", font=f_micro, fill=(228, 228, 231, 255))

    # Round Bezel Mask (Pure circular display)
    mask = Image.new("L", (w, h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse([0, 0, w, h], fill=255)

    final_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    final_img.paste(img, (0, 0), mask=mask)
    return final_img

def render_true_square_hud(w, h):
    # Pure AMOLED Black 320x360
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # In _drawUnifiedAppleHUD:
    # NO CARD BACKGROUND AT ALL. Pure black AMOLED edge-to-edge.
    # badgeCx = 52, badgeCy = 52, badgeRadius = 36
    badge_cx, badge_cy, badge_r = 52, 52, 36
    draw.ellipse([badge_cx - badge_r, badge_cy - badge_r, badge_cx + badge_r, badge_cy + badge_r], fill=(92, 142, 116, 255))
    draw_turn_arrow(draw, badge_cx, badge_cy - 4, "right", color=(255, 255, 255), scale=1.0)

    # Distance text: 2.8 km
    f_num = ImageFont.truetype(font_bold_path, 48)
    f_unit = ImageFont.truetype(font_bold_path, 28)
    draw.text((104, 30), "2.8", font=f_num, fill=(255, 255, 255, 255))
    draw.text((104 + 76, 46), "km", font=f_unit, fill=(148, 163, 184, 255))

    # Subtle divider line
    draw.line([14, 106, w - 14, 106], fill=(39, 39, 42, 255), width=1)

    # Instruction & Street text
    f_act = ImageFont.truetype(font_bold_path, 28)
    f_str = ImageFont.truetype(font_reg_path, 24)
    draw.text((16, 126), "TURN RIGHT", font=f_act, fill=(255, 255, 255, 255))
    draw.text((16, 162), "onto Main Street", font=f_str, fill=(228, 228, 231, 255))
    draw.text((16, 196), "towards City Center", font=f_str, fill=(161, 161, 170, 255))

    # Bottom Pill Bar (ETA on left capsule, clock on right)
    bar_y, bar_h, bar_r = 302, 52, 26
    draw.rounded_rectangle([0, bar_y, w, bar_y + bar_h], radius=bar_r, fill=(24, 24, 27, 255), outline=(39, 39, 42, 255), width=1)

    # ETA Capsule
    eta_x, eta_y, eta_w, eta_h = 10, bar_y + 7, 138, 38
    draw.rounded_rectangle([eta_x, eta_y, eta_x + eta_w, eta_y + eta_h], radius=19, fill=(36, 62, 48, 255), outline=(16, 185, 129, 255), width=1)
    f_micro = ImageFont.truetype(font_bold_path, 20)
    draw.text((eta_x + 22, eta_y + 7), "ETA 17:44", font=f_micro, fill=(255, 255, 255, 255))

    draw.text((w - 74, bar_y + 15), "17:30", font=f_micro, fill=(228, 228, 231, 255))
    draw.ellipse([w - 92, bar_y + 24, w - 88, bar_y + 28], fill=(113, 113, 122, 255))

    return img

def render_true_instinct_hud(w, h):
    # 176x176 High-contrast Monochrome MIP with Dual-Zone Clearance for Physical Hands
    img = Image.new("RGBA", (w, h), (16, 22, 16, 255))
    draw = ImageDraw.Draw(img)

    # 1. Top Zone (0..68)
    badge_cx, badge_cy, badge_r = 34, 36, 22
    draw.ellipse([badge_cx - badge_r, badge_cy - badge_r, badge_cx + badge_r, badge_cy + badge_r], outline=(255, 255, 255, 255), width=2)
    draw_turn_arrow(draw, badge_cx, badge_cy - 2, "roundabout", color=(255, 255, 255), scale=0.6)

    # Distance: 3.5 km
    f_num = ImageFont.truetype(font_bold_path, 28)
    f_unit = ImageFont.truetype(font_bold_path, 16)
    draw.text((68, 20), "3.5", font=f_num, fill=(255, 255, 255, 255))
    draw.text((68 + 48, 28), "km", font=f_unit, fill=(200, 220, 200, 255))

    # Top Divider Line (y = 68)
    draw.line([8, 68, w - 8, 68], fill=(255, 255, 255, 255), width=1)

    # 2. CENTER DEAD-ZONE (y = 69..103) - 100% CLEAR FOR PHYSICAL HANDS & REVOLVING PINION
    draw.ellipse([w//2 - 14, h//2 - 14, w//2 + 14, h//2 + 14], outline=(50, 70, 50, 255), width=1)
    draw.ellipse([w//2 - 4, h//2 - 4, w//2 + 4, h//2 + 4], fill=(30, 45, 30, 255))

    # 3. Bottom Divider Line (y = 104)
    draw.line([8, 104, w - 8, 104], fill=(255, 255, 255, 255), width=1)

    # 4. Bottom Zone (106..h)
    f_mono = ImageFont.truetype(font_bold_path, 15)
    f_small = ImageFont.truetype(font_reg_path, 13)
    draw.text((w // 2 - 42, 110), "2ND EXIT", font=f_mono, fill=(255, 255, 255, 255))
    draw.text((w // 2 - 46, 130), "Broadway Ave", font=f_small, fill=(230, 240, 230, 255))

    draw.text((12, h - 16), "ETA 17:41", font=f_small, fill=(180, 200, 180, 255))
    draw.text((w - 46, h - 16), "17:30", font=f_small, fill=(180, 200, 180, 255))

    # Circular watch mask
    mask = Image.new("L", (w, h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.ellipse([0, 0, w, h], fill=255)

    final_img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    final_img.paste(img, (0, 0), mask=mask)
    return final_img

def main():
    os.makedirs("screenshots", exist_ok=True)

    # 1. Square HUD (320x360)
    img_sq = render_true_square_hud(320, 360)
    img_sq.save("screenshots/01_venu_sq2_square_hud.png")
    print("Saved screenshots/01_venu_sq2_square_hud.png")

    # 2. Round HUD (416x416)
    img_round = render_true_round_hud(416, 416)
    img_round.save("screenshots/02_fr965_fenix7_round_hud.png")
    print("Saved screenshots/02_fr965_fenix7_round_hud.png")

    # 3. Instinct Crossover Dual-Zone (176x176)
    img_cross = render_true_instinct_hud(176, 176)
    img_cross.save("screenshots/03_instinct_crossover_dualzone_hud.png")
    print("Saved screenshots/03_instinct_crossover_dualzone_hud.png")

    # 4. Multi-device Showcase Banner (1200x700)
    comp = Image.new("RGBA", (1200, 700), (18, 18, 20, 255))
    c_draw = ImageDraw.Draw(comp)

    f_title = ImageFont.truetype(font_bold_path, 34)
    f_sub = ImageFont.truetype(font_reg_path, 18)
    f_label = ImageFont.truetype(font_bold_path, 18)

    c_draw.text((40, 35), "Navigation IQ - Multi-Device Hardware Support", font=f_title, fill=(255, 255, 255, 255))
    c_draw.text((40, 80), "Real-time Google Maps Navigation for Garmin Watches with Adaptive Layouts", font=f_sub, fill=(161, 161, 170, 255))

    # 1. Square Watch (x: 40, y: 160)
    comp.paste(img_sq, (40, 160), mask=img_sq)
    c_draw.text((40, 540), "Square Watch (AMOLED)", font=f_label, fill=(255, 255, 255, 255))
    c_draw.text((40, 565), "Venu Sq, Venu Sq 2, Venu X1", font=f_sub, fill=(148, 163, 184, 255))

    # 2. Round Watch (x: 390, y: 130)
    comp.paste(img_round, (390, 130), mask=img_round)
    c_draw.text((430, 570), "Round Watch (AMOLED / MIP)", font=f_label, fill=(255, 255, 255, 255))
    c_draw.text((430, 595), "Forerunner 965/265, Fenix 7, Venu 3", font=f_sub, fill=(148, 163, 184, 255))

    # 3. Instinct Crossover (x: 860, y: 210, upscaled 1.5x)
    img_cross_up = img_cross.resize((int(176 * 1.5), int(176 * 1.5)), Image.Resampling.NEAREST)
    comp.paste(img_cross_up, (860, 210), mask=img_cross_up)
    c_draw.text((860, 510), "Instinct Crossover", font=f_label, fill=(255, 255, 255, 255))
    c_draw.text((860, 535), "Dual-Zone Center Clear", font=f_sub, fill=(16, 185, 129, 255))
    c_draw.text((860, 560), "100% Unobstructed by Hands", font=f_sub, fill=(148, 163, 184, 255))

    comp.save("screenshots/00_navigation_iq_showcase_banner.png")
    print("Saved screenshots/00_navigation_iq_showcase_banner.png")

if __name__ == "__main__":
    main()
