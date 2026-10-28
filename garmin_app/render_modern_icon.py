import os, math
from PIL import Image, ImageDraw, ImageFilter

def round_polygon(vertices, radii, num_points=32):
    n = len(vertices)
    new_points = []
    for i in range(n):
        p_prev = vertices[(i - 1) % n]
        p_curr = vertices[i]
        p_next = vertices[(i + 1) % n]
        r = radii[i]
        
        v1 = (p_prev[0] - p_curr[0], p_prev[1] - p_curr[1])
        v2 = (p_next[0] - p_curr[0], p_next[1] - p_curr[1])
        len1 = math.hypot(*v1)
        len2 = math.hypot(*v2)
        u1 = (v1[0] / len1, v1[1] / len1)
        u2 = (v2[0] / len2, v2[1] / len2)
        
        dot = max(-1.0, min(1.0, u1[0]*u2[0] + u1[1]*u2[1]))
        angle = math.acos(dot)
        half_angle = angle / 2.0
        
        d = r / math.tan(half_angle)
        d = min(d, len1 * 0.45, len2 * 0.45)
        r_actual = d * math.tan(half_angle)
        
        t1 = (p_curr[0] + u1[0]*d, p_curr[1] + u1[1]*d)
        t2 = (p_curr[0] + u2[0]*d, p_curr[1] + u2[1]*d)
        
        bisector = (u1[0] + u2[0], u1[1] + u2[1])
        blen = math.hypot(*bisector)
        if blen < 1e-6:
            new_points.append(p_curr)
            continue
        b_u = (bisector[0] / blen, bisector[1] / blen)
        dist_to_center = r_actual / math.sin(half_angle)
        center = (p_curr[0] + b_u[0]*dist_to_center, p_curr[1] + b_u[1]*dist_to_center)
        
        a1 = math.atan2(t1[1] - center[1], t1[0] - center[0])
        a2 = math.atan2(t2[1] - center[1], t2[0] - center[0])
        
        cross = u1[0]*u2[1] - u1[1]*u2[0]
        if cross < 0:
            if a2 > a1: a2 -= 2*math.pi
        else:
            if a2 < a1: a2 += 2*math.pi
            
        for k in range(num_points + 1):
            theta = a1 + (a2 - a1) * (k / float(num_points))
            pt = (center[0] + r_actual * math.cos(theta), center[1] + r_actual * math.sin(theta))
            new_points.append(pt)
    return new_points

def generate_master_icon(size=2048):
    # Render at 2048x2048 with supersampling for ultra-crisp antialiasing
    scale = size / 1000.0
    
    # 1. Base canvas & Background rounded squircle
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bg_mask = Image.new("L", (size, size), 0)
    bg_draw = ImageDraw.Draw(bg_mask)
    # Squircle radius ~22.5% (Garmin / iOS standard)
    radius = int(225 * scale)
    bg_draw.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
    
    # Clean pure white background with subtle depth
    bg = Image.new("RGBA", (size, size), (255, 255, 255, 255))
    img.paste(bg, (0, 0), bg_mask)
    
    # 2. Navigation Arrow geometry (modern proportions, slightly centered)
    # Proportions in 1000x1000 space
    tip = (500.0, 210.0)
    r_wing = (765.0, 755.0)
    notch = (500.0, 630.0)
    l_wing = (235.0, 755.0)
    
    vertices = [tip, r_wing, notch, l_wing]
    # Generous, smooth corner radii: Tip=42, Wings=48, Notch=36
    radii = [42.0, 48.0, 36.0, 48.0]
    
    smooth_pts = round_polygon(vertices, radii, num_points=64)
    scaled_pts = [(p[0] * scale, p[1] * scale) for p in smooth_pts]
    
    # 3. Soft drop shadow under the arrow
    shadow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow_img)
    shadow_offset_y = int(25 * scale)
    shadow_pts = [(p[0], p[1] + shadow_offset_y) for p in scaled_pts]
    s_draw.polygon(shadow_pts, fill=(16, 50, 35, 45))
    shadow_img = shadow_img.filter(ImageFilter.GaussianBlur(radius=int(22 * scale)))
    img = Image.alpha_composite(img, shadow_img)
    
    # 4. Draw Left Wing (Deep Forest Green) and Right Wing (Vivid Emerald Mint)
    # Split the smoothed polygon by X = 500 * scale
    arrow_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    a_draw = ImageDraw.Draw(arrow_layer)
    
    # Masks for left and right halves
    left_mask = Image.new("L", (size, size), 0)
    l_draw = ImageDraw.Draw(left_mask)
    l_draw.rectangle([0, 0, int(500.0 * scale), size], fill=255)
    
    right_mask = Image.new("L", (size, size), 0)
    r_draw = ImageDraw.Draw(right_mask)
    r_draw.rectangle([int(500.0 * scale), 0, size, size], fill=255)
    
    # Full arrow silhouette
    arrow_full = Image.new("L", (size, size), 0)
    af_draw = ImageDraw.Draw(arrow_full)
    af_draw.polygon(scaled_pts, fill=255)
    
    # Composite Left Wing (#1B4332)
    left_arrow_mask = Image.new("L", (size, size), 0)
    left_arrow_mask.paste(arrow_full, (0, 0), left_mask)
    left_color = Image.new("RGBA", (size, size), (27, 67, 50, 255)) # #1B4332
    arrow_layer.paste(left_color, (0, 0), left_arrow_mask)
    
    # Composite Right Wing (#10B981)
    right_arrow_mask = Image.new("L", (size, size), 0)
    right_arrow_mask.paste(arrow_full, (0, 0), right_mask)
    right_color = Image.new("RGBA", (size, size), (16, 185, 129, 255)) # #10B981
    arrow_layer.paste(right_color, (0, 0), right_arrow_mask)
    
    # 5. Center Spine Divider (subtle luminous line between the two wings)
    spine_draw = ImageDraw.Draw(arrow_layer)
    spine_top_y = (210.0 + 38.0) * scale
    spine_bot_y = (630.0 - 15.0) * scale
    spine_draw.line(
        [(500.0 * scale, spine_top_y), (500.0 * scale, spine_bot_y)],
        fill=(255, 255, 255, 190),
        width=max(2, int(3.5 * scale))
    )
    
    img = Image.alpha_composite(img, arrow_layer)
    return img, smooth_pts

if __name__ == "__main__":
    master, pts = generate_master_icon(2048)
    os.makedirs(r"d:\Project\APKMod\NavigationIQ\scratch", exist_ok=True)
    master.save(r"d:\Project\APKMod\NavigationIQ\scratch\modern_icon_2048.png", "PNG")
    
    # Export 512x512 Store icon
    store_512 = master.resize((512, 512), Image.Resampling.LANCZOS)
    store_path = r"d:\Project\APKMod\NavigationIQ\garmin_app\garmin_store_icon_512.png"
    store_512.save(store_path, "PNG")
    print(f"STORE ICON CREATED: {store_path}")
    
    # Export Garmin Watch Drawables
    garmin_drawables = r"d:\Project\APKMod\NavigationIQ\garmin_app\resources\drawables"
    g_40 = master.resize((40, 40), Image.Resampling.LANCZOS)
    g_40.save(os.path.join(garmin_drawables, "launcher_icon_40.png"), "PNG")
    
    g_33 = master.resize((33, 33), Image.Resampling.LANCZOS)
    g_33.save(os.path.join(garmin_drawables, "launcher_icon_33.png"), "PNG")
    print("GARMIN WATCH ICONS (40x40, 33x33) UPDATED!")
