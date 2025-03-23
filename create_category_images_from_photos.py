#!/usr/bin/env python3
import os
import json
import shutil
from PIL import Image, ImageDraw, ImageFont

# Define the image paths
image_paths = {
    "healthy_breakfast": "temp_images/healthy_breakfast_photo.jpg",  # Yogurt parfait
    "mediterranean_diet": "temp_images/mediterranean_diet_photo.jpg",  # Mediterranean ingredients
    "protein_rich": "temp_images/protein_rich_photo.jpg"  # Protein sources
}

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

# Base directory for the assets
assets_dir = "foodscannerpro/Assets.xcassets/Categories"

# Function to create an image with text overlay
def create_category_image_with_overlay(source_path, category):
    try:
        # Open the original image
        img = Image.open(source_path)
        
        # Resize to 180x180
        img = img.resize((360, 360))  # Making it 2x for better quality
        
        # Create a semi-transparent overlay at the bottom
        draw = ImageDraw.Draw(img)
        
        # Add a dark gradient overlay at the bottom
        height = img.height
        for i in range(80):
            # Create a gradually increasing opacity from top to bottom of overlay
            opacity = int(180 * (i / 80))  # Max opacity of 180 (out of 255)
            draw.rectangle(
                [(0, height - 80 + i), (img.width, height - 80 + i + 1)],
                fill=(0, 0, 0, opacity)
            )
        
        # Try to use a nice font, fallback to default if not available
        try:
            title_font = ImageFont.truetype("Arial Bold.ttf", 24)
            desc_font = ImageFont.truetype("Arial.ttf", 14)
        except IOError:
            try:
                # macOS system fonts
                title_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 24)
                desc_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 14)
            except IOError:
                # Default bitmap font as a last resort
                title_font = ImageFont.load_default()
                desc_font = title_font
        
        # Add title text
        title_text = category["title"]
        title_bbox = draw.textbbox((0, 0), title_text, font=title_font)
        title_width = title_bbox[2] - title_bbox[0]
        title_position = ((img.width - title_width) // 2, height - 60)
        
        # Add text shadow
        draw.text((title_position[0] + 2, title_position[1] + 2), title_text, font=title_font, fill=(0, 0, 0, 180))
        # Draw title
        draw.text(title_position, title_text, font=title_font, fill=(255, 255, 255, 230))
        
        # Add description text
        desc_text = category["description"]
        desc_bbox = draw.textbbox((0, 0), desc_text, font=desc_font)
        desc_width = desc_bbox[2] - desc_bbox[0]
        desc_position = ((img.width - desc_width) // 2, height - 30)
        
        # Draw description
        draw.text(desc_position, desc_text, font=desc_font, fill=(255, 255, 255, 200))
        
        # Save the image
        target_dir = f"{assets_dir}/{category['name']}.imageset"
        os.makedirs(target_dir, exist_ok=True)
        
        # Save as 1x, 2x and 3x versions
        img_path_1x = f"{target_dir}/{category['name']}.jpg"
        img_path_2x = f"{target_dir}/{category['name']}@2x.jpg"
        img_path_3x = f"{target_dir}/{category['name']}@3x.jpg"
        
        # Save the original size as 2x
        img.save(img_path_2x, quality=95)
        
        # Create and save a 1x version (half size)
        img_1x = img.resize((180, 180), Image.LANCZOS)
        img_1x.save(img_path_1x, quality=90)
        
        # For 3x, we'll just copy the 2x version since we don't have a larger original
        shutil.copy2(img_path_2x, img_path_3x)
        
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
            },
            {
                "filename": f"{category_name}@2x.jpg",
                "idiom": "universal",
                "scale": "2x"
            },
            {
                "filename": f"{category_name}@3x.jpg",
                "idiom": "universal",
                "scale": "3x"
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
print("Starting category image processing...")

# Create temp_images directory if it doesn't exist
os.makedirs("temp_images", exist_ok=True)

# Check if the source images exist
missing_images = []
for cat in categories:
    if not os.path.exists(image_paths[cat["name"]]):
        missing_images.append((cat["name"], image_paths[cat["name"]]))

if missing_images:
    print("Warning: Some source images are missing!")
    print("Please save the following images to continue:")
    for name, path in missing_images:
        print(f"  - {path} for {name}")
    print("\nPlease run this script again after saving the images.")
    exit(1)

# Process each category
for cat in categories:
    # Create the category image with overlay
    success = create_category_image_with_overlay(image_paths[cat["name"]], cat)
    
    if success:
        # Update Contents.json
        update_contents_json(cat["name"])

print("\nAll category images have been processed!")
print("Now when you run your app, it will show the real food photos in the category cards.") 