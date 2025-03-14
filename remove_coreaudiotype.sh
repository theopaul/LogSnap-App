#!/bin/bash

# Path to the project.pbxproj file
PROJECT_FILE="LogSnap.xcodeproj/project.pbxproj"

# Make a backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.audio.bak"

# Look for and remove any direct references to CoreAudioTypes
if grep -q "CoreAudioTypes" "$PROJECT_FILE"; then
  echo "Found CoreAudioTypes references, removing them..."
  
  # Remove lines containing CoreAudioTypes
  sed -i '' '/CoreAudioTypes/d' "$PROJECT_FILE"
  
  echo "Removed CoreAudioTypes references from $PROJECT_FILE"
else
  echo "No direct CoreAudioTypes references found in $PROJECT_FILE"
fi

# Additionally, let's look for any framework references that might be problematic
echo "Checking for problematic framework references..."
grep -n "framework = " "$PROJECT_FILE" | grep -v "Foundation\|UIKit\|SwiftUI\|CoreData"

echo "Script completed." 