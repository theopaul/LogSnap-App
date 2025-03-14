#!/bin/bash

# Create a temporary directory for our icons
ICON_DIR="LogSnap/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$ICON_DIR"

# Function to create a placeholder icon with size and text
create_icon() {
    size=$1
    output_file="$ICON_DIR/icon_$size.png"
    
    # Use convert from ImageMagick to create a simple icon
    # If ImageMagick is not installed, this will fail
    convert -size ${size}x${size} xc:blue -fill white -pointsize $(($size/4)) \
        -gravity center -annotate 0 "LogSnap" "$output_file"
    
    echo "Created $output_file"
}

# Create all required icon sizes
create_icon 20
create_icon 29
create_icon 40
create_icon 58
create_icon 60
create_icon 76
create_icon 80
create_icon 87
create_icon 120
create_icon 152
create_icon 167
create_icon 180
create_icon 1024

echo "All app icons generated." 