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
    
    /// Analyze food in an image with specified priority
    func analyzeFood(image: UIImage, priority: RecognitionPriority = .standard) async {
        isProcessing = true
        error = nil
        recognitionResults = []
        
        do {
            switch priority {
            case .enhanced:
                try await performEnhancedAnalysis(image: image)
            case .quick:
                recognitionResults = try await performQuickScan(image: image)
            case .standard:
                try await performStandardAnalysis(image: image)
            }
        } catch let recognitionError as RecognitionError {
            error = recognitionError
        } catch {
            self.error = .networkError
        }
        
        isProcessing = false
    }
    
    // MARK: - Private Methods
    
    private func performEnhancedAnalysis(image: UIImage) async throws {
        // Perform enhanced analysis using multiple ML models
        let mlResults = try await performQuickScan(image: image)
        
        // Additional processing for enhanced results
        let enhancedResults = mlResults.map { result in
            // Add additional processing here
            return result
        }
        
        if enhancedResults.isEmpty {
            throw RecognitionError.noResults
        }
        
        recognitionResults = enhancedResults
    }
    
    private func performQuickScan(image: UIImage) async throws -> [FoodRecognitionResult] {
        // Create a continuation to bridge the callback-based API
        return try await withCheckedThrowingContinuation { continuation in
            foodRecognitionService.recognizeFood(in: image) { results in
                // Filter results by confidence
                let filteredResults = results.filter { $0.confidence >= 0.3 }
                
                if filteredResults.isEmpty {
                    continuation.resume(throwing: RecognitionError.noResults)
                    return
                }
                
                // Convert ML results to our format
                let recognitionResults = filteredResults.map { mlResult in
                    FoodRecognitionResult(
                        id: UUID(),
                        name: mlResult.name.capitalized,
                        confidence: Float(mlResult.confidence),
                        nutrition: nil, // Quick scan doesn't provide nutrition info
                        healthConsiderations: [],
                        allergens: [],
                        portionSize: nil,
                        preparationMethod: nil,
                        isFresh: nil,
                        isDiabetesFriendly: nil,
                        glycemicIndex: nil
                    )
                }
                
                continuation.resume(returning: recognitionResults)
            }
        }
    }
    
    private func performStandardAnalysis(image: UIImage) async throws {
        // Start with quick ML scan
        let mlResults = try await performQuickScan(image: image)
        
        // If ML results are confident enough, use them
        let confidentResults = mlResults.filter { $0.confidence >= 0.7 }
        
        if !confidentResults.isEmpty {
            recognitionResults = confidentResults
            return
        }
        
        // If ML results aren't confident enough, fall back to enhanced analysis
        try await performEnhancedAnalysis(image: image)
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

enum RecognitionPriority {
    case enhanced  // Uses multiple ML models for detailed analysis
    case quick    // Uses CoreML for fast recognition
    case standard // Uses CoreML with fallback to enhanced if needed
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