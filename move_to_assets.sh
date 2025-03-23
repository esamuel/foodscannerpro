#!/bin/bash

# Source directory with downloaded images
IMAGE_DIR="/Users/samueleskenasy/xCode applications/foodscannerpro/MealImages"

# Asset catalog directory
ASSETS_DIR="/Users/samueleskenasy/xCode applications/foodscannerpro/foodscannerpro/Assets.xcassets/FeaturedMeals"

# List of all meal names
MEAL_NAMES=(
    "avocado_toast"
    "oatmeal_bowl"
    "smoothie_bowl"
    "protein_pancakes"
    "veggie_frittata"
    "chia_pudding"
    "breakfast_burrito"
    "quinoa_breakfast"
    "cottage_cheese_toast"
    "greek_salad"
    "grilled_fish"
    "hummus_plate"
    "ratatouille"
    "mediterranean_pasta"
    "falafel_wrap"
    "seafood_paella"
    "tabbouleh"
    "stuffed_peppers"
    "shakshuka"
    "grilled_chicken"
    "salmon_bowl"
    "turkey_meatballs"
    "lentil_curry"
    "tuna_steak"
    "protein_bowl"
    "tofu_stirfry"
    "yogurt_bowl"
    "egg_white_omelette"
    "shrimp_skewers"
    "greek_yogurt_parfait"
)

# Copy each image to its respective asset catalog folder
for MEAL in "${MEAL_NAMES[@]}"; do
    SOURCE_FILE="$IMAGE_DIR/${MEAL}.jpg"
    TARGET_DIR="$ASSETS_DIR/${MEAL}.imageset"
    
    if [ -f "$SOURCE_FILE" ]; then
        echo "Copying $MEAL image to asset catalog..."
        
        # Copy the image to the asset catalog directory
        cp "$SOURCE_FILE" "$TARGET_DIR/image.jpg"
        
        # Update the Contents.json file to reference the image
        cat > "$TARGET_DIR/Contents.json" << EOL
{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "image.jpg",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOL
        
        echo "✅ Successfully added $MEAL image to asset catalog"
    else
        echo "❌ Image for $MEAL not found at $SOURCE_FILE"
    fi
done

echo "All meal images have been added to the asset catalog"
echo "Now open your Xcode project to see the images in use" 