#!/bin/bash

# Directory to save images
IMAGE_DIR="/Users/samueleskenasy/xCode applications/foodscannerpro/MealImages"

# Create directory if it doesn't exist
mkdir -p "$IMAGE_DIR"

# Function to download and save an image
download_image() {
  local meal_name=$1
  local image_url=$2
  
  # Format the output filename
  local filename="${meal_name}.jpg"
  
  echo "Downloading $meal_name image..."
  curl -s -o "$IMAGE_DIR/$filename" "$image_url"
  
  if [ $? -eq 0 ]; then
    echo "✅ Successfully downloaded $meal_name image to $IMAGE_DIR/$filename"
  else
    echo "❌ Failed to download $meal_name image"
  fi
}

# Create the directory
echo "Creating directory: $IMAGE_DIR"
mkdir -p "$IMAGE_DIR"

# Download images for each meal
# Healthy Breakfast meals
download_image "greek_yogurt_parfait" "https://cdn.pixabay.com/photo/2016/11/18/14/39/beans-1834984_1280.jpg"
download_image "avocado_toast" "https://cdn.pixabay.com/photo/2017/05/11/19/44/avocado-toast-2305168_1280.jpg"
download_image "oatmeal_bowl" "https://cdn.pixabay.com/photo/2016/11/18/14/38/oats-1834933_1280.jpg"
download_image "smoothie_bowl" "https://cdn.pixabay.com/photo/2017/05/05/19/06/smoothie-2288075_1280.jpg"
download_image "protein_pancakes" "https://cdn.pixabay.com/photo/2017/01/16/17/45/pancake-1984716_1280.jpg"
download_image "veggie_frittata" "https://cdn.pixabay.com/photo/2019/08/23/13/03/frittata-4425840_1280.jpg"
download_image "chia_pudding" "https://cdn.pixabay.com/photo/2018/04/18/18/03/food-3331075_1280.jpg"
download_image "breakfast_burrito" "https://cdn.pixabay.com/photo/2016/08/23/08/53/tacos-1613795_1280.jpg"
download_image "quinoa_breakfast" "https://cdn.pixabay.com/photo/2016/10/25/13/42/indian-1768906_1280.jpg"
download_image "cottage_cheese_toast" "https://cdn.pixabay.com/photo/2016/09/16/17/47/cottage-cheese-1674639_1280.jpg"

# Mediterranean Diet meals
download_image "greek_salad" "https://cdn.pixabay.com/photo/2016/10/25/13/29/smoked-salmon-salad-1768890_1280.jpg"
download_image "grilled_fish" "https://cdn.pixabay.com/photo/2019/03/31/14/31/fish-4093509_1280.jpg"
download_image "hummus_plate" "https://cdn.pixabay.com/photo/2015/10/02/01/23/hummus-967609_1280.jpg"
download_image "ratatouille" "https://cdn.pixabay.com/photo/2016/09/13/18/38/silverware-1667988_1280.jpg"
download_image "mediterranean_pasta" "https://cdn.pixabay.com/photo/2019/02/18/20/04/mediterranean-4005334_1280.jpg"
download_image "falafel_wrap" "https://cdn.pixabay.com/photo/2020/02/29/21/56/falafel-4890821_1280.jpg"
download_image "seafood_paella" "https://cdn.pixabay.com/photo/2014/10/15/19/17/paella-489894_1280.jpg"
download_image "tabbouleh" "https://cdn.pixabay.com/photo/2021/01/10/04/37/salad-5904093_1280.jpg"
download_image "stuffed_peppers" "https://cdn.pixabay.com/photo/2016/06/01/05/20/paprika-1428050_1280.jpg"
download_image "shakshuka" "https://cdn.pixabay.com/photo/2022/03/02/13/20/shakshuka-7043359_1280.jpg"

# Protein-Rich meals
download_image "grilled_chicken" "https://cdn.pixabay.com/photo/2016/07/31/17/51/chicken-1559548_1280.jpg"
download_image "salmon_bowl" "https://cdn.pixabay.com/photo/2016/03/05/20/02/salmon-1238662_1280.jpg"
download_image "turkey_meatballs" "https://cdn.pixabay.com/photo/2019/09/27/09/59/meatballs-4507662_1280.jpg"
download_image "lentil_curry" "https://cdn.pixabay.com/photo/2023/04/26/11/09/food-7952044_1280.jpg"
download_image "tuna_steak" "https://cdn.pixabay.com/photo/2018/11/11/23/18/tuna-3809802_1280.jpg"
download_image "protein_bowl" "https://cdn.pixabay.com/photo/2017/03/23/19/57/asparagus-2169305_1280.jpg"
download_image "tofu_stirfry" "https://cdn.pixabay.com/photo/2019/06/03/22/07/wok-4250758_1280.jpg"
download_image "yogurt_bowl" "https://cdn.pixabay.com/photo/2018/08/16/22/59/dessert-3611599_1280.jpg"
download_image "egg_white_omelette" "https://cdn.pixabay.com/photo/2015/05/20/16/11/kitchen-775746_1280.jpg"
download_image "shrimp_skewers" "https://cdn.pixabay.com/photo/2017/08/14/13/23/shrimp-2640921_1280.jpg"

echo "All meal images have been downloaded to $IMAGE_DIR"
echo "You can now drag and drop these images into your Xcode asset catalog" 