import os
import sys
from PIL import Image, ImageDraw, ImageFont

def generate_bmfont(font_path, font_size, out_fnt_path, out_png_path, font_face_name, rotate_degrees=0):
    font_base = ImageFont.truetype(font_path, font_size)
    
    # Complete ASCII + full Vietnamese accented characters
    ascii_chars = [chr(i) for i in range(32, 127)]
    vn_chars = list("áàảãạăắằẳẵặâấầẩẫậéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ")
    unique_chars = list(dict.fromkeys(ascii_chars + vn_chars))
    
    ascent_b, descent_b = font_base.getmetrics()
    line_height = ascent_b + descent_b + 4
    base = ascent_b + 2
    
    pad_x = 20
    pad_baseline = ascent_b + 20
    cell_h = pad_baseline + descent_b + 20
    
    glyphs = []
    for ch in unique_chars:
        code = ord(ch)
        adv_int = max(int(round(font_base.getlength(ch))), 1)
        
        cell_w = adv_int + pad_x * 2 + 20
        temp_img = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        temp_draw = ImageDraw.Draw(temp_img)
        temp_draw.text((pad_x, pad_baseline), ch, font=font_base, fill=(255, 255, 255, 255), anchor="ls")
        
        bbox = temp_img.getbbox()
        if bbox is None:
            glyphs.append({
                'id': code, 'char': ch, 'w': 0, 'h': 0,
                'xoff': 0, 'yoff': 0, 'xadv': adv_int if rotate_degrees == 0 else 60,
                'img': None
            })
        else:
            glyph_crop = temp_img.crop(bbox)
            target_w = bbox[2] - bbox[0]
            target_h = bbox[3] - bbox[1]
            xoff = bbox[0] - pad_x
            yoff = base + (bbox[1] - pad_baseline)
            
            if rotate_degrees == 90:
                rot_img = glyph_crop.rotate(270, expand=True)
                rot_xoff = (base - yoff - target_h) + 10
                rot_yoff = xoff
                glyphs.append({
                    'id': code, 'char': ch,
                    'w': rot_img.width, 'h': rot_img.height,
                    'xoff': rot_xoff,
                    'yoff': rot_yoff,
                    'xadv': 60,
                    'img': rot_img
                })
            else:
                glyphs.append({
                    'id': code, 'char': ch,
                    'w': target_w, 'h': target_h,
                    'xoff': xoff,
                    'yoff': yoff,
                    'xadv': adv_int,
                    'img': glyph_crop
                })
                
    # Texture packing
    sheet_w = 512
    sheet_h = 512
    img = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    cur_x = 2
    cur_y = 2
    max_row_h = 0
    
    packed_glyphs = []
    for g in glyphs:
        if g['img'] is None:
            packed_glyphs.append({
                'id': g['id'], 'x': 0, 'y': 0,
                'w': 0, 'h': 0,
                'xoff': 0, 'yoff': 0,
                'xadv': g['xadv']
            })
            continue
            
        gw, gh = g['img'].size
        if cur_x + gw + 2 >= sheet_w:
            cur_x = 2
            cur_y += max_row_h + 2
            max_row_h = 0
            
        if cur_y + gh + 2 >= sheet_h:
            sheet_h *= 2
            new_img = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
            new_img.paste(img, (0, 0))
            img = new_img
            
        img.paste(g['img'], (cur_x, cur_y))
        packed_glyphs.append({
            'id': g['id'],
            'x': cur_x, 'y': cur_y,
            'w': gw, 'h': gh,
            'xoff': g['xoff'], 'yoff': g['yoff'],
            'xadv': g['xadv']
        })
        
        cur_x += gw + 2
        if gh > max_row_h:
            max_row_h = gh
            
    final_h = cur_y + max_row_h + 4
    if final_h < 128:
        final_h = 128
    else:
        p = 128
        while p < final_h:
            p *= 2
        final_h = p
        
    final_img = img.crop((0, 0, sheet_w, final_h))
    alpha_channel = final_img.split()[3]
    alpha_channel.save(out_png_path, "PNG")
    
    png_filename = os.path.basename(out_png_path)
    with open(out_fnt_path, "w", encoding="utf-8") as f:
        f.write(f'info face="{os.path.basename(font_path)}" size={font_size} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1 outline=0\n')
        f.write(f"common lineHeight={line_height} base={base} scaleW={sheet_w} scaleH={final_h} pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4\n")
        f.write(f'page id=0 file="{png_filename}"\n')
        f.write(f"chars count={len(packed_glyphs)}\n")
        for g in packed_glyphs:
            f.write(f"char id={g['id']:<5} x={g['x']:<4} y={g['y']:<4} width={g['w']:<3} height={g['h']:<3} xoffset={g['xoff']:<3} yoffset={g['yoff']:<3} xadvance={g['xadv']:<3} page=0 chnl=0\n")

if __name__ == "__main__":
    font_bold = "app/src/main/res/font/sf_pro_display_semibold.otf"
    font_regular = "app/src/main/res/font/sf_pro_text_medium.otf"
    
    os.makedirs("garmin_app/resources/fonts", exist_ok=True)
    
    # 1. Main Action Bold Font (Size: 30px, Bold)
    generate_bmfont(font_bold, 30, "garmin_app/resources/fonts/sf_pro_street_bold.fnt", "garmin_app/resources/fonts/sf_pro_street_bold_0.png", "SF Pro Street Bold")
    # 2. Street Detail Regular Font (Size: 27px, Medium)
    generate_bmfont(font_regular, 27, "garmin_app/resources/fonts/sf_pro_street.fnt", "garmin_app/resources/fonts/sf_pro_street_0.png", "SF Pro Street")
    # 3. Compact Action Bold Font (Size: 25px, Bold)
    generate_bmfont(font_bold, 25, "garmin_app/resources/fonts/sf_pro_compact_bold.fnt", "garmin_app/resources/fonts/sf_pro_compact_bold_0.png", "SF Pro Compact Bold")
    # 4. Compact Street Regular Font (Size: 23px, Medium)
    generate_bmfont(font_regular, 23, "garmin_app/resources/fonts/sf_pro_compact.fnt", "garmin_app/resources/fonts/sf_pro_compact_0.png", "SF Pro Compact")
    # 5. Micro Pill Font - ETA & Live Clock (Size: 27px, Bold)
    generate_bmfont(font_bold, 27, "garmin_app/resources/fonts/sf_pro_micro.fnt", "garmin_app/resources/fonts/sf_pro_micro_0.png", "SF Pro Micro")
    
    # 6. Rotated 90° Clockwise Fonts for Left-Wrist Motorbike Handlebar mode
    generate_bmfont(font_bold, 28, "garmin_app/resources/fonts/sf_pro_street_bold_rot90.fnt", "garmin_app/resources/fonts/sf_pro_street_bold_rot90_0.png", "SF Pro Street Bold Rot90", rotate_degrees=90)
    generate_bmfont(font_regular, 25, "garmin_app/resources/fonts/sf_pro_street_rot90.fnt", "garmin_app/resources/fonts/sf_pro_street_rot90_0.png", "SF Pro Street Rot90", rotate_degrees=90)
    generate_bmfont(font_bold, 25, "garmin_app/resources/fonts/sf_pro_micro_rot90.fnt", "garmin_app/resources/fonts/sf_pro_micro_rot90_0.png", "SF Pro Micro Rot90", rotate_degrees=90)
    
    print("All BMFonts (Direct 1x TrueType Hinted + Precise Baseline Alignment) successfully generated!")
