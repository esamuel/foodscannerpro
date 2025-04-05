import Foundation
import SwiftUI
import Combine

/// Result of a food classification operation
public struct FoodClassificationResult: Identifiable, Sendable {
    public let id: UUID
    public let label: String
    public let confidence: Float
    
    public init(id: UUID = UUID(), label: String, confidence: Float) {
        self.id = id
        self.label = label
        self.confidence = confidence
    }
    
    public var isReliable: Bool {
        confidence > 0.7 // 70% confidence threshold
    }
    
    public var confidencePercentage: String {
        String(format: "%.1f%%", confidence * 100)
    }
}

/// Errors that can occur during food analysis
public enum FoodAnalysisError: Error, Sendable {
    case modelNotFound(String)
    case modelsNotInitialized
    case invalidImage
    case classificationFailed(Error)
} 