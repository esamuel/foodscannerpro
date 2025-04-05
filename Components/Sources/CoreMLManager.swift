import Foundation
import CoreML
import Vision
import SwiftUI

/// Manages Core ML model loading and inference operations
public actor CoreMLManager {
    // MARK: - Properties
    
    /// Shared instance for the Core ML manager
    public static let shared = CoreMLManager()
    
    /// Cached model configurations
    private var modelCache: [String: VNCoreMLModel] = [:]
    
    private var compiledModelURLs: [String: URL] = [:]
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Preloads a Core ML model in the background
    /// - Parameter modelName: Name of the model file without extension
    public func preloadModel(_ modelName: String) async throws {
        // Check if model is already cached
        if modelCache[modelName] != nil {
            return
        }
        
        // Get compiled model URL
        let compiledModelURL = try await getCompiledModelURL(for: modelName)
        
        // Load model configuration
        let config = MLModelConfiguration()
        config.computeUnits = .all // Use all available compute units
        
        // Create model instance
        let model = try MLModel(contentsOf: compiledModelURL, configuration: config)
        
        // Cache the model
        modelCache[modelName] = try VNCoreMLModel(for: model)
    }
    
    /// Performs food classification on an image
    /// - Parameters:
    ///   - image: The image to classify
    ///   - modelName: Name of the model to use
    /// - Returns: Array of classification results
    public func classifyFood(image: UIImage, modelName: String) async throws -> [FoodClassificationResult] {
        let model = try await loadModel(modelName)
        
        guard let cgImage = image.cgImage else {
            throw FoodAnalysisError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        var results: [VNClassificationObservation] = []
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: FoodAnalysisError.classificationFailed(error))
                    return
                }
                
                if let classifications = request.results as? [VNClassificationObservation] {
                    results = classifications
                    let foodResults = classifications.map { observation in
                        FoodClassificationResult(
                            label: observation.identifier,
                            confidence: observation.confidence
                        )
                    }
                    continuation.resume(returning: foodResults)
                } else {
                    continuation.resume(returning: [])
                }
            }
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// Unloads a model from memory
    /// - Parameter modelName: Name of the model to unload
    public func unloadModel(_ modelName: String) {
        modelCache.removeValue(forKey: modelName)
        compiledModelURLs.removeValue(forKey: modelName)
    }
    
    // MARK: - Private Methods
    
    private func getCompiledModelURL(for modelName: String) async throws -> URL {
        if let cachedURL = compiledModelURLs[modelName] {
            return cachedURL
        }
        
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
            throw FoodAnalysisError.modelNotFound(modelName)
        }
        
        compiledModelURLs[modelName] = modelURL
        return modelURL
    }
    
    public func loadModel(_ modelName: String) async throws -> VNCoreMLModel {
        if let cachedModel = modelCache[modelName] {
            return cachedModel
        }
        
        let modelURL = try await getCompiledModelURL(for: modelName)
        let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
        modelCache[modelName] = model
        return model
    }
    
    public func preloadModels(_ modelNames: [String]) async throws {
        for modelName in modelNames {
            _ = try await loadModel(modelName)
        }
    }
} 