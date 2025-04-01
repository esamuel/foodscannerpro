import SwiftUI
import Combine

@MainActor
public class FoodAnalysisViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Published properties for UI updates
    @Published public private(set) var isAnalyzing = false
    @Published public private(set) var analysisResults: [FoodClassificationResult] = []
    @Published public private(set) var error: Error?
    
    /// Model names to be used for analysis
    private let modelNames: [String]
    
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
            // Preload all models in parallel
            await CoreMLManager.shared.preloadModels(modelNames)
            isInitialized = true
        } catch {
            self.error = error
        }
    }
    
    /// Analyzes a food image
    /// - Parameters:
    ///   - image: The image to analyze
    ///   - modelName: Optional specific model to use (uses first available if not specified)
    public func analyzeFood(image: UIImage, modelName: String? = nil) async {
        guard isInitialized else {
            error = CoreMLError.modelNotLoaded
            return
        }
        
        isAnalyzing = true
        error = nil
        
        do {
            let targetModel = modelName ?? modelNames.first
            guard let model = targetModel else {
                throw CoreMLError.modelNotFound
            }
            
            analysisResults = try await CoreMLManager.shared.classifyFood(
                image: image,
                modelName: model
            )
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
    
    // MARK: - Cleanup
    
    deinit {
        // Unload models when view model is deallocated
        // Note: We can't use async/await directly in deinit,
        // so we detach the task to handle cleanup
        Task.detached { [modelNames] in
            for modelName in modelNames {
                await CoreMLManager.shared.unloadModel(modelName)
            }
        }
    }
}

// MARK: - Helper Extensions

extension FoodClassificationResult {
    /// Returns true if the confidence is above a reasonable threshold
    public var isReliable: Bool {
        confidence > 0.7 // 70% confidence threshold
    }
    
    /// Formatted confidence percentage
    public var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }
} 