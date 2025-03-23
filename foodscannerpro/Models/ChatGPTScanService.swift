import Foundation
import UIKit
import SwiftUI

// Model for ChatGPT Scan Result
struct ChatGPTScanResult: Identifiable, Hashable {
    var id = UUID()
    var foodName: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fats: Double
    var confidenceScore: Double
    var servingSize: String?
    var notes: String?
    
    // Computed property to convert to NutritionInfo
    var asNutritionInfo: FoodNutritionInfo {
        return FoodNutritionInfo(
            foodName: foodName,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            sugar: 0,  // Not provided in scan
            fiber: 0,  // Not provided in scan
            sodium: 0, // Not provided in scan
            cholesterol: 0, // Not provided in scan
            servingSize: servingSize ?? "1 serving"
        )
    }
    
    // For Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ChatGPTScanResult, rhs: ChatGPTScanResult) -> Bool {
        return lhs.id == rhs.id
    }
}

// ChatGPT Scan Service
class ChatGPTScanService: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var scanResults: [ChatGPTScanResult] = []
    @Published var errorMessage: String?
    @Published var scanInProgress: Bool = false
    
    // Simulation data for different food types (to use during development)
    private let simulatedFoods: [String: ChatGPTScanResult] = [
        "pizza": ChatGPTScanResult(
            foodName: "Pizza Slice",
            calories: 285,
            protein: 12.0,
            carbs: 36.0,
            fats: 10.5,
            confidenceScore: 0.92,
            servingSize: "1 slice (107g)",
            notes: "Typical cheese pizza slice. Toppings may add calories."
        ),
        "apple": ChatGPTScanResult(
            foodName: "Apple",
            calories: 95,
            protein: 0.5,
            carbs: 25.0,
            fats: 0.3,
            confidenceScore: 0.96,
            servingSize: "1 medium (182g)",
            notes: "Rich in fiber and vitamin C."
        ),
        "salad": ChatGPTScanResult(
            foodName: "Garden Salad",
            calories: 120,
            protein: 3.0,
            carbs: 12.0,
            fats: 7.0,
            confidenceScore: 0.85,
            servingSize: "2 cups (160g)",
            notes: "Includes lettuce, tomatoes, cucumber, and light dressing."
        ),
        "burger": ChatGPTScanResult(
            foodName: "Hamburger",
            calories: 354,
            protein: 20.0,
            carbs: 40.0,
            fats: 17.0,
            confidenceScore: 0.93,
            servingSize: "1 regular burger (170g)",
            notes: "Standard beef patty with bun and basic toppings."
        ),
        "pasta": ChatGPTScanResult(
            foodName: "Spaghetti with Marinara",
            calories: 320,
            protein: 12.0,
            carbs: 58.0,
            fats: 6.0,
            confidenceScore: 0.89,
            servingSize: "1 cup (140g)",
            notes: "Plain pasta with tomato-based sauce."
        )
    ]
    
    // Add multiple food items for a plate of food
    private let mixedPlateSimulation: [ChatGPTScanResult] = [
        ChatGPTScanResult(
            foodName: "Grilled Chicken Breast",
            calories: 165,
            protein: 31.0,
            carbs: 0.0,
            fats: 3.6,
            confidenceScore: 0.94,
            servingSize: "1 breast (100g)",
            notes: "Lean protein source."
        ),
        ChatGPTScanResult(
            foodName: "Steamed Broccoli",
            calories: 55,
            protein: 3.7,
            carbs: 11.2,
            fats: 0.6,
            confidenceScore: 0.87,
            servingSize: "1 cup (91g)",
            notes: "Rich in vitamins K and C."
        ),
        ChatGPTScanResult(
            foodName: "Brown Rice",
            calories: 218,
            protein: 4.5,
            carbs: 45.8,
            fats: 1.8,
            confidenceScore: 0.83,
            servingSize: "1 cup (195g)",
            notes: "Whole grain carbohydrate source."
        )
    ]
    
    // Simulate a scan - in a real implementation, this would call an API
    func scanFoodImage(_ image: UIImage) {
        isScanning = true
        scanInProgress = true
        errorMessage = nil
        scanResults = []
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            
            // For demo purposes, randomly select between different types of results
            let randomValue = Int.random(in: 0...10)
            
            if randomValue < 7 {
                // 70% chance to pick a specific food
                let foodTypes = ["pizza", "apple", "salad", "burger", "pasta"]
                let selectedFood = foodTypes.randomElement() ?? "apple"
                
                if let food = self.simulatedFoods[selectedFood] {
                    self.scanResults = [food]
                }
            } else if randomValue < 9 {
                // 20% chance for a mixed plate
                self.scanResults = self.mixedPlateSimulation
            } else {
                // 10% chance to fail
                self.errorMessage = "Could not identify the food in this image. Please try again with a clearer photo."
            }
            
            self.isScanning = false
            self.scanInProgress = false
        }
    }
    
    // In a real implementation, this would send the image to an API
    func performRealScan(_ image: UIImage) {
        // Convert image to base64
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            self.errorMessage = "Failed to process image data"
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // This would be where you'd make an API call to a service that can analyze the image
        // For now, we'll just use the simulation
        scanFoodImage(image)
    }
} 