#!/usr/bin/env python3
import os
import json
from PIL import Image, ImageDraw, ImageFont
import random

# Directories
base_dir = "/Users/samueleskenasy/xCode applications/foodscannerpro"
image_dir = os.path.join(base_dir, "MealImages")
assets_dir = os.path.join(base_dir, "foodscannerpro/Assets.xcassets/FeaturedMeals")

# Create image directory if it doesn't exist
os.makedirs(image_dir, exist_ok=True)

# List of meal names
meal_names = [
    "greek_yogurt_parfait", 
    "avocado_toast",
    "oatmeal_bowl",
    "smoothie_bowl",
    "protein_pancakes",
    "veggie_frittata",
    "chia_pudding",
    "breakfast_burrito",
    "quinoa_breakfast",
    "cottage_cheese_toast",
    "greek_salad",
    "grilled_fish",
    "hummus_plate",
    "ratatouille",
    "mediterranean_pasta",
    "falafel_wrap",
    "seafood_paella",
    "tabbouleh",
    "stuffed_peppers",
    "shakshuka",
    "grilled_chicken",
    "salmon_bowl",
    "turkey_meatballs",
    "lentil_curry",
    "tuna_steak",
    "protein_bowl",
    "tofu_stirfry",
    "yogurt_bowl",
    "egg_white_omelette",
    "shrimp_skewers"
]

# Colors for backgrounds
colors = [
    (255, 200, 200), # Light Red
    (200, 255, 200), # Light Green
    (200, 200, 255), # Light Blue
    (255, 255, 200), # Light Yellow
    (255, 200, 255), # Light Purple
    (200, 255, 255), # Light Cyan
    (240, 240, 240)  # Light Gray
]

# Contents.json template
contents_json = {
    "images": [
        {
            "idiom": "universal",
            "scale": "1x"
        },
        {
            "filename": "image.png",
            "idiom": "universal",
            "scale": "2x"
        },
        {
            "idiom": "universal",
            "scale": "3x"
        }
    ],
    "info": {
        "author": "xcode",
        "version": 1
    }
}

def create_placeholder(meal_name, size=(600, 400)):
    """Create a placeholder image with the meal name and a background color"""
    # Format the display name from the meal name
    display_name = meal_name.replace("_", " ").title()
    
    # Create a new image with a random background color
    bg_color = random.choice(colors)
    image = Image.new('RGB', size, color=bg_color)
    draw = ImageDraw.Draw(image)
    
    try:
        # Try to load a font (fallback to default if not available)
        font_large = ImageFont.truetype("Arial", 48)
        font_small = ImageFont.truetype("Arial", 24)
    except IOError:
        # Fallback to default font
        font_large = ImageFont.load_default()
        font_small = font_large
    
    # Draw text centered on the image
    text_width, text_height = draw.textsize(display_name, font=font_large)
    position = ((size[0] - text_width) / 2, (size[1] - text_height) / 2 - 20)
    
    # Draw a rounded rectangle for the text background
    rect_padding = 20
    rect_left = position[0] - rect_padding
    rect_top = position[1] - rect_padding
    rect_right = position[0] + text_width + rect_padding
    rect_bottom = position[1] + text_height + rect_padding
    
    # Draw a shadow
    shadow_offset = 4
    draw.rectangle(
        (rect_left + shadow_offset, rect_top + shadow_offset, 
         rect_right + shadow_offset, rect_bottom + shadow_offset),
        fill=(50, 50, 50, 100)
    )
    
    # Draw the background rectangle
    draw.rectangle(
        (rect_left, rect_top, rect_right, rect_bottom),
        fill=(255, 255, 255, 200),
        outline=(100, 100, 100)
    )
    
    # Draw the text
    draw.text(position, display_name, font=font_large, fill=(0, 0, 0))
    
    # Draw "Placeholder" text at the bottom
    footer_text = "Food Scanner Pro | Meal Image Placeholder"
    footer_width, footer_height = draw.textsize(footer_text, font=font_small)
    footer_position = ((size[0] - footer_width) / 2, size[1] - footer_height - 20)
    draw.text(footer_position, footer_text, font=font_small, fill=(50, 50, 50))
    
    return image

# Generate and save placeholder images
for meal_name in meal_names:
    try:
        # Create the placeholder image
        image = create_placeholder(meal_name)
        
        # Save to the temporary directory
        image_path = os.path.join(image_dir, f"{meal_name}.png")
        image.save(image_path)
        
        # Get the imageset directory
        imageset_dir = os.path.join(assets_dir, f"{meal_name}.imageset")
        os.makedirs(imageset_dir, exist_ok=True)
        
        # Copy to the imageset directory
        target_path = os.path.join(imageset_dir, "image.png")
        image.save(target_path)
        
        # Create/update the Contents.json file
        with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
            json.dump(contents_json, f, indent=2)
        
        print(f"✅ Created placeholder for {meal_name}")
        
    except Exception as e:
        print(f"❌ Failed to create placeholder for {meal_name}: {str(e)}")

print("\nAll placeholder images have been created and added to the asset catalog")
print("Now open your Xcode project to see the images in use") 