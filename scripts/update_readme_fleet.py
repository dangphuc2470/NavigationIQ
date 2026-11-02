import os
import re

PROJECT_ROOT = r"d:\Project\APKMod\NavigationIQ"
README_FILE = os.path.join(PROJECT_ROOT, "README.md")
GALLERY_DIR = "screenshots/gallery"

from organize_gallery import SERIES_CONFIG

def generate_markdown_fleet():
    md_sections = []
    
    md_sections.append("## Supported Garmin Hardware Fleet (By Series)\n")
    md_sections.append("> Navigation IQ is actively compiled, tested, and individually pixel-tuned for **over 50+ Garmin watch models** across 5 distinct hardware series.\n")
    
    for s in SERIES_CONFIG:
        sid = s["id"]
        title = s["title"]
        desc = s["desc"]
        devices = s["devices"]
        
        md_sections.append(f"<details>\n<summary><b>{title} ({len(devices)} Models)</b></summary>\n")
        md_sections.append(f"\n*{desc}*\n")
        
        # Grid table: 3 or 4 columns
        # To make it beautiful, let's format as a 3-column table
        md_sections.append("| Device | Display & Architecture | Live Navigation HUD |")
        md_sections.append("| :--- | :--- | :---: |")
        
        for dev_id, name, spec in devices:
            img_rel = f"{GALLERY_DIR}/{sid}/{dev_id}.png"
            img_tag = f'<img src="{img_rel}" alt="{name}" width="160" />'
            md_sections.append(f"| **{name}**<br><code>{dev_id}</code> | {spec} | {img_tag} |")
            
        md_sections.append("\n</details>\n")
        
    return "\n".join(md_sections)

def update_readme():
    fleet_md = generate_markdown_fleet()
    
    with open(README_FILE, "r", encoding="utf-8") as f:
        content = f.read()
        
    # Replace or insert before "## Project Overview" or at the end of Watch HUD Showcase
    marker = "## Project Overview"
    if marker in content:
        parts = content.split(marker)
        new_content = parts[0] + fleet_md + "\n---\n\n" + marker + parts[1]
    else:
        new_content = content + "\n\n---\n\n" + fleet_md
        
    with open(README_FILE, "w", encoding="utf-8") as f:
        f.write(new_content)
        
    print("README.md updated successfully with full series fleet showcase!")

if __name__ == "__main__":
    update_readme()
