import os
from PIL import Image, ImageDraw, ImageFilter

SPRITES_DIR = "assets/sprites"
TILES_DIR = "assets/textures"
os.makedirs(SPRITES_DIR, exist_ok=True)
os.makedirs(TILES_DIR, exist_ok=True)

OUTLINE_COLOR = (60, 65, 70, 255)
OUTLINE_WIDTH = 3

# 1. Generate Character Sprite (Front & Angled matching the user images)
def gen_character():
    size = (256, 320)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Coordinates
    # Head box: 70, 70 to 186, 175
    # Body box: 70, 175 to 186, 285

    # Helmet (Upper dome & rim)
    # Rim: ellipse at 50, 60, 206, 95
    # Dome: arc/ellipse 55, 20, 201, 85
    d.pieslice([55, 18, 201, 100], 180, 360, fill=(168, 165, 148), outline=OUTLINE_COLOR, width=OUTLINE_WIDTH)
    d.ellipse([50, 58, 206, 88], fill=(182, 179, 162), outline=OUTLINE_COLOR, width=OUTLINE_WIDTH)

    # Head block (flesh tone)
    head_rect = [74, 82, 182, 180]
    d.rectangle(head_rect, fill=(218, 146, 114), outline=OUTLINE_COLOR, width=OUTLINE_WIDTH)
    # Side shadow on head
    d.rectangle([74, 82, 94, 180], fill=(195, 126, 96))

    # Big Googly Eyes
    # Right eye (viewer's left): center (112, 132)
    d.ellipse([96, 118, 130, 154], fill=(255, 255, 255), outline=OUTLINE_COLOR, width=2)
    d.ellipse([110, 128, 124, 144], fill=(15, 15, 20)) # pupil looking right
    d.ellipse([114, 130, 118, 134], fill=(255, 255, 255)) # glare

    # Left eye (viewer's right): center (148, 124) - slightly higher
    d.ellipse([132, 110, 166, 146], fill=(255, 255, 255), outline=OUTLINE_COLOR, width=2)
    d.ellipse([144, 120, 158, 136], fill=(15, 15, 20)) # pupil
    d.ellipse([148, 122, 152, 126], fill=(255, 255, 255)) # glare

    # Big Handlebar Mustache
    # Curved mustache polygon/bezier
    mustache = [
        (100, 158), (114, 146), (130, 144), (146, 146), (160, 158),
        (178, 148), (184, 134), (180, 152), (164, 168), (142, 172),
        (130, 170), (118, 172), (96, 168), (80, 152), (76, 134), (82, 148)
    ]
    d.polygon(mustache, fill=(88, 44, 22), outline=OUTLINE_COLOR)

    # Body block (Khaki explorer shirt / suit)
    body_rect = [74, 180, 182, 280]
    d.rectangle(body_rect, fill=(162, 158, 138), outline=OUTLINE_COLOR, width=OUTLINE_WIDTH)
    # Side shadow on body
    d.rectangle([74, 180, 94, 280], fill=(142, 138, 120))
    # Collar & buttons
    d.line([(128, 180), (128, 280)], fill=OUTLINE_COLOR, width=2)
    d.ellipse([125, 205, 131, 211], fill=(50, 50, 50))
    d.ellipse([125, 235, 131, 241], fill=(50, 50, 50))
    d.ellipse([125, 265, 131, 271], fill=(50, 50, 50))

    # Outer sticker cutout border
    alpha = img.split()[-1]
    dilated = alpha.filter(ImageFilter.MaxFilter(7))
    border_img = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(border_img).bitmap((0, 0), dilated, fill=(255, 255, 255, 255))
    # Drop shadow
    shadow = dilated.filter(ImageFilter.GaussianBlur(4))
    shadow_img = Image.new("RGBA", size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow_img).bitmap((2, 5), shadow, fill=(15, 20, 30, 110))

    final = Image.alpha_composite(shadow_img, border_img)
    final = Image.alpha_composite(final, img)
    final.save(os.path.join(SPRITES_DIR, "character_civitus.png"))

# 2. Generate Stylized Block Textures matching Image 6
def gen_block_textures():
    # 256x256 seamless textures for blocks
    
    # A) Grass Top Texture (lime green with subtle diagonal facets)
    grass = Image.new("RGBA", (128, 128), (145, 205, 25, 255))
    gd = ImageDraw.Draw(grass)
    # Diagonal split facet
    gd.polygon([(0, 0), (128, 0), (0, 128)], fill=(165, 222, 35))
    gd.polygon([(128, 0), (128, 128), (0, 128)], fill=(135, 192, 20))
    grass.save(os.path.join(TILES_DIR, "block_grass_top.png"))

    # B) Dirt Side Texture (warm layered brown with stylized flecks)
    dirt = Image.new("RGBA", (128, 128), (140, 95, 38, 255))
    dd = ImageDraw.Draw(dirt)
    # Darker bottom half layer
    dd.rectangle([0, 64, 128, 128], fill=(110, 72, 28))
    # Top grass rim (green rim)
    dd.rectangle([0, 0, 128, 22], fill=(135, 192, 20))
    # Stylized horizontal dash flecks
    flecks = [
        [15, 38, 35, 42], [70, 48, 95, 52], [40, 85, 65, 89],
        [85, 95, 110, 99], [20, 110, 45, 114]
    ]
    for f in flecks:
        dd.rounded_rectangle(f, radius=2, fill=(80, 50, 18))
    dirt.save(os.path.join(TILES_DIR, "block_dirt_side.png"))

    # C) Water Texture (azure cyan with white dashed ripple lines)
    water = Image.new("RGBA", (128, 128), (0, 195, 245, 255))
    wd = ImageDraw.Draw(water)
    # Diagonal subtle depth
    wd.polygon([(0, 0), (128, 0), (0, 128)], fill=(20, 210, 255))
    wd.polygon([(128, 0), (128, 128), (0, 128)], fill=(0, 180, 230))
    # White horizontal wave dashes
    waves = [
        [20, 25, 48, 29], [65, 38, 90, 42],
        [30, 65, 55, 69], [80, 75, 105, 79],
        [15, 100, 40, 104], [60, 110, 85, 114]
    ]
    for w in waves:
        wd.rounded_rectangle(w, radius=2, fill=(255, 255, 255, 230))
    water.save(os.path.join(TILES_DIR, "block_water.png"))

    # D) Snow Top & Mountain Rock
    snow = Image.new("RGBA", (128, 128), (242, 248, 255, 255))
    sd = ImageDraw.Draw(snow)
    sd.polygon([(0, 0), (128, 0), (0, 128)], fill=(255, 255, 255))
    sd.polygon([(128, 0), (128, 128), (0, 128)], fill=(215, 235, 250))
    snow.save(os.path.join(TILES_DIR, "block_snow_top.png"))

    # E) Resource Ore Blocks (Waste of Space style chunks)
    # Iron (Gris plateado metálico), Copper (Naranja cobrizo), Silicon (Púrpura oscuro), Titanium (Azul acero)
    ores = {
        "ore_iron": ((175, 180, 190), (220, 225, 235)),
        "ore_copper": ((205, 115, 60), (245, 160, 100)),
        "ore_silicon": ((95, 70, 135), (145, 115, 190)),
        "ore_uranium": ((35, 190, 95), (110, 255, 160)),
    }
    for name, (base_c, speck_c) in ores.items():
        ore_img = Image.new("RGBA", (128, 128), (65, 70, 78, 255))
        od = ImageDraw.Draw(ore_img)
        # Vein chunks
        od.polygon([(25, 20), (60, 15), (75, 50), (40, 65)], fill=base_c)
        od.polygon([(30, 25), (55, 20), (50, 45)], fill=speck_c)
        od.polygon([(70, 70), (110, 60), (120, 100), (85, 115)], fill=base_c)
        od.polygon([(75, 75), (105, 65), (95, 95)], fill=speck_c)
        ore_img.save(os.path.join(TILES_DIR, f"{name}.png"))

# 3. Clean Modern Mobile UI Icons (Roblox-style minimalist vectors)
def gen_mobile_icons():
    icon_defs = {
        "icon_joystick_base": (160, 160),
        "icon_joystick_knob": (72, 72),
        "icon_thrust": (80, 80),
        "icon_mine": (80, 80),
        "icon_craft": (80, 80),
        "icon_starmap": (80, 80),
        "icon_cam_left": (70, 70),
        "icon_cam_right": (70, 70),
        "icon_heart": (48, 48),
        "icon_o2": (48, 48),
        "icon_fuel": (48, 48),
    }

    # Joystick Base (Translucent dark circle with glowing cyan outline)
    jb = Image.new("RGBA", (160, 160), (0, 0, 0, 0))
    jbd = ImageDraw.Draw(jb)
    jbd.ellipse([4, 4, 156, 156], fill=(20, 25, 35, 140), outline=(100, 200, 255, 180), width=3)
    jbd.ellipse([30, 30, 130, 130], outline=(100, 200, 255, 60), width=2)
    jb.save(os.path.join(SPRITES_DIR, "icon_joystick_base.png"))

    # Joystick Knob (Solid circular puck with thumb grip)
    jk = Image.new("RGBA", (72, 72), (0, 0, 0, 0))
    jkd = ImageDraw.Draw(jk)
    jkd.ellipse([2, 2, 70, 70], fill=(240, 245, 255, 230), outline=(50, 140, 220, 255), width=3)
    jkd.ellipse([26, 26, 46, 46], fill=(80, 180, 255, 200))
    jk.save(os.path.join(SPRITES_DIR, "icon_joystick_knob.png"))

    # Thrust Icon (Rocket)
    ti = Image.new("RGBA", (80, 80), (0, 0, 0, 0))
    tid = ImageDraw.Draw(ti)
    tid.ellipse([2, 2, 78, 78], fill=(30, 35, 48, 200), outline=(255, 180, 40, 230), width=3)
    # Rocket body
    tid.polygon([(40, 16), (54, 44), (48, 56), (32, 56), (26, 44)], fill=(245, 245, 250))
    tid.polygon([(40, 16), (46, 32), (40, 46), (34, 32)], fill=(240, 80, 60)) # center stripe
    # Wings
    tid.polygon([(26, 44), (16, 56), (28, 56)], fill=(240, 80, 60))
    tid.polygon([(54, 44), (64, 56), (52, 56)], fill=(240, 80, 60))
    # Flame
    tid.polygon([(34, 56), (40, 68), (46, 56)], fill=(255, 200, 50))
    ti.save(os.path.join(SPRITES_DIR, "icon_thrust.png"))

    # Mine / Pickaxe Icon
    mi = Image.new("RGBA", (80, 80), (0, 0, 0, 0))
    mid = ImageDraw.Draw(mi)
    mid.ellipse([2, 2, 78, 78], fill=(30, 35, 48, 200), outline=(80, 220, 255, 230), width=3)
    # Pickaxe head (curved)
    mid.arc([16, 16, 64, 64], 200, 340, fill=(230, 240, 255), width=6)
    # Handle
    mid.line([(40, 40), (62, 62)], fill=(180, 120, 60), width=5)
    mi.save(os.path.join(SPRITES_DIR, "icon_mine.png"))

    # Craft / Wrench Icon
    ci = Image.new("RGBA", (80, 80), (0, 0, 0, 0))
    cid = ImageDraw.Draw(ci)
    cid.ellipse([2, 2, 78, 78], fill=(30, 35, 48, 200), outline=(130, 230, 90, 230), width=3)
    # Wrench head
    cid.line([(24, 24), (54, 54)], fill=(220, 230, 245), width=7)
    cid.ellipse([16, 16, 36, 36], outline=(220, 230, 245), width=5)
    ci.save(os.path.join(SPRITES_DIR, "icon_craft.png"))

    # Starmap Icon
    si = Image.new("RGBA", (80, 80), (0, 0, 0, 0))
    sid = ImageDraw.Draw(si)
    sid.ellipse([2, 2, 78, 78], fill=(30, 35, 48, 200), outline=(180, 140, 255, 230), width=3)
    # Sun and orbit rings
    sid.ellipse([34, 34, 46, 46], fill=(255, 210, 60))
    sid.ellipse([20, 20, 60, 60], outline=(200, 180, 255, 140), width=2)
    sid.ellipse([54, 24, 62, 32], fill=(100, 200, 255)) # planet on ring
    si.save(os.path.join(SPRITES_DIR, "icon_starmap.png"))

    # Camera rotate L / R
    for side, deg in [("cam_left", 180), ("cam_right", 0)]:
        cri = Image.new("RGBA", (70, 70), (0, 0, 0, 0))
        crid = ImageDraw.Draw(cri)
        crid.ellipse([2, 2, 68, 68], fill=(25, 30, 42, 180), outline=(200, 210, 230, 180), width=2)
        if side == "cam_left":
            crid.arc([16, 16, 54, 54], 45, 270, fill=(240, 245, 255), width=4)
            crid.polygon([(14, 36), (24, 24), (26, 40)], fill=(240, 245, 255))
        else:
            crid.arc([16, 16, 54, 54], 270, 135, fill=(240, 245, 255), width=4)
            crid.polygon([(56, 36), (46, 24), (44, 40)], fill=(240, 245, 255))
        cri.save(os.path.join(SPRITES_DIR, f"icon_{side}.png"))

if __name__ == "__main__":
    gen_character()
    gen_block_textures()
    gen_mobile_icons()
    print("Art assets generated successfully!")
