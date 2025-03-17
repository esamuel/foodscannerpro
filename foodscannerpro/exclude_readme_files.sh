#!/bin/bash

# This script excludes README.md files and problematic Swift files from the build to avoid conflicts
# Add this as a "Run Script" build phase in Xcode, before the "Copy Bundle Resources" phase

# Get the source root directory
SOURCE_ROOT="${SRCROOT}"

# Find all README.md files in the project
README_FILES=$(find "${SOURCE_ROOT}/foodscannerpro" -name "*.md")

# Find Swift files with hashbang lines
HASHBANG_SWIFT_FILES=$(grep -l "^#!/usr/bin/swift" "${SOURCE_ROOT}/foodscannerpro"/*.swift 2>/dev/null || true)

# Create a temporary directory for excluded files if it doesn't exist
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

# Process each Swift file with hashbang
for FILE in $HASHBANG_SWIFT_FILES; do
    # Get the filename
    FILENAME=$(basename "$FILE")
    
    # Create a symlink in the excluded directory
    ln -sf "$FILE" "${EXCLUDED_DIR}/${FILENAME}.excluded"
    
    echo "Excluded from build: $FILENAME (contains hashbang)"
done

exit 0 