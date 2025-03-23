#!/bin/bash

# Get the directory where the script is located
ASSETS_DIR="/Users/samueleskenasy/xCode applications/foodscannerpro/foodscannerpro/Assets.xcassets/FeaturedMeals"

# List of meal image URLs
MEAL_IMAGES=(
    "avocado_toast"
    "oatmeal_bowl"
    "smoothie_bowl"
    "protein_pancakes"
    "veggie_frittata"
    "chia_pudding"
    "breakfast_burrito"
    "quinoa_breakfast"
    "cottage_cheese_toast"
    "grilled_fish"
    "hummus_plate"
    "ratatouille"
    "mediterranean_pasta"
    "falafel_wrap"
    "seafood_paella"
    "tabbouleh"
    "stuffed_peppers"
    "shakshuka"
    "salmon_bowl"
    "turkey_meatballs"
    "lentil_curry"
    "tuna_steak"
    "protein_bowl"
    "tofu_stirfry"
    "yogurt_bowl"
    "egg_white_omelette"
    "shrimp_skewers"
)

# Standard Contents.json content
CONTENTS='{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "filename" : "placeholder.png",
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
}'

# Loop through each meal image
for MEAL in "${MEAL_IMAGES[@]}"; do
    # Create Contents.json file
    echo "$CONTENTS" > "$ASSETS_DIR/$MEAL.imageset/Contents.json"
    echo "Created Contents.json for $MEAL"
done

echo "All Contents.json files created successfully!" 