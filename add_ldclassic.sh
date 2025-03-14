#!/bin/bash

# Path to the project.pbxproj file
PROJECT_FILE="LogSnap.xcodeproj/project.pbxproj"

# Make a backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.bak"

# Find all build configuration blocks
CONFIGS=$(grep -n "buildSettings = {" "$PROJECT_FILE" | cut -d: -f1)

# Add OTHER_LDFLAGS = "-ld_classic"; to each build configuration block
for LINE in $CONFIGS; do
  # Check if OTHER_LDFLAGS already exists
  NEXT_LINE=$((LINE + 1))
  if ! grep -A 10 -B 0 "^$LINE:" "$PROJECT_FILE" | grep -q "OTHER_LDFLAGS"; then
    sed -i '' "${NEXT_LINE}i\\
				OTHER_LDFLAGS = \"-ld_classic\";" "$PROJECT_FILE"
  fi
done

echo "Added -ld_classic to Other Linker Flags in $PROJECT_FILE" 