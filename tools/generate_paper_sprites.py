import os
import math
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = "assets/sprites"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def add_paper_sticker_border(img, border_width=4, border_color=(255, 255, 255, 255), shadow=True):
    # Extract alpha mask
    alpha = img.split()[-1]
    # Dilate mask for border
    dilated = alpha
    for _ in range(border_width):
        dilated = dilated.filter(ImageFilter.MaxFilter(3))
    
    # Create border image
    border_img = Image.new("RGBA", img.size, (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border_img)
    border_draw.bitmap((0, 0), dilated, fill=border_color)
    
    # Create final composite
    if shadow:
        shadow_mask = dilated.filter(ImageFilter.GaussianBlur(3))
        shadow_img = Image.new("RGBA", img.size, (0, 0, 0, 0))
        shadow_draw = ImageDraw.Draw(shadow_img)
        shadow_draw.bitmap((2, 4), shadow_mask, fill=(10, 15, 25, 120))
        final = Image.alpha_composite(shadow_img, border_img)
    else:
        final = border_img
        
    final = Image.alpha_composite(final, img)
    return final

# 1. Astronaut Paper Cutout (128x128)
def create_astronaut():
    size = (128, 128)
    base = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    
    # Body (Spacesuit)
    d.rounded_rectangle([42, 58, 86, 102], radius=14, fill=(235, 238, 245), outline=(170, 180, 200), width=2)
    # Suit belt & details
    d.rectangle([46, 80, 82, 86], fill=(50, 60, 80))
    d.rectangle([58, 81, 70, 85], fill=(70, 180, 240)) # buckle
    
    # Backpack (Oxygen tank)
    d.rounded_rectangle([32, 64, 42, 94], radius=4, fill=(200, 70, 70), outline=(140, 40, 40), width=2)
    d.rounded_rectangle([86, 64, 96, 94], radius=4, fill=(200, 70, 70), outline=(140, 40, 40), width=2)
    
    # Legs
    d.rounded_rectangle([44, 98, 58, 116], radius=6, fill=(225, 230, 240), outline=(160, 170, 190), width=2)
    d.rounded_rectangle([70, 98, 84, 116], radius=6, fill=(225, 230, 240), outline=(160, 170, 190), width=2)
    
    # Boots
    d.rounded_rectangle([40, 110, 59, 120], radius=4, fill=(80, 90, 110))
    d.rounded_rectangle([69, 110, 88, 120], radius=4, fill=(80, 90, 110))
    
    # Arms
    d.rounded_rectangle([32, 66, 44, 92], radius=6, fill=(225, 230, 240), outline=(160, 170, 190), width=2)
    d.rounded_rectangle([84, 66, 96, 92], radius=6, fill=(225, 230, 240), outline=(160, 170, 190), width=2)
    
    # Helmet (Circle)
    d.ellipse([36, 16, 92, 70], fill=(245, 248, 255), outline=(170, 180, 200), width=3)
    
    # Visor (Reflective glass - Gold/Cyan)
    d.ellipse([44, 26, 84, 58], fill=(20, 35, 55), outline=(250, 190, 40), width=2)
    # Visor reflection
    d.ellipse([50, 30, 64, 44], fill=(80, 210, 250, 220))
    d.ellipse([54, 34, 58, 38], fill=(255, 255, 255, 240))
    
    # Antenna
    d.line([64, 8, 64, 16], fill=(120, 130, 150), width=3)
    d.ellipse([61, 4, 67, 10], fill=(255, 80, 80))
    
    sticker = add_paper_sticker_border(base, border_width=4)
    sticker.save(os.path.join(OUTPUT_DIR, "astronaut_paper.png"))

# 2. Alien Crystal Ore
def create_crystal(filename, core_color, glow_color):
    size = (96, 96)
    base = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    
    # Crystal facets
    poly1 = [(48, 12), (72, 36), (62, 84), (48, 80)]
    poly2 = [(48, 12), (48, 80), (34, 84), (24, 36)]
    poly3 = [(48, 12), (60, 38), (48, 80), (36, 38)]
    
    d.polygon(poly1, fill=glow_color, outline=(255, 255, 255, 200))
    d.polygon(poly2, fill=core_color, outline=(255, 255, 255, 180))
    d.polygon(poly3, fill=(255, 255, 255, 230), outline=(255, 255, 255, 255))
    
    # Small side crystals
    d.polygon([(62, 50), (84, 62), (74, 86), (58, 78)], fill=glow_color)
    d.polygon([(34, 52), (12, 65), (22, 86), (38, 78)], fill=core_color)
    
    sticker = add_paper_sticker_border(base, border_width=3)
    sticker.save(os.path.join(OUTPUT_DIR, filename))

# 3. Papercraft Base Lander / Spaceship
def create_lander():
    size = (160, 160)
    base = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(base)
    
    # Hull (Capsule / Lander body)
    d.polygon([(80, 20), (125, 85), (105, 125), (55, 125), (35, 85)], fill=(240, 242, 248), outline=(160, 175, 195), width=3)
    
    # Top cockpit dome
    d.ellipse([62, 45, 98, 75], fill=(30, 45, 75), outline=(70, 200, 255), width=3)
    d.ellipse([68, 50, 78, 60], fill=(255, 255, 255, 200)) # glare
    
    # Stripe
    d.rectangle([50, 95, 110, 105], fill=(230, 75, 60))
    
    # Thruster bell
    d.polygon([(65, 125), (95, 125), (102, 142), (58, 142)], fill=(90, 95, 110))
    
    # Landing legs
    d.line([(45, 100), (20, 145), (10, 148)], fill=(120, 130, 145), width=5)
    d.line([(115, 100), (140, 145), (150, 148)], fill=(120, 130, 145), width=5)
    
    # Foot pads
    d.ellipse([5, 144, 25, 152], fill=(60, 65, 75))
    d.ellipse([135, 144, 155, 152], fill=(60, 65, 75))
    
    sticker = add_paper_sticker_border(base, border_width=4)
    sticker.save(os.path.join(OUTPUT_DIR, "lander_pod.png"))

if __name__ == "__main__":
    create_astronaut()
    create_crystal("crystal_cyan.png", (0, 160, 220), (80, 230, 255))
    create_crystal("crystal_gold.png", (220, 140, 20), (255, 215, 60))
    create_lander()
    print("Paper sprites generated successfully!")
