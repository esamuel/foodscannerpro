# Food Scanner Pro

A comprehensive iOS app for food recognition, nutritional analysis, and health recommendations.

## Food Recognition Improvements

The app now supports multiple food recognition methods for improved accuracy:

1. **Standard Recognition**: Uses Apple's Vision framework for general image classification.
2. **Enhanced Recognition**: Uses a specialized food recognition model for improved accuracy.
3. **API Recognition**: Uses external food recognition APIs for high accuracy.
4. **Combined Recognition**: Combines multiple recognition methods for the highest accuracy.

## Adding Custom ML Models

To further improve food recognition accuracy, you can add custom ML models to the app:

### Food Classification Model

1. Download a pre-trained food classification model (e.g., from [Food101](https://github.com/pytorch/hub/blob/master/pytorch_vision_food101.md) or [similar sources](https://github.com/topics/food-classification))
2. Convert the model to Core ML format using [coremltools](https://coremltools.readme.io/docs)
3. Add the `.mlmodel` file to the project
4. Rename it to `FoodClassifier.mlmodel`

Example conversion code:

```python
import coremltools as ct

# Load your trained model (example with PyTorch)
import torch
model = torch.hub.load('pytorch/vision:v0.10.0', 'food101')
model.eval()

# Trace the model with an example input
example_input = torch.rand(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)

# Convert to Core ML
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.TensorType(name="input", shape=example_input.shape)],
    classifier_config=ct.ClassifierConfig(["class1", "class2", ...])  # Replace with your food classes
)

# Save the model
mlmodel.save("FoodClassifier.mlmodel")
```

### Food Detection Model

For detecting multiple food items in a single image:

1. Download a pre-trained object detection model fine-tuned for food (e.g., YOLOv5, SSD, or Faster R-CNN)
2. Convert the model to Core ML format
3. Add the `.mlmodel` file to the project
4. Rename it to `FoodDetector.mlmodel`

## API Integration

The app supports integration with external food recognition APIs:

1. **Clarifai Food Model**: Get an API key from [Clarifai](https://www.clarifai.com/)
2. **LogMeal API**: Get an API key from [LogMeal](https://logmeal.es/api)

Add your API keys to the `FoodRecognitionAPIService.swift` file:

```swift
private let clarifaiAPIKey = "YOUR_CLARIFAI_API_KEY"
private let logMealAPIKey = "YOUR_LOGMEAL_API_KEY"
```

## Nutrition Data

The app uses the USDA Food Data Central API for nutrition information:

1. Get an API key from [USDA Food Data Central](https://fdc.nal.usda.gov/api-key-signup.html)
2. Add your API key to the `NutritionService.swift` file:

```swift
private let apiKey = "YOUR_USDA_API_KEY"
```

## Feedback System

The app includes a feedback system that allows users to correct misidentified foods. This data is used to improve future recognition accuracy through a learning mechanism.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 