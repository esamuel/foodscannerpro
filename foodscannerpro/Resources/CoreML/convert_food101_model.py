#!/usr/bin/env python3
"""
Food101 Model Converter for Food Scanner Pro

This script downloads a pre-trained Food101 model and converts it to Core ML format.
Requirements:
- torch
- torchvision
- coremltools

Usage:
python convert_food101_model.py
"""

import os
import torch
import coremltools as ct
from torchvision import transforms

def main():
    print("Downloading Food101 model from PyTorch Hub...")
    model = torch.hub.load('pytorch/vision:v0.10.0', 'food101', pretrained=True)
    model.eval()
    
    print("Model downloaded successfully.")
    
    # Get the class names
    try:
        # Try to get class names from the model
        class_names = model.classes
    except AttributeError:
        # If not available, use a placeholder list
        print("Class names not found in model, using placeholder names.")
        class_names = [f"food_{i}" for i in range(101)]
    
    # Create example input
    example_input = torch.rand(1, 3, 224, 224)
    
    print("Tracing model...")
    traced_model = torch.jit.trace(model, example_input)
    
    print("Converting to Core ML format...")
    mlmodel = ct.convert(
        traced_model,
        inputs=[ct.TensorType(name="input", shape=example_input.shape)],
        classifier_config=ct.ClassifierConfig(class_names)
    )
    
    # Set model metadata
    mlmodel.author = "Food Scanner Pro"
    mlmodel.license = "MIT"
    mlmodel.short_description = "Food classification model based on Food101 dataset"
    mlmodel.version = "1.0"
    
    # Save the model
    output_path = "FoodClassifier.mlmodel"
    print(f"Saving model to {output_path}...")
    mlmodel.save(output_path)
    
    print("Conversion complete!")
    print(f"Model saved to: {os.path.abspath(output_path)}")
    print("Add this model to your Xcode project to enable enhanced food recognition.")

if __name__ == "__main__":
    main() 