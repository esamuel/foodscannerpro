#!/usr/bin/env python3
import os
import urllib.request
import shutil
import json
import time

# Directories
base_dir = "/Users/samueleskenasy/xCode applications/foodscannerpro"
image_dir = os.path.join(base_dir, "MealImages")
assets_dir = os.path.join(base_dir, "foodscannerpro/Assets.xcassets/FeaturedMeals")

# Create image directory if it doesn't exist
os.makedirs(image_dir, exist_ok=True)

# Meal data with image URLs
meal_images = {
    # Healthy Breakfast meals
    "greek_yogurt_parfait": "https://cdn.pixabay.com/photo/2018/08/16/22/59/dessert-3611599_1280.jpg",
    "avocado_toast": "https://cdn.pixabay.com/photo/2017/05/11/19/44/avocado-toast-2305168_1280.jpg",
    "oatmeal_bowl": "https://cdn.pixabay.com/photo/2016/11/18/14/38/oats-1834933_1280.jpg",
    "smoothie_bowl": "https://cdn.pixabay.com/photo/2017/05/05/19/06/smoothie-2288075_1280.jpg",
    "protein_pancakes": "https://cdn.pixabay.com/photo/2017/01/16/17/45/pancake-1984716_1280.jpg",
    "veggie_frittata": "https://cdn.pixabay.com/photo/2019/08/23/13/03/frittata-4425840_1280.jpg",
    "chia_pudding": "https://cdn.pixabay.com/photo/2018/04/18/18/03/food-3331075_1280.jpg",
    "breakfast_burrito": "https://cdn.pixabay.com/photo/2016/08/23/08/53/tacos-1613795_1280.jpg",
    "quinoa_breakfast": "https://cdn.pixabay.com/photo/2016/10/25/13/42/indian-1768906_1280.jpg",
    "cottage_cheese_toast": "https://cdn.pixabay.com/photo/2016/09/16/17/47/cottage-cheese-1674639_1280.jpg",
    
    # Mediterranean Diet meals
    "greek_salad": "https://cdn.pixabay.com/photo/2016/10/25/13/29/smoked-salmon-salad-1768890_1280.jpg",
    "grilled_fish": "https://cdn.pixabay.com/photo/2019/03/31/14/31/fish-4093509_1280.jpg",
    "hummus_plate": "https://cdn.pixabay.com/photo/2015/10/02/01/23/hummus-967609_1280.jpg",
    "ratatouille": "https://cdn.pixabay.com/photo/2016/09/13/18/38/silverware-1667988_1280.jpg",
    "mediterranean_pasta": "https://cdn.pixabay.com/photo/2019/02/18/20/04/mediterranean-4005334_1280.jpg",
    "falafel_wrap": "https://cdn.pixabay.com/photo/2020/02/29/21/56/falafel-4890821_1280.jpg",
    "seafood_paella": "https://cdn.pixabay.com/photo/2014/10/15/19/17/paella-489894_1280.jpg",
    "tabbouleh": "https://cdn.pixabay.com/photo/2021/01/10/04/37/salad-5904093_1280.jpg",
    "stuffed_peppers": "https://cdn.pixabay.com/photo/2016/06/01/05/20/paprika-1428050_1280.jpg",
    "shakshuka": "https://cdn.pixabay.com/photo/2022/03/02/13/20/shakshuka-7043359_1280.jpg",
    
    # Protein-Rich meals
    "grilled_chicken": "https://cdn.pixabay.com/photo/2016/07/31/17/51/chicken-1559548_1280.jpg",
    "salmon_bowl": "https://cdn.pixabay.com/photo/2016/03/05/20/02/salmon-1238662_1280.jpg",
    "turkey_meatballs": "https://cdn.pixabay.com/photo/2019/09/27/09/59/meatballs-4507662_1280.jpg",
    "lentil_curry": "https://cdn.pixabay.com/photo/2023/04/26/11/09/food-7952044_1280.jpg",
    "tuna_steak": "https://cdn.pixabay.com/photo/2018/11/11/23/18/tuna-3809802_1280.jpg",
    "protein_bowl": "https://cdn.pixabay.com/photo/2017/03/23/19/57/asparagus-2169305_1280.jpg",
    "tofu_stirfry": "https://cdn.pixabay.com/photo/2019/06/03/22/07/wok-4250758_1280.jpg",
    "yogurt_bowl": "https://cdn.pixabay.com/photo/2018/08/16/22/59/dessert-3611599_1280.jpg",
    "egg_white_omelette": "https://cdn.pixabay.com/photo/2015/05/20/16/11/kitchen-775746_1280.jpg",
    "shrimp_skewers": "https://cdn.pixabay.com/photo/2017/08/14/13/23/shrimp-2640921_1280.jpg"
}

# Contents.json template
contents_json = {
    "images": [
        {
            "idiom": "universal",
            "scale": "1x"
        },
        {
            "filename": "image.jpg",
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

# Download and save images
for meal_name, image_url in meal_images.items():
    image_path = os.path.join(image_dir, f"{meal_name}.jpg")
    imageset_dir = os.path.join(assets_dir, f"{meal_name}.imageset")
    
    # Create imageset directory if it doesn't exist
    os.makedirs(imageset_dir, exist_ok=True)
    
    try:
        print(f"Downloading {meal_name} image...")
        # Download the image
        urllib.request.urlretrieve(image_url, image_path)
        
        # Copy to imageset directory
        shutil.copy(image_path, os.path.join(imageset_dir, "image.jpg"))
        
        # Create Contents.json
        with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
            json.dump(contents_json, f, indent=2)
        
        print(f"✅ Successfully added {meal_name} image to asset catalog")
        
        # Small delay to avoid overwhelming the server
        time.sleep(0.5)
        
    except Exception as e:
        print(f"❌ Failed to process {meal_name} image: {str(e)}")

print("\nAll meal images have been added to the asset catalog")
print("Now open your Xcode project to see the images in use") 