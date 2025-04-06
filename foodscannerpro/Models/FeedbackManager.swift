import Foundation
import SwiftUI

enum FoodRecognitionFeedback: String, Codable {
    case correct = "Correct"
    case incorrect = "Incorrect"
    case partiallyCorrect = "Partially Correct"
}

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    @Published var isSubmitting = false
    @Published var lastError: String?
    @Published var feedbackData: [FeedbackEntry] = []
    
    private let userDefaults = UserDefaults.standard
    private let feedbackKey = "foodRecognitionFeedback"
    private let feedbackQueue = DispatchQueue(label: "com.foodscannerpro.feedbackQueue", attributes: .concurrent)
    
    private init() {
        loadFeedback()
    }
    
    func submitFeedback(originalResult: FoodRecognitionResult, correctedName: String, additionalNotes: String? = nil) async {
        guard !isSubmitting else { return }
        
        DispatchQueue.main.async {
            self.isSubmitting = true
            self.lastError = nil
        }
        
        do {
            let feedback = FeedbackEntry(
                timestamp: Date(),
                foodName: originalResult.name,
                correctFoodName: correctedName,
                confidence: originalResult.confidence,
                additionalNotes: additionalNotes
            )
            
            try await saveFeedback(feedback)
            
            DispatchQueue.main.async {
                self.isSubmitting = false
            }
        } catch {
            DispatchQueue.main.async {
                self.isSubmitting = false
                self.lastError = error.localizedDescription
            }
        }
    }
    
    func addFeedback(for food: RecognizedFood, feedback: FoodRecognitionFeedback, correctName: String? = nil) {
        let entry = FeedbackEntry(
            timestamp: Date(),
            foodName: food.name,
            correctFoodName: correctName ?? "",
            confidence: food.confidence,
            additionalNotes: nil,
            feedback: feedback
        )
        
        // Use concurrent queue for background work, then update UI on main thread
        feedbackQueue.async {
            // Create a local copy to avoid race conditions
            var currentFeedback = self.feedbackData
            currentFeedback.append(entry)
            
            // Encode the data
            if let encoded = try? JSONEncoder().encode(currentFeedback) {
                // Save to user defaults
                self.userDefaults.set(encoded, forKey: self.feedbackKey)
                
                // Update the published property on the main thread
                DispatchQueue.main.async {
                    self.feedbackData = currentFeedback
                }
            }
        }
    }
    
    func loadFeedback() {
        feedbackQueue.async {
            if let data = self.userDefaults.data(forKey: self.feedbackKey),
               let decoded = try? JSONDecoder().decode([FeedbackEntry].self, from: data) {
                DispatchQueue.main.async {
                    self.feedbackData = decoded
                }
            }
        }
    }
    
    private func saveFeedback(_ feedback: FeedbackEntry) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            feedbackQueue.async {
                do {
                    // Get the feedback file URL
                    let fileManager = FileManager.default
                    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let feedbackFile = documentsPath.appendingPathComponent("recognition_feedback.json")
                    
                    // Load existing feedback
                    var existingFeedback: [FeedbackEntry] = []
                    if fileManager.fileExists(atPath: feedbackFile.path) {
                        let data = try Data(contentsOf: feedbackFile)
                        existingFeedback = try JSONDecoder().decode([FeedbackEntry].self, from: data)
                    }
                    
                    // Add new feedback
                    existingFeedback.append(feedback)
                    
                    // Save back to file
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let data = try encoder.encode(existingFeedback)
                    try data.write(to: feedbackFile)
                    
                    // Also update the UserDefaults and published property
                    let finalFeedback = existingFeedback
                    if let encoded = try? JSONEncoder().encode(finalFeedback) {
                        self.userDefaults.set(encoded, forKey: self.feedbackKey)
                        
                        DispatchQueue.main.async {
                            self.feedbackData = finalFeedback
                        }
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func exportFeedback() -> Data? {
        return try? JSONEncoder().encode(feedbackData)
    }
}

struct FeedbackEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let foodName: String
    let correctFoodName: String?
    let confidence: Float
    let additionalNotes: String?
    let feedback: FoodRecognitionFeedback?
    
    init(id: UUID = UUID(), timestamp: Date = Date(), foodName: String, correctFoodName: String? = nil, 
         confidence: Float, additionalNotes: String? = nil, feedback: FoodRecognitionFeedback? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.foodName = foodName
        self.correctFoodName = correctFoodName
        self.confidence = confidence
        self.additionalNotes = additionalNotes
        self.feedback = feedback
    }
} 