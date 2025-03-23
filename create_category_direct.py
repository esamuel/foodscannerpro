#!/usr/bin/env python3
import os
import json
import base64
from PIL import Image, ImageDraw, ImageFont
from io import BytesIO

# Base directory for the assets
assets_dir = "foodscannerpro/Assets.xcassets/Categories"

# Define the categories with their titles and descriptions
categories = [
    {
        "name": "healthy_breakfast", 
        "title": "Healthy Breakfast", 
        "description": "Start your day with nutritious and energizing meals"
    },
    {
        "name": "mediterranean_diet", 
        "title": "Mediterranean Diet", 
        "description": "Heart-healthy choices inspired by Mediterranean cuisine"
    },
    {
        "name": "protein_rich", 
        "title": "Protein-Rich Meals", 
        "description": "High-protein meals for muscle building and recovery"
    }
]

# Function to create a generic category image with text and color
def create_category_image(category, color):
    try:
        # Create a new image
        width, height = 360, 360
        img = Image.new('RGB', (width, height), color=color)
        draw = ImageDraw.Draw(img)
        
        # Add a gradient overlay
        for y in range(height):
            opacity = min(100, int(y / height * 200))
            draw.line([(0, y), (width, y)], fill=(0, 0, 0, opacity))
        
        # Try to use a nice font, fallback to default if not available
        try:
            title_font = ImageFont.truetype("Arial Bold.ttf", 28)
            desc_font = ImageFont.truetype("Arial.ttf", 16)
        except IOError:
            try:
                # macOS system fonts
                title_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 28)
                desc_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 16)
            except IOError:
                # Default bitmap font as a last resort
                title_font = ImageFont.load_default()
                desc_font = title_font
        
        # Add title text
        title_text = category["title"]
        title_bbox = draw.textbbox((0, 0), title_text, font=title_font)
        title_width = title_bbox[2] - title_bbox[0]
        title_height = title_bbox[3] - title_bbox[1]
        title_position = ((width - title_width) // 2, height // 2 - title_height)
        
        # Add shadow for text
        shadow_offset = 2
        draw.text(
            (title_position[0] + shadow_offset, title_position[1] + shadow_offset),
            title_text,
            font=title_font,
            fill=(0, 0, 0, 180)
        )
        
        # Draw title
        draw.text(
            title_position,
            title_text,
            font=title_font,
            fill=(255, 255, 255)
        )
        
        # Draw description
        desc_text = category["description"]
        desc_bbox = draw.textbbox((0, 0), desc_text, font=desc_font)
        desc_width = desc_bbox[2] - desc_bbox[0]
        desc_height = desc_bbox[3] - desc_bbox[1]
        desc_position = ((width - desc_width) // 2, title_position[1] + title_height + 20)
        
        draw.text(
            desc_position,
            desc_text,
            font=desc_font,
            fill=(255, 255, 255, 220)
        )
        
        # Save the image
        target_dir = f"{assets_dir}/{category['name']}.imageset"
        os.makedirs(target_dir, exist_ok=True)
        
        img_path = f"{target_dir}/{category['name']}.jpg"
        img.save(img_path, quality=95)
        
        print(f"Created category image for {category['title']}")
        return True
    except Exception as e:
        print(f"Error creating image for {category['title']}: {str(e)}")
        return False

# Create updated Contents.json for each category
def update_contents_json(category_name):
    contents_path = f"{assets_dir}/{category_name}.imageset/Contents.json"
    
    contents = {
        "images": [
            {
                "filename": f"{category_name}.jpg",
                "idiom": "universal",
                "scale": "1x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    
    print(f"Updated Contents.json for {category_name}")

# Main process
print("Starting category image generation...")

# Define colors for each category
colors = {
    "healthy_breakfast": (76, 175, 80),  # Green
    "mediterranean_diet": (63, 81, 181),  # Blue
    "protein_rich": (233, 30, 99)  # Pink
}

# Process each category
for cat in categories:
    # Create the category image with overlay
    success = create_category_image(cat, colors[cat["name"]])
    
    if success:
        # Update Contents.json
        update_contents_json(cat["name"])

print("\nAll category images have been generated!")
print("Now when you run your app, the category cards will show the images with text.") 