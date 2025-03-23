#!/bin/bash

ASSETS_DIR="foodscannerpro/Assets.xcassets/Categories"

# Create category images using macOS screencapture and text rendering

# Function to create a simple colored image with text
create_category_image() {
    local name=$1
    local title=$2
    local bgcolor=$3
    local output_dir="$ASSETS_DIR/$name.imageset"
    
    # Create the text content in HTML
    cat > temp.html <<EOF
<html>
<head>
<style>
body {
    margin: 0;
    padding: 0;
    width: 360px;
    height: 360px;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: $bgcolor;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
}
.container {
    text-align: center;
    padding: 20px;
}
h1 {
    font-size: 28px;
    font-weight: bold;
    margin-bottom: 20px;
    color: white;
    text-shadow: 0 2px 4px rgba(0,0,0,0.3);
}
</style>
</head>
<body>
    <div class="container">
        <h1>$title</h1>
    </div>
</body>
</html>
EOF

    # Open in Safari and take screenshot
    open -a Safari temp.html
    sleep 1
    
    # Take screenshot and save to the correct location
    screencapture -l$(osascript -e 'tell app "Safari" to id of window 1') -R0,0,360,360 "$output_dir/$name.png"
    
    # Create 2x and 3x versions
    cp "$output_dir/$name.png" "$output_dir/$name@2x.png"
    cp "$output_dir/$name.png" "$output_dir/$name@3x.png"
    
    # Close Safari
    osascript -e 'tell application "Safari" to close (every window)'
    
    # Remove temp file
    rm temp.html
    
    echo "Created category image for $title"
}

# Create the category images
create_category_image "healthy_breakfast" "Healthy Breakfast" "#4CAF50"
create_category_image "mediterranean_diet" "Mediterranean Diet" "#3F51B5"
create_category_image "protein_rich" "Protein-Rich Meals" "#E91E63"

echo "All category images created successfully!" 