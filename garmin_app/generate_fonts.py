import os
import sys
from PIL import Image, ImageDraw, ImageFont

def generate_bmfont(font_path, font_size, out_fnt_path, out_png_path, font_face_name):
    # Load TrueType / OpenType font
    font = ImageFont.truetype(font_path, font_size)
    
    # Charset
    ascii_chars = "".join(chr(i) for i in range(32, 127))
    vn_chars = "àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ•–—’“”…"
    unique_chars = list(dict.fromkeys(ascii_chars + vn_chars))
    
    # Measure line metrics
    ascent, descent = font.getmetrics()
    line_height = ascent + descent + 2
    base = ascent
    
    # First pass: measure all glyphs
    glyphs = []
    for ch in unique_chars:
        code = ord(ch)
        bbox = font.getbbox(ch) # (left, top, right, bottom)
        if bbox is None or bbox[2] <= bbox[0] or bbox[3] <= bbox[1]:
            # Space or invisible char
            advance = font.getlength(ch)
            glyphs.append({
                'id': code, 'char': ch, 'w': 0, 'h': 0,
                'xoff': 0, 'yoff': 0, 'xadv': int(round(advance)),
                'bbox': (0,0,0,0)
            })
        else:
            left, top, right, bottom = bbox
            w = right - left
            h = bottom - top
            advance = font.getlength(ch)
            glyphs.append({
                'id': code, 'char': ch, 'w': w, 'h': h,
                'xoff': left, 'yoff': top,
                'xadv': int(round(advance)),
                'bbox': bbox
            })
            
    # Pack into texture sheet (512x512 or 256x256)
    sheet_w = 512
    sheet_h = 512
    img = Image.new("RGBA", (sheet_w, sheet_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cur_x = 2
    cur_y = 2
    row_h = 0
    
    packed_glyphs = []
    for g in glyphs:
        if g['w'] == 0 or g['h'] == 0:
            packed_glyphs.append(dict(g, x=0, y=0))
            continue
            
        if cur_x + g['w'] + 2 >= sheet_w:
            cur_x = 2
            cur_y += row_h + 2
            row_h = 0
            
        if cur_y + g['h'] + 2 >= sheet_h:
            print(f"Warning: Texture sheet full for {font_face_name}")
            break
            
        # Draw glyph: offset to place bbox inside (cur_x, cur_y)
        draw_x = cur_x - g['bbox'][0]
        draw_y = cur_y - g['bbox'][1]
        draw.text((draw_x, draw_y), g['char'], font=font, fill=(255, 255, 255, 255))
        
        packed_glyphs.append(dict(g, x=cur_x, y=cur_y))
        
        cur_x += g['w'] + 2
        if g['h'] > row_h:
            row_h = g['h']
            
    # Crop unused bottom area of image to power of 2 or minimum size
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
    font_path = "garmin_app/resources/fonts/SF-Pro.ttf"
    os.makedirs("garmin_app/resources/fonts", exist_ok=True)
    
    # 1. Medium Street Text Font (Size: 22px)
    generate_bmfont(font_path, 22, "garmin_app/resources/fonts/sf_pro_street.fnt", "garmin_app/resources/fonts/sf_pro_street_0.png", "SF Pro Street")
    # 2. Compact Street Text Font (Size: 18px)
    generate_bmfont(font_path, 18, "garmin_app/resources/fonts/sf_pro_compact.fnt", "garmin_app/resources/fonts/sf_pro_compact_0.png", "SF Pro Compact")
    # 3. Micro Pill Font (Size: 14px)
    generate_bmfont(font_path, 14, "garmin_app/resources/fonts/sf_pro_micro.fnt", "garmin_app/resources/fonts/sf_pro_micro_0.png", "SF Pro Micro")
    
    print("BMFonts successfully generated!")
