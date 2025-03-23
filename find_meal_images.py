#!/usr/bin/env python3
import os
import webbrowser
import json
import time
import urllib.parse

# Directories
base_dir = "/Users/samueleskenasy/xCode applications/foodscannerpro"
download_dir = os.path.join(base_dir, "MealImages")

# Create download directory if it doesn't exist
os.makedirs(download_dir, exist_ok=True)

# List of meal names with search terms for better results
meal_searches = {
    "greek_yogurt_parfait": "greek yogurt parfait with berries and honey",
    "avocado_toast": "avocado toast with egg on whole grain bread",
    "oatmeal_bowl": "oatmeal bowl with fruits and nuts",
    "smoothie_bowl": "acai smoothie bowl with toppings",
    "protein_pancakes": "protein pancakes with berries",
    "veggie_frittata": "vegetable frittata with spinach and peppers",
    "chia_pudding": "chia seed pudding with fruits",
    "breakfast_burrito": "healthy breakfast burrito with vegetables",
    "quinoa_breakfast": "quinoa breakfast bowl",
    "cottage_cheese_toast": "cottage cheese toast with cucumber",
    "greek_salad": "greek salad with feta and olives",
    "grilled_fish": "grilled fish with lemon and herbs",
    "hummus_plate": "hummus plate with vegetables and pita",
    "ratatouille": "ratatouille vegetable stew",
    "mediterranean_pasta": "mediterranean whole grain pasta with vegetables",
    "falafel_wrap": "falafel wrap with tahini sauce",
    "seafood_paella": "spanish seafood paella rice dish",
    "tabbouleh": "tabbouleh salad with bulgur and herbs",
    "stuffed_peppers": "stuffed bell peppers with rice",
    "shakshuka": "shakshuka eggs in tomato sauce",
    "grilled_chicken": "grilled chicken breast with vegetables",
    "salmon_bowl": "salmon bowl with quinoa and avocado",
    "turkey_meatballs": "turkey meatballs with whole grain pasta",
    "lentil_curry": "red lentil curry with rice",
    "tuna_steak": "seared tuna steak with vegetables",
    "protein_bowl": "protein bowl with chicken and vegetables",
    "tofu_stirfry": "tofu stir fry with vegetables",
    "yogurt_bowl": "greek yogurt bowl with granola and berries",
    "egg_white_omelette": "egg white omelette with spinach",
    "shrimp_skewers": "grilled shrimp skewers with vegetables"
}

def open_search_for_image(meal_name, search_term):
    """Open a search for the meal image in the browser"""
    # Different search options
    search_urls = [
        f"https://unsplash.com/s/photos/{urllib.parse.quote(search_term)}",
        f"https://www.pexels.com/search/{urllib.parse.quote(search_term)}/",
        f"https://pixabay.com/images/search/{urllib.parse.quote(search_term)}/"
    ]
    
    # Open each search in a new tab
    for url in search_urls:
        webbrowser.open_new_tab(url)
        time.sleep(1)  # Wait a bit to avoid overwhelming the browser
    
    print(f"\n✅ Opened search for: {meal_name}")
    print(f"   Search term: {search_term}")
    print(f"   These websites allow free downloads for personal use")
    print(f"   Once you find an image you like, download it to: {download_dir}")
    print(f"   Rename it to: {meal_name}.jpg before moving to Xcode")
    print("-" * 70)

# Instructions for the user
print("\n" + "=" * 70)
print("MEAL IMAGE FINDER".center(70))
print("=" * 70)
print("\nThis script will help you find appropriate images for your featured meals.")
print("For each meal, it will open search results in your browser.")
print("You can then:")
print("  1. Browse the results and choose an image you like")
print("  2. Download it to your computer")
print("  3. Rename it to match the meal name (e.g., 'greek_salad.jpg')")
print("  4. Drag it into Xcode's asset catalog")
print("\nImages will be searched in batches of 5 to avoid overwhelming your browser.")
print("Press Enter after each batch to continue to the next set of meals.")
print("=" * 70)

# Batch process the meals (5 at a time)
batch_size = 5
meal_items = list(meal_searches.items())

for i in range(0, len(meal_items), batch_size):
    batch = meal_items[i:i+batch_size]
    
    print(f"\nOpening searches for batch {i//batch_size + 1} of {(len(meal_items) + batch_size - 1)//batch_size}:")
    for j, (meal_name, search_term) in enumerate(batch, 1):
        print(f"  {j}. {meal_name.replace('_', ' ').title()}")
    
    for meal_name, search_term in batch:
        open_search_for_image(meal_name, search_term)
    
    if i + batch_size < len(meal_items):
        input("\nPress Enter to open the next batch of meal searches...")

print("\n" + "=" * 70)
print("All meal searches have been opened.")
print("After downloading the images, you can:")
print("1. Rename them according to the meal names (e.g., 'greek_salad.jpg')")
print("2. Open your Xcode project")
print("3. Navigate to Assets.xcassets > FeaturedMeals")
print("4. Drag each image to its corresponding image asset")
print("=" * 70)

# For convenience, also open the download directory
webbrowser.open('file:///' + download_dir) 