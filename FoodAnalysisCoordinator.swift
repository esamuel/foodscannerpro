import SwiftUI

public class FoodAnalysisCoordinator {
    public static let shared = FoodAnalysisCoordinator()
    
    private init() {}
    
    // Model names available in the app
    private let availableModels = ["FoodClassifier"]
    
    // View model instance
    private lazy var viewModel: FoodAnalysisViewModel = {
        FoodAnalysisViewModel(modelNames: availableModels)
    }()
    
    /// Returns true if the Core ML model is available
    public var isModelAvailable: Bool {
        Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodel") != nil
    }
    
    /// Initializes the food analysis system
    public func initialize() async {
        await viewModel.initialize()
    }
    
    /// Creates a food analysis view
    public func createFoodAnalysisView() -> some View {
        FoodAnalysisTestView()
    }
} 