#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== Food Scanner Pro Setup Script =====${NC}"
echo -e "${YELLOW}This script will help you set up the Food Scanner Pro app.${NC}"
echo

# Check if Python is installed
echo -e "${BLUE}Checking for Python...${NC}"
if command -v python3 &>/dev/null; then
    echo -e "${GREEN}✓ Python is installed${NC}"
    PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
    echo -e "${GREEN}✓ Python is installed${NC}"
    PYTHON_CMD="python"
else
    echo -e "${RED}✗ Python is not installed. Please install Python 3.${NC}"
    echo -e "${YELLOW}Visit https://www.python.org/downloads/ to download and install Python.${NC}"
    exit 1
fi

# Check for pip
echo -e "${BLUE}Checking for pip...${NC}"
if command -v pip3 &>/dev/null; then
    echo -e "${GREEN}✓ pip is installed${NC}"
    PIP_CMD="pip3"
elif command -v pip &>/dev/null; then
    echo -e "${GREEN}✓ pip is installed${NC}"
    PIP_CMD="pip"
else
    echo -e "${RED}✗ pip is not installed. Please install pip.${NC}"
    exit 1
fi

# Create Resources directory if it doesn't exist
echo -e "${BLUE}Setting up directories...${NC}"
mkdir -p Resources/CoreML
echo -e "${GREEN}✓ Created Resources/CoreML directory${NC}"
echo -e "${YELLOW}See Resources/CoreML/MODELS_README.md for more information about the ML models${NC}"

# Ask if user wants to install Python dependencies
echo
echo -e "${BLUE}Do you want to install Python dependencies for ML model conversion?${NC}"
echo -e "${YELLOW}This will install torch, torchvision, coremltools, and ultralytics.${NC}"
read -p "Install dependencies? (y/n): " install_deps

if [[ $install_deps == "y" || $install_deps == "Y" ]]; then
    echo -e "${BLUE}Installing Python dependencies...${NC}"
    $PIP_CMD install torch torchvision coremltools ultralytics
    echo -e "${GREEN}✓ Dependencies installed${NC}"
fi

# Ask if user wants to convert ML models
echo
echo -e "${BLUE}Do you want to convert the ML models now?${NC}"
echo -e "${YELLOW}This may take some time and requires an internet connection.${NC}"
read -p "Convert models? (y/n): " convert_models

if [[ $convert_models == "y" || $convert_models == "Y" ]]; then
    echo -e "${BLUE}Converting Food Classifier model...${NC}"
    cd Resources/CoreML
    $PYTHON_CMD convert_food101_model.py
    
    echo -e "${BLUE}Converting Food Detector model...${NC}"
    $PYTHON_CMD convert_food_detector_model.py
    
    cd ../..
    echo -e "${GREEN}✓ Models converted${NC}"
    echo -e "${YELLOW}Remember to add the .mlmodel files to your Xcode project.${NC}"
fi

# API Keys information
echo
echo -e "${BLUE}API Keys Setup${NC}"
echo -e "${YELLOW}You'll need to set up API keys for the following services:${NC}"
echo -e "1. Clarifai: https://www.clarifai.com/"
echo -e "2. LogMeal: https://logmeal.es/api"
echo -e "3. USDA Food Data Central: https://fdc.nal.usda.gov/api-key-signup.html"
echo
echo -e "${YELLOW}You can set up these API keys in the app by:${NC}"
echo -e "1. Opening the app"
echo -e "2. Going to the Profile tab"
echo -e "3. Tapping on 'Setup API Keys'"
echo

echo -e "${BLUE}===== Setup Complete =====${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Open the Xcode project"
echo -e "2. If you converted the ML models, add them to your project"
echo -e "3. Build and run the app"
echo -e "4. Set up your API keys in the Profile tab"
echo
echo -e "${GREEN}Thank you for using Food Scanner Pro!${NC}" 