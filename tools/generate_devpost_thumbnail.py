import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1200, 800
canvas = Image.new("RGBA", (W, H), (7, 10, 20, 255))
d = ImageDraw.Draw(canvas)

# 1. Deep space background gradient
for y in range(H):
    factor = y / H
    r = int(7 + 10 * factor)
    g = int(10 + 16 * factor)
    b = int(20 + 32 * factor)
    d.line([(0, y), (W, y)], fill=(r, g, b, 255))

# 2. Nebulae glows
nebula = Image.new("RGBA", (W, H), (0, 0, 0, 0))
nd = ImageDraw.Draw(nebula)
nd.ellipse([600, 80, 1300, 780], fill=(28, 65, 150, 50))
nd.ellipse([700, 180, 1200, 680], fill=(110, 35, 160, 40))
nd.ellipse([800, 260, 1100, 560], fill=(14, 165, 233, 30))
nd.ellipse([50, 450, 550, 950], fill=(30, 80, 140, 25))
nebula = nebula.filter(ImageFilter.GaussianBlur(55))
canvas = Image.alpha_composite(canvas, nebula)

# 3. Procedural Starfield
random.seed(1337)
star_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(star_layer)
for _ in range(180):
    sx = random.randint(0, W)
    sy = random.randint(0, H)
    brightness = random.randint(150, 255)
    size = random.choices([1, 2, 3], weights=[80, 16, 4])[0]
    alpha = random.randint(140, 255)
    color = (brightness, brightness, min(255, int(brightness * 1.1)), alpha)
    sd.ellipse([sx, sy, sx + size, sy + size], fill=color)
    # Give a tiny cross spike to a few bright stars
    if size == 3 and random.random() < 0.35:
        sd.line([(sx - 4, sy + 1), (sx + 7, sy + 1)], fill=(brightness, brightness, 255, 120))
        sd.line([(sx + 1, sy - 4), (sx + 1, sy + 7)], fill=(brightness, brightness, 255, 120))
canvas = Image.alpha_composite(canvas, star_layer)

# 4. Planetary Body (icon.png)
planet_raw = Image.open("icon.png").convert("RGBA")
planet_size = 470
planet_resized = planet_raw.resize((planet_size, planet_size), Image.Resampling.LANCZOS)
px = 715
py = 165

# Atmospheric Glow behind planet
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([px - 50, py - 50, px + planet_size + 50, py + planet_size + 50], fill=(56, 189, 248, 65))
gd.ellipse([px - 22, py - 22, px + planet_size + 22, py + planet_size + 22], fill=(14, 165, 233, 115))
glow = glow.filter(ImageFilter.GaussianBlur(34))
canvas = Image.alpha_composite(canvas, glow)

# Paste planet
canvas.paste(planet_resized, (px, py), planet_resized)

# Planetary Rings overlay
ring_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
rd = ImageDraw.Draw(ring_layer)
cx = px + planet_size // 2
cy = py + planet_size // 2

# Draw elliptical rings
for rx_rad, ry_rad, width, col in [
    (270, 72, 3, (168, 85, 247, 190)),
    (285, 76, 2, (192, 132, 252, 140)),
    (300, 80, 4, (147, 51, 234, 170)),
    (315, 84, 2, (56, 189, 248, 130)),
]:
    bbox = [cx - rx_rad, cy - ry_rad, cx + rx_rad, cy + ry_rad]
    rd.ellipse(bbox, outline=col, width=width)

# Mask out ring behind planet (back half of the ellipse)
ring_front = ring_layer.copy()
mask_front = Image.new("L", (W, H), 0)
md = ImageDraw.Draw(mask_front)
md.rectangle([0, cy - 15, W, H], fill=255)
ring_front.putalpha(Image.composite(ring_layer.split()[-1], mask_front, mask_front))
canvas = Image.alpha_composite(canvas, ring_front)

# 5. Aerospace beacon in high orbit (sleek vector probe)
probe_x, probe_y = 660, 150
probe_glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
pgd = ImageDraw.Draw(probe_glow)
pgd.ellipse([probe_x - 12, probe_y - 12, probe_x + 12, probe_y + 12], fill=(56, 189, 248, 140))
pgd.ellipse([probe_x - 4, probe_y - 4, probe_x + 4, probe_y + 4], fill=(255, 255, 255, 255))
pgd.line([(probe_x - 18, probe_y), (probe_x + 18, probe_y)], fill=(56, 189, 248, 180), width=2)
pgd.line([(probe_x, probe_y - 18), (probe_x, probe_y + 18)], fill=(56, 189, 248, 180), width=2)
probe_glow = probe_glow.filter(ImageFilter.GaussianBlur(4))
canvas = Image.alpha_composite(canvas, probe_glow)

# 6. Typography & UI Badges
font_bold = "C:/Windows/Fonts/segoeuib.ttf"
font_regular = "C:/Windows/Fonts/segoeui.ttf"
font_black = "C:/Windows/Fonts/ariblk.ttf"

f_chip = ImageFont.truetype(font_bold, 15)
f_title = ImageFont.truetype(font_bold, 86)
f_subtitle = ImageFont.truetype(font_bold, 24)
f_desc = ImageFont.truetype(font_regular, 21)
f_badge = ImageFont.truetype(font_bold, 14)

draw = ImageDraw.Draw(canvas)

# Chip: Event / Category
chip_x, chip_y = 75, 125
chip_text = "REVENUECAT SHIPATON 2026  •  NEXT GEN AWARD"
chip_w = 410
chip_h = 36
draw.rounded_rectangle([chip_x, chip_y, chip_x + chip_w, chip_y + chip_h], radius=18, fill=(232, 69, 60, 45), outline=(232, 69, 60, 220), width=1)
draw.ellipse([chip_x + 16, chip_y + 13, chip_x + 26, chip_y + 23], fill=(232, 69, 60, 255))
draw.text((chip_x + 36, chip_y + 8), chip_text, fill=(255, 235, 235, 255), font=f_chip)

# Main Title: CIVITUS
title_x = 75
title_y = 185
# Subtle soft shadow
draw.text((title_x + 3, title_y + 3), "CIVITUS", fill=(0, 0, 0, 180), font=f_title)
draw.text((title_x, title_y), "CIVITUS", fill=(255, 255, 255, 255), font=f_title)

# Subtitle: THE UNMILKY WAY HOME
sub_y = title_y + 102
sub_text = "T H E   U N M I L K Y   W A Y   H O M E"
draw.text((title_x + 2, sub_y + 1), sub_text, fill=(14, 165, 233, 240), font=f_subtitle)

# Description paragraphs
desc_y = sub_y + 56
lines = [
    "A 3D procedural space survival & planetary exploration",
    "experience featuring spherical diorama worlds (R=160m),",
    "radial gravity, and an ethical freemium economy.",
]
for i, line in enumerate(lines):
    draw.text((title_x, desc_y + i * 32), line, fill=(203, 213, 225, 240), font=f_desc)

# Feature Badges Pill Row
badge_y = 560
badges = [
    ("Godot Engine 4.7", (71, 140, 191)),
    ("RevenueCat IAP", (232, 69, 60)),
    ("Radial Gravity", (168, 85, 247)),
    ("640+ TDD Tests", (34, 197, 94)),
]

cur_bx = title_x
for b_text, b_col in badges:
    bbox = draw.textbbox((0, 0), b_text, font=f_badge)
    bw = (bbox[2] - bbox[0]) + 30
    bh = 32
    # background pill
    draw.rounded_rectangle([cur_bx, badge_y, cur_bx + bw, badge_y + bh], radius=8, fill=(15, 23, 42, 220), outline=b_col, width=1)
    # text
    draw.text((cur_bx + 15, badge_y + 7), b_text, fill=(241, 245, 249, 255), font=f_badge)
    cur_bx += bw + 14

# Bottom Footer bar
draw.line([(75, 710), (1125, 710)], fill=(51, 65, 85, 140), width=1)
f_footer = ImageFont.truetype(font_regular, 15)
draw.text((75, 725), "Open Source  •  MIT License  •  Solo Student Developer: Nicolas Buelvas (Icesi)", fill=(148, 163, 184, 220), font=f_footer)
draw.text((890, 725), "github.com/nicolasbuelvas/CIVITUS", fill=(56, 189, 248, 220), font=f_footer)

output_path = "docs/screenshots/civitus_devpost_thumbnail.png"
canvas.save(output_path, "PNG", optimize=True)
print(f"Thumbnail saved to {output_path}")
