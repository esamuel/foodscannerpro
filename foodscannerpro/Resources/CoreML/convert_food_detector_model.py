#!/usr/bin/env python3
"""
Food Detection Model Converter for Food Scanner Pro

This script downloads a pre-trained YOLOv5 model and converts it to Core ML format.
Requirements:
- torch
- torchvision
- coremltools
- ultralytics

Usage:
python convert_food_detector_model.py
"""

import os
import torch
import coremltools as ct

def main():
    print("Downloading YOLOv5 model from Ultralytics Hub...")
    # You can replace this with a custom-trained food detection model
    # For this example, we're using a pre-trained YOLOv5s model
    model = torch.hub.load('ultralytics/yolov5', 'yolov5s', pretrained=True)
    
    print("Model downloaded successfully.")
    
    # Set model to evaluation mode
    model.eval()
    
    # Export to ONNX format
    onnx_model_path = 'food_detector.onnx'
    print(f"Exporting model to ONNX format: {onnx_model_path}")
    
    # Example input shape (batch_size, channels, height, width)
    dummy_input = torch.zeros(1, 3, 640, 640)
    
    # Export the model
    torch.onnx.export(
        model,
        dummy_input,
        onnx_model_path,
        opset_version=12,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    
    print("Converting ONNX model to Core ML format...")
    # Convert ONNX model to Core ML
    mlmodel = ct.converters.onnx.convert(
        model=onnx_model_path,
        minimum_ios_deployment_target='14.0',
        predicted_feature_name='output'
    )
    
    # Set model metadata
    mlmodel.author = "Food Scanner Pro"
    mlmodel.license = "MIT"
    mlmodel.short_description = "Food detection model based on YOLOv5"
    mlmodel.version = "1.0"
    
    # Save the model
    output_path = "FoodDetector.mlmodel"
    print(f"Saving model to {output_path}...")
    mlmodel.save(output_path)
    
    # Clean up ONNX file
    if os.path.exists(onnx_model_path):
        os.remove(onnx_model_path)
        print(f"Removed temporary file: {onnx_model_path}")
    
    print("Conversion complete!")
    print(f"Model saved to: {os.path.abspath(output_path)}")
    print("Add this model to your Xcode project to enable enhanced food detection.")
    print("\nNote: This is a general object detection model. For best results,")
    print("train a custom model specifically on food datasets with bounding boxes.")

if __name__ == "__main__":
    main() 