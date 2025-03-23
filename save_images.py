#!/usr/bin/env python3
import os
import requests
import json
from PIL import Image
import io
import base64

# Create necessary directories
os.makedirs("temp_images", exist_ok=True)

# Helper function to save images from the internet
def save_image_from_url(url, filename):
    try:
        response = requests.get(url)
        response.raise_for_status()  # Check for HTTP errors
        
        with open(filename, 'wb') as f:
            f.write(response.content)
        
        print(f"Successfully saved {filename}")
        return True
    except Exception as e:
        print(f"Error saving {filename}: {str(e)}")
        return False

# Download and save the images
print("Please manually save the following images:")
print("1. Save the yogurt parfait image as: temp_images/healthy_breakfast_photo.jpg")
print("2. Save the Mediterranean ingredients image as: temp_images/mediterranean_diet_photo.jpg")
print("3. Save the protein sources image as: temp_images/protein_rich_photo.jpg")
print("\nAfter saving these images, run the create_category_images_from_photos.py script.") 