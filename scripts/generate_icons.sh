#!/bin/bash

# Create icons directory if it doesn't exist
mkdir -p web/icons

# Convert SVG to various PNG sizes
# Regular icons
inkscape -w 32 -h 32 web/icons/app-icon.svg -o web/favicon.png
inkscape -w 192 -h 192 web/icons/app-icon.svg -o web/icons/Icon-192.png
inkscape -w 512 -h 512 web/icons/app-icon.svg -o web/icons/Icon-512.png

# Maskable icons (with padding for safe area)
# For maskable icons, we'll use 80% of the space to ensure content is within the safe area
inkscape -w 240 -h 240 web/icons/app-icon.svg -o web/icons/temp.png
convert web/icons/temp.png -resize 192x192 -gravity center -background none -extent 192x192 web/icons/Icon-maskable-192.png

inkscape -w 640 -h 640 web/icons/app-icon.svg -o web/icons/temp.png
convert web/icons/temp.png -resize 512x512 -gravity center -background none -extent 512x512 web/icons/Icon-maskable-512.png

# Clean up temporary files
rm -f web/icons/temp.png

echo "Icons generated successfully!"
