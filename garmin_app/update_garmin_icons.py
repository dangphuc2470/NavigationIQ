import os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter
import shutil

GARMIN_ROOT = r"d:\Project\APKMod\NavigationIQ\garmin_app"
GARMIN_DRAWABLES = os.path.join(GARMIN_ROOT, "resources", "drawables")
ANDROID_RES = r"d:\Project\APKMod\NavigationIQ\app\src\main\res"
ARTIFACT_DIR = r"C:\Users\phucdnh\.gemini\antigravity-ide\brain\3d2eab4b-8ff7-434d-8f30-db3ed9546551"

def quad_bezier(p0, p1, p2, n=30):
    t = np.linspace(0, 1, n)[:, None]
    return (1 - t)**2 * p0 + 2 * (1 - t) * t * p1 + t**2 * p2

def round_corner(p_prev, p_curr, p_next, r, n=50):
    v_in = np.array(p_prev, dtype=float) - np.array(p_curr, dtype=float)
    v_out = np.array(p_next, dtype=float) - np.array(p_curr, dtype=float)
    u_in = v_in / np.linalg.norm(v_in)
    u_out = v_out / np.linalg.norm(v_out)
    
    p_start = np.array(p_curr, dtype=float) + u_in * r
    p_end = np.array(p_curr, dtype=float) + u_out * r
    arc = quad_bezier(p_start, np.array(p_curr, dtype=float), p_end, n)
    return p_start, arc, p_end

def render_selected_option_3():
    # Option 3 (Level 3 - Extra Chunky Round):
    # Tip: 185, Wings: 145, Notch: 115
    verts = [(500., 195.), (755., 765.), (500., 625.), (245., 765.)]
    radii = [185., 145., 115., 145.]

    s0, arc0, e0 = round_corner(verts[3], verts[0], verts[1], radii[0], 50)
    s1, arc1, e1 = round_corner(verts[0], verts[1], verts[2], radii[1], 50)
    s2, arc2, e2 = round_corner(verts[1], verts[2], verts[3], radii[2], 50)
    s3, arc3, e3 = round_corner(verts[2], verts[3], verts[0], radii[3], 50)

    # Full arrow boundary with perfectly straight connecting edges
    full_arrow = np.vstack([
        arc0,
        np.linspace(e0, s1, 30),
        arc1,
        np.linspace(e1, s2, 30),
        arc2,
        np.linspace(e2, s3, 30),
        arc3,
        np.linspace(e3, s0, 30)
    ])

    SIZE = 2048
    scale = SIZE / 1000.0

    # Base Canvas with Rounded Squircle (Garmin / iOS standard ~22.5%)
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    mask = Image.new("L", (SIZE, SIZE), 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle([0, 0, SIZE, SIZE], radius=int(SIZE * 0.225), fill=255)
    bg = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 255))
    img.paste(bg, (0, 0), mask)

    # Ambient drop shadow
    poly_scaled = [(p[0]*scale, p[1]*scale) for p in full_arrow]
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    shadow_pts = [(p[0], p[1] + 28*scale) for p in poly_scaled]
    sdraw.polygon(shadow_pts, fill=(16, 50, 35, 45))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=int(22 * scale)))
    img = Image.alpha_composite(img, shadow)

    # Crisp split between Left Wing (#1B4332) and Right Wing (#10B981)
    arrow_mask = Image.new("L", (SIZE, SIZE), 0)
    am_draw = ImageDraw.Draw(arrow_mask)
    am_draw.polygon(poly_scaled, fill=255)

    left_clip = Image.new("L", (SIZE, SIZE), 0)
    lc_draw = ImageDraw.Draw(left_clip)
    lc_draw.rectangle([0, 0, int(500 * scale), SIZE], fill=255)
    left_arrow_mask = Image.new("L", (SIZE, SIZE), 0)
    left_arrow_mask.paste(arrow_mask, (0, 0), left_clip)

    right_clip = Image.new("L", (SIZE, SIZE), 0)
    rc_draw = ImageDraw.Draw(right_clip)
    rc_draw.rectangle([int(500 * scale), 0, SIZE, SIZE], fill=255)
    right_arrow_mask = Image.new("L", (SIZE, SIZE), 0)
    right_arrow_mask.paste(arrow_mask, (0, 0), right_clip)

    wings_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    left_color = Image.new("RGBA", (SIZE, SIZE), (27, 67, 50, 255)) # #1B4332 (Deep Forest Green)
    right_color = Image.new("RGBA", (SIZE, SIZE), (16, 185, 129, 255)) # #10B981 (Vivid Emerald)

    wings_layer.paste(left_color, (0, 0), left_arrow_mask)
    wings_layer.paste(right_color, (0, 0), right_arrow_mask)

    # Crisp, bold white spine line running from very top of tip to bottom notch!
    spine_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sp_draw = ImageDraw.Draw(spine_layer)
    top_y = (np.min(arc0[:, 1]) - 10) * scale
    notch_y = (np.max(arc2[:, 1]) + 10) * scale
    line_width = int(14 * scale) # ~28px at 2048, ~7px at 512, extremely crisp!
    sp_draw.line([(500*scale, top_y), (500*scale, notch_y)], fill=(255, 255, 255, 255), width=line_width)

    # Clip spine by arrow_mask so it stays 100% inside arrow silhouette
    spine_clipped = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    spine_clipped.paste(spine_layer, (0, 0), arrow_mask)
    wings_layer = Image.alpha_composite(wings_layer, spine_clipped)

    img = Image.alpha_composite(img, wings_layer)

    # 2. Export 512x512 Store icon
    store_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
    store_path = os.path.join(GARMIN_ROOT, "garmin_store_icon_512.png")
    store_512.save(store_path, "PNG")
    print(f"[OK] Garmin Store 512x512 saved: {store_path}")

    # Copy to Artifact directory for instant user access
    if os.path.isdir(ARTIFACT_DIR):
        artifact_store = os.path.join(ARTIFACT_DIR, "garmin_store_icon_512.png")
        shutil.copyfile(store_path, artifact_store)
        print(f"[OK] Copied to artifact directory: {artifact_store}")

    # 3. Export Garmin Watch drawables with dedicated high-contrast spine for tiny screens
    def render_watch_icon(target_size):
        # Render at 4x target size for perfect anti-aliasing
        hi_size = target_size * 4
        hi_img = img.resize((hi_size, hi_size), Image.Resampling.LANCZOS)
        # Overlay crisp spine tailored for watch display
        overlay = Image.new("RGBA", (hi_size, hi_size), (0, 0, 0, 0))
        od = ImageDraw.Draw(overlay)
        y1 = ((0.25*s0[1] + 0.5*195. + 0.25*e0[1]) / 1000.0) * hi_size
        y2 = ((0.25*s2[1] + 0.5*625. + 0.25*e2[1]) / 1000.0) * hi_size
        od.line([(hi_size / 2.0, y1), (hi_size / 2.0, y2)], fill=(255, 255, 255, 255), width=max(4, int(hi_size * 0.045)))
        hi_img = Image.alpha_composite(hi_img, overlay)
        return hi_img.resize((target_size, target_size), Image.Resampling.LANCZOS)

    g_40 = render_watch_icon(40)
    g_40.save(os.path.join(GARMIN_DRAWABLES, "launcher_icon_40.png"), "PNG")
    g_33 = render_watch_icon(33)
    g_33.save(os.path.join(GARMIN_DRAWABLES, "launcher_icon_33.png"), "PNG")
    print(f"[OK] Garmin watch icons (40x40, 33x33) saved with crisp high-contrast spine")

    # 4. Generate clean, semantic SVG with straight lines and quadratic corner curves (40x40)
    sc40 = 0.04
    y_top_40 = (0.25*s0[1] + 0.5*195. + 0.25*e0[1]) * sc40
    y_notch_40 = (0.25*s2[1] + 0.5*625. + 0.25*e2[1]) * sc40

    svg_content = f"""<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
    <!-- Pure White Rounded Background -->
    <rect width="40" height="40" rx="9" fill="#FFFFFF"/>
    
    <!-- Modern Navigation Arrow (Left Wing - Deep Forest Green) -->
    <path d="M 20,{y_top_40:.2f} Q 20,7.80 {s0[0]*sc40:.2f},{s0[1]*sc40:.2f} L {e3[0]*sc40:.2f},{e3[1]*sc40:.2f} Q 9.80,30.60 {s3[0]*sc40:.2f},{s3[1]*sc40:.2f} L {e2[0]*sc40:.2f},{e2[1]*sc40:.2f} Q 20,25.00 20,{y_notch_40:.2f} Z" fill="#1B4332"/>
    
    <!-- Modern Navigation Arrow (Right Wing - Vivid Mint Emerald) -->
    <path d="M 20,{y_top_40:.2f} Q 20,7.80 {e0[0]*sc40:.2f},{e0[1]*sc40:.2f} L {s1[0]*sc40:.2f},{s1[1]*sc40:.2f} Q 30.20,30.60 {e1[0]*sc40:.2f},{e1[1]*sc40:.2f} L {s2[0]*sc40:.2f},{s2[1]*sc40:.2f} Q 20,25.00 20,{y_notch_40:.2f} Z" fill="#10B981"/>
    
    <!-- Center White Spine Divider (Crisp, solid white as in original) -->
    <line x1="20" y1="{y_top_40:.2f}" x2="20" y2="{y_notch_40:.2f}" stroke="#FFFFFF" stroke-width="1.2"/>
</svg>
"""
    with open(os.path.join(GARMIN_DRAWABLES, "launcher_icon.svg"), "w", encoding="utf-8") as f:
        f.write(svg_content)
    print(f"[OK] Garmin launcher_icon.svg updated with Option 3 geometry & crisp white spine")

    # 5. Generate Android ic_launcher_foreground.xml (108dp viewport)
    scale_a = 0.088
    ox = 10.0
    oy = 10.0
    def a_pt(p): return f"{p[0]*scale_a + ox:.2f},{p[1]*scale_a + oy:.2f}"

    y_top_a = (0.25*s0[1] + 0.5*195. + 0.25*e0[1]) * scale_a + oy
    y_notch_a = (0.25*s2[1] + 0.5*625. + 0.25*e2[1]) * scale_a + oy

    android_fg_xml = f"""<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <!-- Modern Navigation Arrow (Left Wing - Deep Forest Green) -->
    <path
        android:fillColor="#1B4332"
        android:pathData="M 54,{y_top_a:.2f} Q 54,27.16 {a_pt(s0)} L {a_pt(e3)} Q 31.56,77.32 {a_pt(s3)} L {a_pt(e2)} Q 54,65.00 54,{y_notch_a:.2f} Z" />

    <!-- Modern Navigation Arrow (Right Wing - Vivid Mint Emerald) -->
    <path
        android:fillColor="#10B981"
        android:pathData="M 54,{y_top_a:.2f} Q 54,27.16 {a_pt(e0)} L {a_pt(s1)} Q 76.44,77.32 {a_pt(e1)} L {a_pt(s2)} Q 54,65.00 54,{y_notch_a:.2f} Z" />

    <!-- Center White Spine Divider (Crisp, solid white as in original) -->
    <path
        android:strokeColor="#FFFFFF"
        android:strokeWidth="1.6"
        android:pathData="M 54,{y_top_a:.2f} L 54,{y_notch_a:.2f}" />
</vector>
"""
    with open(os.path.join(ANDROID_RES, "drawable", "ic_launcher_foreground.xml"), "w", encoding="utf-8") as f:
        f.write(android_fg_xml)
    print(f"[OK] Android ic_launcher_foreground.xml updated with Option 3 geometry & crisp white spine")

if __name__ == "__main__":
    render_selected_option_3()
