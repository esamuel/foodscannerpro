import CoreML
import Vision
import UIKit

/// Manages Core ML model loading and inference operations
public actor CoreMLManager {
    // MARK: - Properties
    
    /// Shared instance for the Core ML manager
    public static let shared = CoreMLManager()
    
    /// Cached model configurations
    private var modelCache: [String: Any] = [:]
    
    /// Background queue for model loading
    private let modelLoadingQueue = DispatchQueue(label: "com.foodscannerpro.modelLoading",
                                                qos: .userInitiated)
    
    // MARK: - Public Methods
    
    /// Preloads a Core ML model in the background
    /// - Parameter modelName: Name of the model file without extension
    public func preloadModel(_ modelName: String) async throws {
        // Check if model is already cached
        if modelCache[modelName] != nil {
            return
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            modelLoadingQueue.async {
                do {
                    // Compile model if needed
                    let compiledModelURL = try self.getCompiledModelURL(for: modelName)
                    
                    // Load model configuration
                    let config = MLModelConfiguration()
                    config.computeUnits = .all // Use all available compute units
                    
                    // Create model instance
                    let model = try MLModel(contentsOf: compiledModelURL, configuration: config)
                    
                    // Cache the model
                    self.modelCache[modelName] = model
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Performs food classification on an image
    /// - Parameters:
    ///   - image: The image to classify
    ///   - modelName: Name of the model to use
    /// - Returns: Array of classification results
    public func classifyFood(image: UIImage, modelName: String) async throws -> [FoodClassificationResult] {
        guard let model = modelCache[modelName] as? MLModel else {
            throw CoreMLError.modelNotLoaded
        }
        
        guard let cgImage = image.cgImage else {
            throw CoreMLError.invalidImage
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        return try await withCheckedThrowingContinuation { continuation in
            // Create classification request
            let request = VNCoreMLRequest(model: try! VNCoreMLModel(for: model)) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: CoreMLError.invalidResults)
                    return
                }
                
                let classifications = results.map { result in
                    FoodClassificationResult(
                        label: result.identifier,
                        confidence: Double(result.confidence)
                    )
                }
                
                continuation.resume(returning: classifications)
            }
            
            // Optimize for speed over accuracy if needed
            request.usesCPUOnly = false
            
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
    }
    
    // MARK: - Private Methods
    
    private func getCompiledModelURL(for modelName: String) throws -> URL {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodel") else {
            throw CoreMLError.modelNotFound
        }
        
        let compiledModelName = modelName + ".mlmodelc"
        let compiledModelURL = try MLModel.compileModel(at: modelURL)
        
        return compiledModelURL
    }
}

// MARK: - Types

public struct FoodClassificationResult: Identifiable {
    public let id = UUID()
    public let label: String
    public let confidence: Double
}

// MARK: - Errors

public enum CoreMLError: Error {
    case modelNotFound
    case modelNotLoaded
    case invalidImage
    case invalidResults
    case compilationFailed
}

// MARK: - Convenience Extensions

public extension CoreMLManager {
    /// Preloads multiple models in parallel
    /// - Parameter modelNames: Array of model names to preload
    func preloadModels(_ modelNames: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for modelName in modelNames {
                group.addTask {
                    try? await self.preloadModel(modelName)
                }
            }
        }
    }
} 