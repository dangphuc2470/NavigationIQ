import os
from PIL import Image, ImageDraw, ImageFont

font_bold_path = "app/src/main/res/font/sf_pro_display_semibold.otf"
font_reg_path = "app/src/main/res/font/sf_pro_text_medium.otf"

def main():
    sq_path = "screenshots/01_venu_sq2_square_hud.png"
    round_path = "screenshots/02_fr965_fenix7_round_hud.png"
    cross_path = "screenshots/03_instinct_crossover_dualzone_hud.png"

    img_sq = Image.open(sq_path).convert("RGBA")
    img_round = Image.open(round_path).convert("RGBA")
    img_cross = Image.open(cross_path).convert("RGBA")

    # Round watch circular mask
    rw, rh = img_round.size
    round_mask = Image.new("L", (rw, rh), 0)
    rm_draw = ImageDraw.Draw(round_mask)
    rm_draw.ellipse([0, 0, rw, rh], fill=255)
    img_round_masked = Image.new("RGBA", (rw, rh), (0, 0, 0, 0))
    img_round_masked.paste(img_round, (0, 0), mask=round_mask)

    # Resize round to 380x380 for harmonious showcase layout
    target_round_w = 380
    target_round_h = 380
    img_round_display = img_round_masked.resize((target_round_w, target_round_h), Image.Resampling.LANCZOS)

    # Square watch rounded rect mask (Venu Sq 2 has smooth bezel squircle corners)
    sw, sh = img_sq.size
    sq_mask = Image.new("L", (sw, sh), 0)
    sm_draw = ImageDraw.Draw(sq_mask)
    sm_draw.rounded_rectangle([0, 0, sw, sh], radius=24, fill=255)
    img_sq_masked = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    img_sq_masked.paste(img_sq, (0, 0), mask=sq_mask)

    # Instinct Crossover upscaled 1.6x (crisp 1-bit pixel aesthetic)
    cw, ch = img_cross.size
    img_cross_display = img_cross.resize((int(cw * 1.6), int(ch * 1.6)), Image.Resampling.NEAREST)

    # Composite Banner (1200x700)
    comp = Image.new("RGBA", (1200, 700), (15, 17, 21, 255))
    c_draw = ImageDraw.Draw(comp)

    f_title = ImageFont.truetype(font_bold_path, 34)
    f_sub = ImageFont.truetype(font_reg_path, 18)
    f_label = ImageFont.truetype(font_bold_path, 19)
    f_small = ImageFont.truetype(font_reg_path, 15)

    c_draw.text((45, 35), "Navigation IQ - Multi-Device Hardware Support", font=f_title, fill=(255, 255, 255, 255))
    c_draw.text((45, 80), "Live Google Maps Navigation for Garmin Watches with Screen-Adaptive Layouts", font=f_sub, fill=(161, 161, 170, 255))

    # 1. Square Watch (Venu Sq 2)
    sq_x, sq_y = 50, 150
    # Watch body frame border
    c_draw.rounded_rectangle([sq_x - 4, sq_y - 4, sq_x + sw + 4, sq_y + sh + 4], radius=28, outline=(40, 44, 52, 255), width=2)
    comp.paste(img_sq_masked, (sq_x, sq_y), mask=img_sq_masked)
    c_draw.text((sq_x, 535), "Square Watch (AMOLED / LCD)", font=f_label, fill=(255, 255, 255, 255))
    c_draw.text((sq_x, 562), "Venu 2 Sq, Venu Sq, Venu X1", font=f_small, fill=(148, 163, 184, 255))

    # 2. Round Watch (Forerunner 965 / Fenix 7)
    rnd_x, rnd_y = 430, 140
    # Watch bezel ring
    c_draw.ellipse([rnd_x - 5, rnd_y - 5, rnd_x + target_round_w + 5, rnd_y + target_round_h + 5], outline=(40, 44, 52, 255), width=3)
    comp.paste(img_round_display, (rnd_x, rnd_y), mask=img_round_display)
    c_draw.text((rnd_x + 35, 545), "Round Watch (AMOLED / MIP)", font=f_label, fill=(255, 255, 255, 255))
    c_draw.text((rnd_x + 35, 572), "Forerunner 965/265, Fenix 7, Venu 3", font=f_small, fill=(148, 163, 184, 255))

    # 3. Instinct Crossover
    cross_x, cross_y = 870, 190
    target_cw, target_ch = img_cross_display.size
    c_draw.rounded_rectangle([cross_x - 4, cross_y - 4, cross_x + target_cw + 4, cross_y + target_ch + 4], radius=16, outline=(40, 44, 52, 255), width=2)
    comp.paste(img_cross_display, (cross_x, cross_y))
    c_draw.text((cross_x, 500), "Instinct Crossover (MIP)", font=f_label, fill=(255, 255, 255, 255))
    c_draw.text((cross_x, 525), "Dual-Zone Mechanical Clearance", font=f_small, fill=(16, 185, 129, 255))
    c_draw.text((cross_x, 550), "100% Unobstructed by Watch Hands", font=f_small, fill=(148, 163, 184, 255))

    out_banner = "screenshots/00_navigation_iq_showcase_banner.png"
    comp.save(out_banner)
    print(f"Generated {out_banner} successfully from real simulator captures!")

if __name__ == "__main__":
    main()
