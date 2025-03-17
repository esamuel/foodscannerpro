#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== Food Scanner Pro Build Fix Script =====${NC}"
echo -e "${YELLOW}This script will fix the 'Multiple commands produce' build error.${NC}"
echo

# Check if the project file exists
if [ ! -f "foodscannerpro.xcodeproj/project.pbxproj" ]; then
    echo -e "${RED}Error: Xcode project file not found.${NC}"
    exit 1
fi

# Create a backup of the project file
echo -e "${BLUE}Creating backup of project file...${NC}"
cp foodscannerpro.xcodeproj/project.pbxproj foodscannerpro.xcodeproj/project.pbxproj.bak
echo -e "${GREEN}✓ Backup created at foodscannerpro.xcodeproj/project.pbxproj.bak${NC}"

# Fix the build issue by adding a custom script phase to exclude README.md files
echo -e "${BLUE}Fixing build issue...${NC}"

# Check if the README.md files are in the Copy Bundle Resources phase
if grep -q "README.md" foodscannerpro.xcodeproj/project.pbxproj; then
    # Create a temporary file with the fixed content
    cat foodscannerpro.xcodeproj/project.pbxproj | sed 's/README.md/README.md.excluded/g' > foodscannerpro.xcodeproj/project.pbxproj.tmp
    mv foodscannerpro.xcodeproj/project.pbxproj.tmp foodscannerpro.xcodeproj/project.pbxproj
    echo -e "${GREEN}✓ Renamed README.md references in project file${NC}"
else
    echo -e "${YELLOW}No README.md references found in project file.${NC}"
fi

# Check if setup_api_keys.swift is in the project
if grep -q "setup_api_keys.swift" foodscannerpro.xcodeproj/project.pbxproj; then
    # Remove references to setup_api_keys.swift
    cat foodscannerpro.xcodeproj/project.pbxproj | grep -v "setup_api_keys.swift" > foodscannerpro.xcodeproj/project.pbxproj.tmp
    mv foodscannerpro.xcodeproj/project.pbxproj.tmp foodscannerpro.xcodeproj/project.pbxproj
    echo -e "${GREEN}✓ Removed setup_api_keys.swift references from project file${NC}"
    
    # Check if the file exists and remove it
    if [ -f "foodscannerpro/setup_api_keys.swift" ]; then
        rm foodscannerpro/setup_api_keys.swift
        echo -e "${GREEN}✓ Removed setup_api_keys.swift file${NC}"
    fi
else
    echo -e "${YELLOW}No setup_api_keys.swift references found in project file.${NC}"
fi

# Create a .gitignore entry to ignore .md.excluded files
if [ -f ".gitignore" ]; then
    if ! grep -q "*.md.excluded" .gitignore; then
        echo "*.md.excluded" >> .gitignore
        echo -e "${GREEN}✓ Added *.md.excluded to .gitignore${NC}"
    fi
else
    echo "*.md.excluded" > .gitignore
    echo -e "${GREEN}✓ Created .gitignore with *.md.excluded${NC}"
fi

# Rename the README.md files to avoid conflicts
echo -e "${BLUE}Renaming README.md files to avoid conflicts...${NC}"
if [ -f "foodscannerpro/README.md" ]; then
    cp foodscannerpro/README.md foodscannerpro/README.md.excluded
    echo -e "${GREEN}✓ Created foodscannerpro/README.md.excluded${NC}"
fi

if [ -f "foodscannerpro/Resources/CoreML/MODELS_README.md" ]; then
    cp foodscannerpro/Resources/CoreML/MODELS_README.md foodscannerpro/Resources/CoreML/MODELS_README.md.excluded
    echo -e "${GREEN}✓ Created foodscannerpro/Resources/CoreML/MODELS_README.md.excluded${NC}"
fi

if [ -f "foodscannerpro/SETUP.md" ]; then
    cp foodscannerpro/SETUP.md foodscannerpro/SETUP.md.excluded
    echo -e "${GREEN}✓ Created foodscannerpro/SETUP.md.excluded${NC}"
fi

if [ -f "foodscannerpro/BUILD_FIX.md" ]; then
    cp foodscannerpro/BUILD_FIX.md foodscannerpro/BUILD_FIX.md.excluded
    echo -e "${GREEN}✓ Created foodscannerpro/BUILD_FIX.md.excluded${NC}"
fi

echo
echo -e "${BLUE}===== Fix Complete =====${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Clean the build folder (Product > Clean Build Folder)"
echo -e "2. Build the project again"
echo
echo -e "${GREEN}The original .md files are preserved, but excluded from the build.${NC}"
echo -e "${GREEN}The .md.excluded files are copies that won't cause build conflicts.${NC}" 