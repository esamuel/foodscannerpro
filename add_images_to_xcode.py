#!/usr/bin/env python3
import os
import json
import shutil
import glob

# Directories
base_dir = "/Users/samueleskenasy/xCode applications/foodscannerpro"
download_dir = os.path.join(base_dir, "MealImages")
assets_dir = os.path.join(base_dir, "foodscannerpro/Assets.xcassets/FeaturedMeals")

# List of all meal names we're expecting images for
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

# Contents.json template
contents_json = {
    "images": [
        {
            "idiom": "universal",
            "scale": "1x"
        },
        {
            "filename": "image.jpg",  # Will be updated with actual filename
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

def process_downloaded_images():
    """Process all downloaded images in the MealImages directory"""
    print("\n" + "=" * 70)
    print("XCODE IMAGE IMPORTER".center(70))
    print("=" * 70)
    print(f"Looking for images in: {download_dir}")
    
    # Find all image files in the download directory
    image_files = []
    for ext in ['*.jpg', '*.jpeg', '*.png']:
        image_files.extend(glob.glob(os.path.join(download_dir, ext)))
    
    if not image_files:
        print("\nNo images found in the download directory.")
        print(f"Please download images to: {download_dir}")
        print("Make sure to name them according to the meal (e.g., 'greek_salad.jpg')")
        return
    
    print(f"\nFound {len(image_files)} images")
    print("\nProcessing images...")
    
    for image_path in image_files:
        filename = os.path.basename(image_path)
        name, ext = os.path.splitext(filename)
        
        # Check if this matches any meal name
        matching_meal = None
        for meal_name in meal_names:
            if name.lower() == meal_name.lower() or name.lower().replace(" ", "_") == meal_name.lower():
                matching_meal = meal_name
                break
        
        if matching_meal:
            imageset_dir = os.path.join(assets_dir, f"{matching_meal}.imageset")
            target_path = os.path.join(imageset_dir, f"image{ext}")
            
            try:
                # Copy the image to the asset catalog
                shutil.copy(image_path, target_path)
                
                # Update the Contents.json
                contents_path = os.path.join(imageset_dir, "Contents.json")
                
                # Make a copy of the template and update the filename
                json_data = contents_json.copy()
                json_data["images"][1]["filename"] = f"image{ext}"
                
                with open(contents_path, "w") as f:
                    json.dump(json_data, f, indent=2)
                
                print(f"✅ Added {filename} to {matching_meal} asset")
            except Exception as e:
                print(f"❌ Failed to process {filename}: {str(e)}")
        else:
            print(f"⚠️  Warning: {filename} doesn't match any meal name")
            print("   Rename it to match one of these meal names:")
            for i, name in enumerate(meal_names):
                if i > 0 and i % 5 == 0:
                    print()  # Line break every 5 items
                print(f"   - {name}", end="  ")
            print("\n")
    
    print("\n" + "=" * 70)
    print("Import complete!")
    print("Open your Xcode project and check the Assets.xcassets/FeaturedMeals folder")
    print("to see your imported images.")
    print("=" * 70)

if __name__ == "__main__":
    process_downloaded_images() 