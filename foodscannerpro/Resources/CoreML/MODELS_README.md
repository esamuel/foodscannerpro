# Core ML Models for Food Scanner Pro

This directory should contain the following Core ML models:

## 1. FoodClassifier.mlmodel

A classification model for identifying food items in images. You can create this model by:

1. Using a pre-trained model like Food101 and converting it to Core ML format
2. Fine-tuning a model on your own food dataset
3. Using Create ML to train a custom food classifier

### Example conversion code (Python with coremltools):

```python
import coremltools as ct
import torch

# Load pre-trained model (example with PyTorch)
model = torch.hub.load('pytorch/vision:v0.10.0', 'food101')
model.eval()

# Trace the model with example input
example_input = torch.rand(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)

# Convert to Core ML
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.TensorType(name="input", shape=example_input.shape)],
    classifier_config=ct.ClassifierConfig(["class1", "class2", ...])  # Replace with food classes
)

# Save the model
mlmodel.save("FoodClassifier.mlmodel")
```

## 2. FoodDetector.mlmodel

An object detection model for identifying multiple food items in a single image. You can create this model by:

1. Using a pre-trained object detection model (YOLOv5, SSD, etc.)
2. Fine-tuning it on a food dataset with bounding box annotations
3. Converting it to Core ML format

### Example conversion for YOLOv5 (Python):

```python
import torch
import coremltools as ct

# Load YOLOv5 model
model = torch.hub.load('ultralytics/yolov5', 'custom', path='path/to/food_yolov5.pt')

# Export to ONNX format
onnx_model_path = 'food_detector.onnx'
torch.onnx.export(model, torch.zeros(1, 3, 640, 640), onnx_model_path)

# Convert ONNX to Core ML
mlmodel = ct.converters.onnx.convert(
    model=onnx_model_path,
    minimum_ios_deployment_target='14.0'
)

# Save the model
mlmodel.save("FoodDetector.mlmodel")
```

## Important Notes

1. These models should be added to the Xcode project and will be bundled with the app
2. The app is designed to fall back to Vision framework if these models are not available
3. For optimal performance, consider quantizing the models to reduce size
4. Test the models with a variety of food images to ensure accuracy 