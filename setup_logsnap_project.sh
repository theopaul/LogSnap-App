#!/bin/bash

echo "LogSnap Xcode Project Setup"
echo "==========================="
echo ""
echo "This script will guide you through creating a new Xcode project for LogSnap."
echo ""
echo "Instructions:"
echo "1. Open Xcode"
echo "2. Select 'Create a new Xcode project'"
echo "3. Choose 'App' under iOS templates"
echo "4. Enter the following details:"
echo "   - Product Name: LogSnap"
echo "   - Organization Identifier: com.yourname.logsnap (or your preferred identifier)"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - ✓ Use Core Data"
echo "   - ✓ Include Tests"
echo "5. Choose the parent directory of your current LogSnap folder"
echo "6. Click 'Create'"
echo ""
echo "After creating the project:"
echo "7. In Finder, copy the contents of your current LogSnap folder into the newly created Xcode project folder"
echo "8. In Xcode, right-click on the LogSnap folder in the Project Navigator and select 'Add Files to LogSnap...'"
echo "9. Navigate to each folder and add the files we've created, maintaining the folder structure"
echo ""

# Check if we can automatically find Xcode
XCODE_PATH=$(mdfind kMDItemCFBundleIdentifier=com.apple.dt.Xcode | head -n 1)

if [ -n "$XCODE_PATH" ]; then
    echo "Xcode found at: $XCODE_PATH"
    echo "Would you like to open Xcode now? (y/n)"
    read -r open_xcode
    if [ "$open_xcode" = "y" ] || [ "$open_xcode" = "Y" ]; then
        open "$XCODE_PATH"
    fi
else
    echo "Xcode not found automatically. Please open Xcode manually to continue."
fi

echo ""
echo "Once complete, you should have a working Xcode project with all the LogSnap files."
echo "You can build and run the app by clicking the Play button in Xcode." 