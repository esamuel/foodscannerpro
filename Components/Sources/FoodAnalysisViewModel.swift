import SwiftUI
import Combine
import Vision
import CoreML

@MainActor
public class FoodAnalysisViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Published properties for UI updates
    @Published public private(set) var isAnalyzing = false
    @Published public private(set) var analysisResults: [FoodClassificationResult] = []
    @Published public private(set) var error: Error?
    
    /// Model names to be used for analysis
    private let modelNames: [String]
    private var models: [VNCoreMLModel] = []
    
    /// Initialization status
    private var isInitialized = false
    
    // MARK: - Initialization
    
    public init(modelNames: [String]) {
        self.modelNames = modelNames
    }
    
    // MARK: - Public Methods
    
    /// Initializes the food analysis system
    public func initialize() async {
        guard !isInitialized else { return }
        
        do {
            for modelName in modelNames {
                guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                    throw FoodAnalysisError.modelNotFound(modelName)
                }
                let model = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
                models.append(model)
            }
            isInitialized = true
        } catch {
            self.error = error
        }
    }
    
    /// Analyzes a food image
    /// - Parameters:
    ///   - image: The image to analyze
    public func analyzeFood(image: UIImage) async {
        guard isInitialized else {
            error = FoodAnalysisError.modelsNotInitialized
            return
        }
        
        guard !models.isEmpty else {
            error = FoodAnalysisError.modelsNotInitialized
            return
        }
        
        isAnalyzing = true
        error = nil
        
        do {
            guard let cgImage = image.cgImage else {
                throw FoodAnalysisError.invalidImage
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage)
            var results: [VNClassificationObservation] = []
            
            for model in models {
                let request = VNCoreMLRequest(model: model) { request, error in
                    if let error = error {
                        self.error = FoodAnalysisError.classificationFailed(error)
                        return
                    }
                    if let classifications = request.results as? [VNClassificationObservation] {
                        results.append(contentsOf: classifications)
                    }
                }
                try requestHandler.perform([request])
            }
            
            // Process results
            self.analysisResults = results.map { observation in
                FoodClassificationResult(
                    label: observation.identifier,
                    confidence: observation.confidence
                )
            }
        } catch {
            self.error = error
            analysisResults = []
        }
        
        isAnalyzing = false
    }
    
    /// Clears current analysis results
    public func clearResults() {
        analysisResults = []
        error = nil
    }
} 