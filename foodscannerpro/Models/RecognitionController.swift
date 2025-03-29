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
    
    private let chatGPTService = ChatGPTScanService()
    private let foodRecognitionService = FoodRecognitionService.shared
    
    // MARK: - Public Methods
    
    /// Analyze food in an image with specified priority
    func analyzeFood(image: UIImage, priority: RecognitionPriority = .hybrid) async {
        isProcessing = true
        error = nil
        recognitionResults = []
        
        do {
            switch priority {
            case .highAccuracy:
                try await performHighAccuracyAnalysis(image: image)
            case .quickScan:
                recognitionResults = try await performQuickScan(image: image)
            case .hybrid:
                try await performHybridAnalysis(image: image)
            }
        } catch let recognitionError as RecognitionError {
            error = recognitionError
        } catch {
            self.error = .networkError
        }
        
        isProcessing = false
    }
    
    // MARK: - Private Methods
    
    private func performHighAccuracyAnalysis(image: UIImage) async throws {
        // Start with ChatGPT Vision analysis
        chatGPTService.scanFoodImage(image)
        
        // Wait for results
        while chatGPTService.scanInProgress {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Check for results
        if let result = chatGPTService.scanResults.first {
            // Convert ChatGPT results to our format
            let results = try await convertAndEnrichResults(from: result)
            
            if results.isEmpty {
                throw RecognitionError.noResults
            }
            
            // Update results
            recognitionResults = results
        } else {
            throw RecognitionError.noResults
        }
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
                        confidence: Double(mlResult.confidence),
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
    
    private func performHybridAnalysis(image: UIImage) async throws {
        // Start with quick ML scan
        let mlResults = try await performQuickScan(image: image)
        
        // If ML results are confident enough, use them
        let confidentResults = mlResults.filter { $0.confidence >= 0.7 }
        
        if !confidentResults.isEmpty {
            recognitionResults = confidentResults
            return
        }
        
        // If ML results aren't confident enough, fall back to high accuracy
        try await performHighAccuracyAnalysis(image: image)
    }
    
    private func convertAndEnrichResults(from scanResult: ChatGPTScanResult) async throws -> [FoodRecognitionResult] {
        return [FoodRecognitionResult(
            id: UUID(),
            name: scanResult.foodName,
            confidence: scanResult.confidenceScore,
            nutrition: NutritionInfo(
                calories: Int(scanResult.calories),
                protein: scanResult.protein,
                carbs: scanResult.carbs,
                fats: scanResult.fats,
                fiber: nil,
                sugar: nil,
                vitamins: [:],
                minerals: [:]
            ),
            healthConsiderations: [],
            allergens: [],
            portionSize: scanResult.servingSize,
            preparationMethod: nil,
            isFresh: nil,
            isDiabetesFriendly: nil,
            glycemicIndex: nil
        )]
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
    case highAccuracy  // Uses ChatGPT Vision for detailed analysis
    case quickScan    // Uses CoreML for fast recognition
    case hybrid       // Starts with CoreML, falls back to ChatGPT if needed
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
    let confidence: Double
    let nutrition: NutritionInfo?
    let healthConsiderations: [String]
    let allergens: [String]
    let portionSize: String?
    let preparationMethod: String?
    let isFresh: Bool?
    let isDiabetesFriendly: Bool?
    let glycemicIndex: Int?
} 