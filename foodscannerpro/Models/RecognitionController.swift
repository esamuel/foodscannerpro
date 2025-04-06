import Foundation
import UIKit
import SwiftUI
import Vision
import CoreML

/// Central controller for handling all food recognition tasks
@MainActor
class RecognitionController: ObservableObject {
    @Published private(set) var isProcessing = false
    @Published private(set) var error: RecognitionError?
    @Published private(set) var recognitionResults: [FoodRecognitionResult] = []
    
    private let foodRecognitionService = FoodRecognitionService.shared
    
    // MARK: - Public Methods
    
    /// Analyze food in an image
    func analyzeFood(image: UIImage) async {
        isProcessing = true
        error = nil
        recognitionResults = []
        
        do {
            recognitionResults = try await performQuickScan(image: image)
        } catch let recognitionError as RecognitionError {
            error = recognitionError
        } catch {
            self.error = .networkError
        }
        
        isProcessing = false
    }
    
    // MARK: - Private Methods
    
    private func performQuickScan(image: UIImage) async throws -> [FoodRecognitionResult] {
        // Implement your CoreML-based quick scan logic here
        return []
    }
    
    private func processRecognizedFood(_ food: String, confidence: Float) -> RecognizedFood {
        let nutritionInfo = FoodNutritionInfo(
            foodName: food,
            calories: 100,
            protein: 5,
            carbs: 15,
            fat: 3,
            fiber: nil,
            sugar: nil,
            sodium: nil,
            cholesterol: nil,
            potassium: nil,
            calcium: nil,
            iron: nil,
            vitaminA: nil,
            vitaminC: nil,
            servingSize: 100,
            servingUnit: "g",
            source: .estimated
        )
        
        // Convert FoodNutritionInfo to FoodNutrition
        let foodNutrition = FoodNutrition(
            calories: nutritionInfo.calories,
            protein: nutritionInfo.protein,
            carbs: nutritionInfo.carbs,
            fats: nutritionInfo.fat  // Note: using fat from FoodNutritionInfo for fats in FoodNutrition
        )
        
        // Create AdditionalNutrition from the optional values
        let additionalNutrition = AdditionalNutrition(
            fiber: nutritionInfo.fiber,
            sugar: nutritionInfo.sugar,
            sodium: nutritionInfo.sodium,
            cholesterol: nutritionInfo.cholesterol,
            potassium: nutritionInfo.potassium,
            calcium: nutritionInfo.calcium,
            iron: nutritionInfo.iron,
            vitaminA: nutritionInfo.vitaminA,
            vitaminC: nutritionInfo.vitaminC,
            servingSize: nutritionInfo.servingSize,
            servingUnit: nutritionInfo.servingUnit
        )
        
        return RecognizedFood(
            name: food,
            confidence: confidence,
            boundingBox: .zero,
            estimatedNutrition: foodNutrition,
            additionalNutrition: additionalNutrition,
            nutritionSource: nutritionInfo.source,
            dietaryWarnings: [],
            isRecommended: false
        )
    }
}

// MARK: - Supporting Types

struct NutritionInfo {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let fiber: Double?
    let sugar: Double?
    let vitamins: [String: Double]
    let minerals: [String: Double]
}

enum RecognitionError: Error {
    case networkError
    case lowConfidence(Double)
    case noResults
    case invalidImage
    case apiLimitReached
    case serviceUnavailable(String)
}

struct FoodRecognitionResult: Identifiable {
    let id: UUID
    let name: String
    let confidence: Float
    let nutrition: NutritionInfo?
    let healthConsiderations: [String]
    let allergens: [String]
    let portionSize: String?
    let preparationMethod: String?
    let isFresh: Bool?
    let isDiabetesFriendly: Bool?
    let glycemicIndex: Int?
} 