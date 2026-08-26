import os
import sys
from PIL import Image, ImageDraw, ImageFont

def generate_bmfont(font_path, font_size, out_fnt_path, out_png_path, font_face_name):
    # Load Font with Semibold / Bold Weight
    font = ImageFont.truetype(font_path, font_size)
    
    # Complete ASCII + Vietnamese Charset
    ascii_chars = "".join(chr(i) for i in range(32, 127))
    vn_chars = "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ•–—’“”…"
    unique_chars = list(dict.fromkeys(ascii_chars + vn_chars))
    
    # Line Metrics
    ascent, descent = font.getmetrics()
    line_height = ascent + descent + 2
    base = ascent
    
    pad = 4
    cell_h = line_height + pad * 2
    
    glyphs = []
    for ch in unique_chars:
        code = ord(ch)
        advance = font.getlength(ch)
        adv_int = int(round(advance))
        
        # Temporary canvas for single glyph to measure exact relative bounding box
        cell_w = max(adv_int + pad * 2, font_size * 2)
        temp_img = Image.new("RGBA", (cell_w, cell_h), (0, 0, 0, 0))
        temp_draw = ImageDraw.Draw(temp_img)
        
        # Draw character at exact coordinate (pad, pad)
        temp_draw.text((pad, pad), ch, font=font, fill=(255, 255, 255, 255))
        
        bbox = temp_img.getbbox()
        if bbox is None:
            # Space or whitespace
            glyphs.append({
                'id': code, 'char': ch, 'w': 0, 'h': 0,
                'xoff': 0, 'yoff': 0, 'xadv': adv_int,
                'img': None
            })
        else:
            glyph_img = temp_img.crop(bbox)
            gw = bbox[2] - bbox[0]
            gh = bbox[3] - bbox[1]
            
            # Exact offset relative to cell origin (pad, pad)
            xoff = bbox[0] - pad
            yoff = bbox[1] - pad
            
            glyphs.append({
                'id': code, 'char': ch, 'w': gw, 'h': gh,
                'xoff': xoff, 'yoff': yoff,
                'xadv': adv_int,
                'img': glyph_img
            })
            
    # Pack into texture sheet (512x512)
    sheet_w = 512
    sheet_h = 512
    img = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    
    cur_x = 2
    cur_y = 2
    row_h = 0
    
    packed_glyphs = []
    for g in glyphs:
        if g['w'] == 0 or g['h'] == 0 or g['img'] is None:
            packed_glyphs.append(dict(g, x=0, y=0))
            continue
            
        if cur_x + g['w'] + 2 >= sheet_w:
            cur_x = 2
            cur_y += row_h + 2
            row_h = 0
            
        if cur_y + g['h'] + 2 >= sheet_h:
            print(f"Warning: Texture sheet full for {font_face_name}")
            break
            
        # Paste glyph onto sheet
        img.paste(g['img'], (cur_x, cur_y), g['img'])
        packed_glyphs.append(dict(g, x=cur_x, y=cur_y))
        
        cur_x += g['w'] + 2
        if g['h'] > row_h:
            row_h = g['h']
            
    # Crop to power-of-2 height
    final_h = 128
    while final_h < cur_y + row_h + 4 and final_h < 1024:
        final_h *= 2
    
    final_img = img.crop((0, 0, sheet_w, final_h))
    final_img.save(out_png_path, "PNG")
    
    # Write .fnt file
    png_filename = os.path.basename(out_png_path)
    with open(out_fnt_path, "w", encoding="utf-8") as f:
        f.write(f'info face="{font_face_name}" size={font_size} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=1,1 outline=0\n')
        f.write(f'common lineHeight={line_height} base={base} scaleW={sheet_w} scaleH={final_h} pages=1 packed=0\n')
        f.write(f'page id=0 file="{png_filename}"\n')
        f.write(f'chars count={len(packed_glyphs)}\n')
        for g in packed_glyphs:
            f.write(f"char id={g['id']:<5} x={g['x']:<4} y={g['y']:<4} width={g['w']:<3} height={g['h']:<3} xoffset={g['xoff']:<3} yoffset={g['yoff']:<3} xadvance={g['xadv']:<3} page=0 chnl=15\n")

if __name__ == "__main__":
    # Street fonts use Apple SF Pro Display Semibold
    font_semibold = "app/src/main/res/font/sf_pro_display_semibold.otf"
    # Micro Pill font uses Apple SF Pro Rounded Bold (18px) for thicker, bold legibility
    font_bold = "app/src/main/res/font/sf_pro_rounded_bold.otf"
    
    os.makedirs("garmin_app/resources/fonts", exist_ok=True)
    
    # 1. Large Street Text Font (Size: 25px, Semibold)
    generate_bmfont(font_semibold, 25, "garmin_app/resources/fonts/sf_pro_street.fnt", "garmin_app/resources/fonts/sf_pro_street_0.png", "SF Pro Street")
    # 2. Compact Street Text Font (Size: 20px, Semibold)
    generate_bmfont(font_semibold, 20, "garmin_app/resources/fonts/sf_pro_compact.fnt", "garmin_app/resources/fonts/sf_pro_compact_0.png", "SF Pro Compact")
    # 3. Micro Pill Font (Size: 18px, Rounded Bold)
    generate_bmfont(font_bold, 18, "garmin_app/resources/fonts/sf_pro_micro.fnt", "garmin_app/resources/fonts/sf_pro_micro_0.png", "SF Pro Micro")
    
    print("Apple SF Pro Semibold & Rounded Bold 18px BMFonts successfully generated!")
