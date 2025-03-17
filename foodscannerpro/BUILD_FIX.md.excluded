# Fixing Build Errors in Food Scanner Pro

This guide addresses common build errors you might encounter in the Food Scanner Pro project.

## Error 1: "Multiple commands produce" Build Error

If you encounter the following build error:

```
Multiple commands produce '/Users/.../Build/Products/Debug-iphoneos/foodscannerpro.app/README.md'
```

This happens because multiple README.md files are being copied to the same location in the app bundle. Here are several ways to fix this issue:

### Option 1: Run the Fix Script (Recommended)

We've provided a script that automatically fixes the issue:

1. Open Terminal
2. Navigate to the project directory
3. Run the fix script:
   ```
   ./foodscannerpro/fix_build.sh
   ```
4. Clean the build folder in Xcode (Product > Clean Build Folder)
5. Build the project again

### Option 2: Add a Build Phase Script in Xcode

1. Open the project in Xcode
2. Select the foodscannerpro target
3. Go to the "Build Phases" tab
4. Click the "+" button and select "New Run Script Phase"
5. Drag the new phase to be before the "Copy Bundle Resources" phase
6. Paste the following script:
   ```bash
   # Find all README.md files in the project
   README_FILES=$(find "${SRCROOT}/foodscannerpro" -name "*.md")
   
   # Create a temporary directory for excluded files
   EXCLUDED_DIR="${DERIVED_FILE_DIR}/ExcludedFiles"
   mkdir -p "${EXCLUDED_DIR}"
   
   # Process each README file
   for FILE in $README_FILES; do
       # Get the filename
       FILENAME=$(basename "$FILE")
       
       # Create a symlink in the excluded directory
       ln -sf "$FILE" "${EXCLUDED_DIR}/${FILENAME}.excluded"
       
       echo "Excluded from build: $FILENAME"
   done
   ```
7. Clean the build folder and build again

### Option 3: Manually Exclude Files from the Build

1. Open the project in Xcode
2. In the Project Navigator, select the README.md files
3. In the File Inspector (right panel), uncheck "Target Membership" for the foodscannerpro target
4. Clean the build folder and build again

## Error 2: "Hashbang line is allowed only in the main file"

If you encounter the following build error:

```
/Users/.../foodscannerpro/setup_api_keys.swift:1:1 Hashbang line is allowed only in the main file
/Users/.../foodscannerpro/setup_api_keys.swift:95:1 Expressions are not allowed at the top level
```

This happens because the `setup_api_keys.swift` file contains a hashbang line (`#!/usr/bin/swift`) and top-level expressions, which are only allowed in the main file of a Swift executable, not in a file that's part of an iOS app target.

### Option 1: Run the Fix Script (Recommended)

The same fix script mentioned above will also handle this issue:

1. Open Terminal
2. Navigate to the project directory
3. Run the fix script:
   ```
   ./foodscannerpro/fix_build.sh
   ```
4. Clean the build folder in Xcode (Product > Clean Build Folder)
5. Build the project again

### Option 2: Use the APIKeyManager Class

We've replaced the `setup_api_keys.swift` script with a proper Swift class called `APIKeyManager` that can be used within the app. The API key setup functionality is now available in the Profile tab of the app.

### Option 3: Manually Remove the File

1. Open the project in Xcode
2. In the Project Navigator, find and select the `setup_api_keys.swift` file
3. Press Delete and choose "Remove Reference" (or "Move to Trash" if you want to delete the file)
4. Clean the build folder and build again

## Why These Issues Happen

- **README.md Conflict**: This issue occurs because Xcode tries to copy multiple files with the same name (README.md) to the same location in the app bundle.
- **Hashbang Line Error**: This issue occurs because Swift files in an iOS app cannot contain hashbang lines or top-level expressions, which are only allowed in Swift scripts or the main file of a Swift executable. 