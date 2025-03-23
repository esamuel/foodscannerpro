#!/usr/bin/env python3
import os
import json

# Directories
base_dir = "/Users/samueleskenasy/xCode applications/foodscannerpro"
assets_dir = os.path.join(base_dir, "foodscannerpro/Assets.xcassets/FeaturedMeals")

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

# Update Contents.json for each imageset
for meal_name in meal_names:
    try:
        # Get the imageset directory
        imageset_dir = os.path.join(assets_dir, f"{meal_name}.imageset")
        
        # Create the directory if it doesn't exist
        os.makedirs(imageset_dir, exist_ok=True)
        
        # Contents.json - we'll have a placeholder name but no actual image file
        # This will let Xcode display the placeholder in the UI
        contents_json = {
            "images": [
                {
                    "idiom": "universal",
                    "scale": "1x"
                },
                {
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
            },
            "properties": {
                "template-rendering-intent": "original"
            }
        }
        
        # Create/update the Contents.json file
        with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
            json.dump(contents_json, f, indent=2)
        
        print(f"✅ Updated {meal_name} image asset")
        
    except Exception as e:
        print(f"❌ Failed to update {meal_name} image asset: {str(e)}")

print("\nAll meal image assets have been updated")
print("You can now add actual images to each .imageset folder using Xcode") 