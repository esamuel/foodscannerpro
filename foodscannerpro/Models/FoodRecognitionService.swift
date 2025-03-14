import Foundation
import Vision
import CoreML
import UIKit

class FoodRecognitionService {
    // Singleton instance
    static let shared = FoodRecognitionService()
    
    // Models
    private var foodClassificationModel: VNCoreMLModel?
    private var foodDetectionModel: VNCoreMLModel?
    
    // Model URLs - these would be replaced with actual model file names
    private let classificationModelName = "FoodClassifier"
    private let detectionModelName = "FoodDetector"
    
    // Confidence thresholds
    private let minimumConfidence: Float = 0.3
    private let highConfidenceThreshold: Float = 0.7
    
    // Initialize the service
    private init() {
        loadModels()
    }
    
    // Load ML models
    private func loadModels() {
        // Try to load the custom food classification model if available
        if let modelURL = Bundle.main.url(forResource: classificationModelName, withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                foodClassificationModel = try VNCoreMLModel(for: model)
                print("Successfully loaded food classification model")
            } catch {
                print("Failed to load food classification model: \(error)")
            }
        } else {
            print("Food classification model not found in bundle, will use Vision framework default")
        }
        
        // Try to load the food detection model if available
        if let modelURL = Bundle.main.url(forResource: detectionModelName, withExtension: "mlmodelc") {
            do {
                let model = try MLModel(contentsOf: modelURL)
                foodDetectionModel = try VNCoreMLModel(for: model)
                print("Successfully loaded food detection model")
            } catch {
                print("Failed to load food detection model: \(error)")
            }
        }
    }
    
    // Recognize food in an image using multiple approaches
    func recognizeFood(in image: UIImage, completion: @escaping ([RecognitionResult]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        // Create a request handler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // If we have a custom food model, use it first
        if let foodModel = foodClassificationModel {
            let request = VNCoreMLRequest(model: foodModel) { request, error in
                if let error = error {
                    print("Custom model error: \(error)")
                    // Fall back to standard classification
                    self.performStandardClassification(on: cgImage, completion: completion)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    // Fall back to standard classification
                    self.performStandardClassification(on: cgImage, completion: completion)
                    return
                }
                
                // Process results from custom model
                let filteredResults = results
                    .filter { $0.confidence > self.minimumConfidence }
                    .prefix(10)
                    .map { RecognitionResult(name: $0.identifier, confidence: $0.confidence, boundingBox: .zero, source: .customModel) }
                
                if !filteredResults.isEmpty {
                    completion(Array(filteredResults))
                } else {
                    // Fall back to standard classification
                    self.performStandardClassification(on: cgImage, completion: completion)
                }
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                print("Failed to perform custom model request: \(error)")
                // Fall back to standard classification
                performStandardClassification(on: cgImage, completion: completion)
            }
        } else {
            // No custom model, use standard classification
            performStandardClassification(on: cgImage, completion: completion)
        }
    }
    
    // Perform standard Vision framework classification
    private func performStandardClassification(on cgImage: CGImage, completion: @escaping ([RecognitionResult]) -> Void) {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let classificationRequest = VNClassifyImageRequest { request, error in
            if let error = error {
                print("Standard classification error: \(error)")
                completion([])
                return
            }
            
            guard let observations = request.results as? [VNClassificationObservation] else {
                completion([])
                return
            }
            
            // Filter and map results
            let results = observations
                .filter { $0.confidence > self.minimumConfidence }
                .prefix(10)
                .map { RecognitionResult(name: $0.identifier, confidence: $0.confidence, boundingBox: .zero, source: .visionFramework) }
            
            completion(Array(results))
        }
        
        // Set revision to 2 for better accuracy
        classificationRequest.revision = VNClassifyImageRequestRevision2
        
        do {
            try requestHandler.perform([classificationRequest])
        } catch {
            print("Failed to perform standard classification: \(error)")
            completion([])
        }
    }
    
    // Detect multiple food items in a single image (if detection model is available)
    func detectFoodItems(in image: UIImage, completion: @escaping ([RecognitionResult]) -> Void) {
        guard let cgImage = image.cgImage, let detectionModel = foodDetectionModel else {
            // If no detection model, just return empty results
            completion([])
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        let request = VNCoreMLRequest(model: detectionModel) { request, error in
            if let error = error {
                print("Food detection error: \(error)")
                completion([])
                return
            }
            
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }
            
            // Process detection results
            let detectionResults = results.compactMap { observation -> RecognitionResult? in
                guard let topClassification = observation.labels.first,
                      topClassification.confidence > self.minimumConfidence else {
                    return nil
                }
                
                return RecognitionResult(
                    name: topClassification.identifier,
                    confidence: topClassification.confidence,
                    boundingBox: observation.boundingBox,
                    source: .objectDetection
                )
            }
            
            completion(detectionResults)
        }
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Failed to perform food detection: \(error)")
            completion([])
        }
    }
}

// Result from food recognition
struct RecognitionResult {
    let name: String
    let confidence: Float
    let boundingBox: CGRect
    let source: RecognitionSource
    
    enum RecognitionSource {
        case customModel
        case visionFramework
        case objectDetection
        case api
    }
} 