import os
import shutil

PROJECT_ROOT = r"d:\Project\APKMod\NavigationIQ"
SCREENSHOTS_SRC = os.path.join(PROJECT_ROOT, "garmin_app", "screenshots", "normal")
GALLERY_ROOT = os.path.join(PROJECT_ROOT, "screenshots", "gallery")

SERIES_CONFIG = [
    {
        "id": "instinct",
        "title": "Instinct Series (Rugged Monochrome & AMOLED)",
        "desc": "Built for extreme outdoors. Dual-zone layout with dedicated directional sub-window.",
        "devices": [
            ("instinct3solar45mm", "Instinct 3 Solar (45mm)", "176x176 1-bit MIP"),
            ("instinct3amoled45mm", "Instinct 3 AMOLED (45mm)", "390x390 AMOLED"),
            ("instinct3amoled50mm", "Instinct 3 AMOLED (50mm)", "416x416 AMOLED"),
            ("instincte40mm", "Instinct E (40mm)", "166x166 1-bit MIP"),
            ("instincte45mm", "Instinct E (45mm)", "176x176 1-bit MIP"),
            ("instinctcrossover", "Instinct Crossover (45mm)", "176x176 MIP Hybrid"),
            ("instinctcrossoveramoled", "Instinct Crossover AMOLED", "390x390 AMOLED Hybrid"),
            ("instinct2", "Instinct 2 (45mm)", "176x176 1-bit MIP"),
            ("instinct2s", "Instinct 2S (40mm)", "156x156 1-bit MIP"),
            ("instinct2x", "Instinct 2X Solar (50mm)", "176x176 1-bit MIP")
        ]
    },
    {
        "id": "forerunner",
        "title": "Forerunner Series (Running Flagships & Essentials)",
        "desc": "Optimized glanceability while running, high contrast distance numbers and turn alerts.",
        "devices": [
            ("fr965", "Forerunner 965", "454x454 AMOLED"),
            ("fr955", "Forerunner 955", "260x260 MIP"),
            ("fr265", "Forerunner 265", "416x416 AMOLED"),
            ("fr265s", "Forerunner 265S", "360x360 AMOLED"),
            ("fr255", "Forerunner 255", "260x260 MIP"),
            ("fr255s", "Forerunner 255S", "218x218 MIP"),
            ("fr165", "Forerunner 165", "390x390 AMOLED"),
            ("fr55", "Forerunner 55", "240x240 MIP")
        ]
    },
    {
        "id": "fenix_epix_enduro",
        "title": "Fenix, Epix & Enduro Series (Outdoor Multi-Sport Flagships)",
        "desc": "Premium multi-sport watches with adaptive solar MIP and ultra-bright AMOLED graphics.",
        "devices": [
            ("fenix847mm", "fēnix 8 47mm", "454x454 AMOLED"),
            ("fenix843mm", "fēnix 8 43mm", "416x416 AMOLED"),
            ("fenix8solar47mm", "fēnix 8 Solar 47mm", "260x260 MIP"),
            ("fenix8solar51mm", "fēnix 8 Solar 51mm", "280x280 MIP"),
            ("fenix8pro47mm", "fēnix 8 Pro 47mm", "454x454 AMOLED"),
            ("fenixe", "fēnix E", "416x416 AMOLED"),
            ("epix2pro51mm", "epix Pro (Gen 2) 51mm", "454x454 AMOLED"),
            ("epix2pro47mm", "epix Pro (Gen 2) 47mm", "416x416 AMOLED"),
            ("epix2pro42mm", "epix Pro (Gen 2) 42mm", "390x390 AMOLED"),
            ("epix2", "epix (Gen 2)", "416x416 AMOLED"),
            ("fenix7x", "fēnix 7X (51mm)", "280x280 MIP"),
            ("fenix7", "fēnix 7 (47mm)", "260x260 MIP"),
            ("fenix7s", "fēnix 7S (42mm)", "240x240 MIP"),
            ("enduro3", "Enduro 3", "280x280 MIP"),
            ("enduro", "Enduro", "280x280 MIP")
        ]
    },
    {
        "id": "venu_vivoactive",
        "title": "Venu & Vivoactive Series (Lifestyle, Square & Round)",
        "desc": "Tailored for daily commutes and urban rides with both Squircle and Round layouts.",
        "devices": [
            ("venusq2", "Venu Sq 2", "320x360 AMOLED Square"),
            ("venusq", "Venu Sq", "240x240 LCD Square"),
            ("venu3", "Venu 3", "454x454 AMOLED"),
            ("venu3s", "Venu 3S", "390x390 AMOLED"),
            ("venu2plus", "Venu 2 Plus", "416x416 AMOLED"),
            ("venu2", "Venu 2", "416x416 AMOLED"),
            ("venu2s", "Venu 2S", "360x360 AMOLED"),
            ("venux1", "Venu X1", "416x416 AMOLED"),
            ("vivoactive5", "vívoactive 5", "390x390 AMOLED")
        ]
    },
    {
        "id": "specialty",
        "title": "Specialty Series (Golf, Diving, Aviator & Luxury)",
        "desc": "Dedicated hardware adaptations for Approach golf watches, Descent dive computers, and D2 aviator models.",
        "devices": [
            ("approachs7047mm", "Approach S70 47mm (Golf)", "454x454 AMOLED"),
            ("approachs7042mm", "Approach S70 42mm (Golf)", "390x390 AMOLED"),
            ("descentmk351mm", "Descent Mk3i 51mm (Diving)", "454x454 AMOLED"),
            ("descentmk343mm", "Descent Mk3 43mm (Diving)", "390x390 AMOLED"),
            ("descentg1", "Descent G1 / Solar (Diving)", "176x176 1-bit MIP"),
            ("descentg2", "Descent G2 (Diving)", "390x390 AMOLED"),
            ("d2mach2", "D2 Mach 2 (Aviator)", "454x454 AMOLED"),
            ("d2mach2pro", "D2 Mach 2 Pro (Aviator)", "454x454 AMOLED"),
            ("d2mach1", "D2 Mach 1 (Aviator)", "416x416 AMOLED"),
            ("marq2", "MARQ (Gen 2)", "390x390 AMOLED"),
            ("marq2aviator", "MARQ (Gen 2) Aviator", "390x390 AMOLED")
        ]
    }
]

def organize():
    os.makedirs(GALLERY_ROOT, exist_ok=True)
    
    total_copied = 0
    for s in SERIES_CONFIG:
        series_dir = os.path.join(GALLERY_ROOT, s["id"])
        os.makedirs(series_dir, exist_ok=True)
        for dev_id, name, desc in s["devices"]:
            src_png = os.path.join(SCREENSHOTS_SRC, f"{dev_id}.png")
            if os.path.exists(src_png):
                dst_png = os.path.join(series_dir, f"{dev_id}.png")
                shutil.copyfile(src_png, dst_png)
                total_copied += 1
                
    print(f"Organized {total_copied} screenshots across 5 series.")

if __name__ == "__main__":
    organize()
