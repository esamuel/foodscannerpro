# Food Scanner Pro Setup Guide

This guide will help you set up the missing components required for the Food Scanner Pro app to function properly.

## 1. API Keys

The app requires several API keys to access external services for food recognition and nutrition data:

### Setting Up API Keys

You can set up API keys directly in the app:

1. Open the app
2. Go to the Profile tab
3. Tap on "Setup API Keys"
4. Enter your API keys for each service

### Required API Keys

#### Clarifai API Key

1. Go to [Clarifai](https://www.clarifai.com/) and create an account
2. Create a new application
3. Navigate to the API Keys section and create a new API key
4. Copy the API key and enter it in the app's API Key Setup screen

#### LogMeal API Key

1. Go to [LogMeal](https://logmeal.es/api) and create an account
2. Subscribe to their API service
3. Copy the API key and enter it in the app's API Key Setup screen

#### USDA Food Data Central API Key

1. Go to [USDA Food Data Central API Key Signup](https://fdc.nal.usda.gov/api-key-signup.html)
2. Fill out the form to request an API key
3. Check your email for the API key
4. Copy the API key and enter it in the app's API Key Setup screen

## 2. Core ML Models

The app uses two Core ML models for food recognition. For more detailed information, see `Resources/CoreML/MODELS_README.md`.

### FoodClassifier.mlmodel

This model is used for general food classification. To create it:

1. Navigate to `Resources/CoreML` directory
2. Install the required Python packages:
   ```
   pip install torch torchvision coremltools
   ```
3. Run the conversion script:
   ```
   python convert_food101_model.py
   ```
4. Add the generated `FoodClassifier.mlmodel` to your Xcode project:
   - Drag and drop the file into the Xcode project navigator
   - Make sure "Copy items if needed" is checked
   - Add to the main app target

### FoodDetector.mlmodel

This model is used for detecting multiple food items in a single image. To create it:

1. Navigate to `Resources/CoreML` directory
2. Install the required Python packages:
   ```
   pip install torch torchvision coremltools ultralytics
   ```
3. Run the conversion script:
   ```
   python convert_food_detector_model.py
   ```
4. Add the generated `FoodDetector.mlmodel` to your Xcode project:
   - Drag and drop the file into the Xcode project navigator
   - Make sure "Copy items if needed" is checked
   - Add to the main app target

## 3. Automated Setup

For convenience, you can use the provided setup script to automate parts of the setup process:

```bash
./setup.sh
```

This script will:
1. Check if Python and pip are installed
2. Create the necessary directories
3. Help you install the required Python dependencies
4. Convert the ML models if you choose to do so
5. Provide instructions for setting up API keys

## 4. Testing the Setup

After adding the API keys and ML models:

1. Build and run the app
2. Test the food recognition feature by scanning different food items
3. Verify that the app can retrieve nutrition information
4. Check that the history and analytics features are working properly

## 5. Troubleshooting

If you encounter issues:

- **API Key Issues**: Double-check that the API keys are correctly entered and that you have an active subscription if required
- **ML Model Issues**: Ensure the models are properly added to the Xcode project and that they're included in the app bundle
- **Recognition Issues**: The app will fall back to the Vision framework if the custom models are not available
- **Build Issues**: If you encounter build errors related to README.md files, see the BUILD_FIX.md file for solutions

## 6. Next Steps

Once the basic setup is complete, consider:

- Fine-tuning the ML models on your own food dataset for better accuracy
- Implementing a feedback mechanism to improve recognition over time
- Adding support for more food types and cuisines 