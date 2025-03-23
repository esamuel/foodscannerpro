#!/usr/bin/env python3
import os
import sys
import urllib.request
from PIL import Image
from io import BytesIO

# Make sure we have the temp_images directory
os.makedirs("temp_images", exist_ok=True)

# Define the image URLs (these will be entered by the user)
print("To use this script, you need to first:")
print("1. Download the images from the chat to your computer")
print("2. Then place them in the temp_images folder with these names:")
print("   - healthy_breakfast_photo.jpg (the yogurt parfait image)")
print("   - mediterranean_diet_photo.jpg (the Mediterranean diet ingredients image)")
print("   - protein_rich_photo.jpg (the protein-rich foods image)")
print("\nAfter you've done this, run the create_category_images_from_photos.py script")

# Create empty placeholder files to remind the user what images to add
for filename in ["healthy_breakfast_photo.jpg", "mediterranean_diet_photo.jpg", "protein_rich_photo.jpg"]:
    filepath = os.path.join("temp_images", filename)
    if not os.path.exists(filepath):
        # Create a simple text image with instructions
        width, height = 400, 200
        image = Image.new('RGB', (width, height), color=(240, 240, 240))
        
        try:
            from PIL import ImageDraw, ImageFont
            draw = ImageDraw.Draw(image)
            try:
                font = ImageFont.truetype("Arial.ttf", 14)
            except:
                font = ImageFont.load_default()
                
            text = f"Please replace this with the\nappropriate image for:\n\n{filename}"
            textbbox = draw.textbbox((0,0), text, font=font)
            text_width = textbbox[2] - textbbox[0]
            text_height = textbbox[3] - textbbox[1]
            position = ((width - text_width) // 2, (height - text_height) // 2)
            draw.text(position, text, font=font, fill=(0, 0, 0))
        except Exception as e:
            print(f"Warning: Could not create text on image: {str(e)}")
        
        try:
            image.save(filepath)
            print(f"Created placeholder for {filename}")
        except Exception as e:
            print(f"Warning: Could not save placeholder file: {str(e)}")

print("\nPlaceholder files created. Please replace them with the actual images.")
print("After replacing the images, run: ./create_category_images_from_photos.py") 