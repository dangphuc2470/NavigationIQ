import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

v2_path = r"D:\Project\APKMod\NavigationIQ\screenshots\arrived_venu2.png"
sq2_path = r"D:\Project\APKMod\NavigationIQ\screenshots\arrived_venusq2.png"

img_v2 = Image.open(v2_path).convert("RGBA")
img_sq2 = Image.open(sq2_path).convert("RGBA")

# Create a composite dark luxury showcase canvas (1100 x 560)
canvas_w, canvas_h = 1000, 560
bg = Image.new("RGBA", (canvas_w, canvas_h), (12, 14, 18, 255))
draw = ImageDraw.Draw(bg)

# Typography
font_path = "app/src/main/res/font/sf_pro_display_semibold.otf"
f_title = ImageFont.truetype(font_path, 26)
f_sub = ImageFont.truetype(font_path, 15)
f_label = ImageFont.truetype(font_path, 18)
f_specs = ImageFont.truetype(font_path, 13)

# Header
draw.text((40, 24), "Navigation IQ - Destination Reached Screen", font=f_title, fill=(255, 255, 255, 255))
draw.text((40, 60), "Real Garmin ConnectIQ Simulator Screen Capture (Adaptive Round & Square)", font=f_sub, fill=(148, 163, 184, 255))

# Paste Venu 2 (Round 416x416)
# Center at x=250, y=300
v2_x = 70
v2_y = 95
bg.paste(img_v2, (v2_x, v2_y), mask=img_v2)

# Venu 2 Label
draw.text((v2_x + 130, v2_y + 425), "Venu 2 (Round AMOLED)", font=f_label, fill=(255, 255, 255, 255), anchor="mt")
draw.text((v2_x + 130, v2_y + 450), "416 x 416 • Circular Aero Safe-Area", font=f_specs, fill=(113, 127, 147, 255), anchor="mt")

# Paste Venu Sq 2 (Square 320x360)
# Scale up slightly to match optical weight, or show at 1:1 scale
# Center at x=730, y=300
sq2_x = 580
sq2_y = 123
bg.paste(img_sq2, (sq2_x, sq2_y), mask=img_sq2)

# Venu Sq 2 Label
draw.text((sq2_x + 160, sq2_y + 375), "Venu Sq 2 (Square AMOLED)", font=f_label, fill=(255, 255, 255, 255), anchor="mt")
draw.text((sq2_x + 160, sq2_y + 400), "320 x 360 • Minimal Top Padding • Max Glancability", font=f_specs, fill=(113, 127, 147, 255), anchor="mt")

out_comp = r"D:\Project\APKMod\NavigationIQ\screenshots\arrived_showcase.png"
bg.save(out_comp)
print(f"Saved {out_comp}")

# Also copy to artifact dir
art_comp = r"C:\Users\phucdnh\.gemini\antigravity-ide\brain\857623ae-ec7a-4ce3-8dfa-5fd821ab13e6\arrived_showcase.png"
bg.save(art_comp)
print(f"Saved {art_comp}")
