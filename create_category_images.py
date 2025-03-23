#!/usr/bin/env python3
import os
import base64
import json

# Define the categories with their colors and descriptions
categories = [
    {
        "name": "healthy_breakfast", 
        "title": "Healthy Breakfast", 
        "description": "Start your day with nutritious and energizing meals",
        "color": (76, 175, 80)  # Green
    },
    {
        "name": "mediterranean_diet", 
        "title": "Mediterranean Diet", 
        "description": "Heart-healthy choices inspired by Mediterranean cuisine",
        "color": (63, 81, 181)  # Blue
    },
    {
        "name": "protein_rich", 
        "title": "Protein-Rich Meals", 
        "description": "High-protein meals for muscle building and recovery",
        "color": (233, 30, 99)  # Pink
    }
]

# Base directory for the assets
assets_dir = "foodscannerpro/Assets.xcassets/Categories"

# Function to create a more styled SVG image with text
def create_svg_image(name, title, description, color):
    r, g, b = color
    
    # Create gradient colors
    darker_r = max(0, r - 50)
    darker_g = max(0, g - 50)
    darker_b = max(0, b - 50)
    
    svg = f'''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="180" height="180" xmlns="http://www.w3.org/2000/svg">
    <!-- Background with gradient -->
    <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" style="stop-color:rgb({r},{g},{b});stop-opacity:1" />
            <stop offset="100%" style="stop-color:rgb({darker_r},{darker_g},{darker_b});stop-opacity:1" />
        </linearGradient>
        
        <!-- Shadow filter -->
        <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="2" dy="2" stdDeviation="2" flood-opacity="0.3" />
        </filter>
    </defs>
    
    <!-- Card background -->
    <rect width="180" height="180" rx="15" ry="15" fill="url(#grad)" />
    
    <!-- Overlay for text contrast -->
    <rect width="180" height="80" y="100" rx="0" ry="0" fill="rgba(0,0,0,0.3)" />
    
    <!-- Title text -->
    <text x="90" y="130" font-family="Arial, Helvetica, sans-serif" font-size="16" font-weight="bold" fill="white" text-anchor="middle" filter="url(#shadow)">{title}</text>
    
    <!-- Description text -->
    <text x="90" y="155" font-family="Arial, Helvetica, sans-serif" font-size="10" fill="white" text-anchor="middle" opacity="0.9">
        <tspan x="90" dy="0">{description}</tspan>
    </text>
    
    <!-- Decorative elements -->
    <circle cx="90" cy="60" r="25" fill="white" opacity="0.2" />
</svg>'''
    return svg

# Function to save the SVG file
def save_svg(svg_content, output_path):
    with open(output_path, 'w') as f:
        f.write(svg_content)

# Create images for each category
for cat in categories:
    # Create the directory if it doesn't exist
    output_dir = f"{assets_dir}/{cat['name']}.imageset"
    os.makedirs(output_dir, exist_ok=True)
    
    # Create SVG image
    svg_content = create_svg_image(cat['name'], cat['title'], cat['description'], cat['color'])
    
    # Save SVG image
    svg_path = f"{output_dir}/{cat['name']}.svg"
    save_svg(svg_content, svg_path)
    
    print(f"Created SVG image for {cat['title']}")
    
    # Create a Contents.json file that uses the SVG
    contents = {
        "images": [
            {
                "filename": f"{cat['name']}.svg",
                "idiom": "universal",
                "scale": "1x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        },
        "properties": {
            "preserves-vector-representation": True
        }
    }
    
    # Save the Contents.json file
    with open(f"{output_dir}/Contents.json", 'w') as f:
        json.dump(contents, f, indent=2)

print("All category images created successfully!") 