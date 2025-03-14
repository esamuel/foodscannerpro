import Foundation
import SwiftUI

class UserProfile: ObservableObject {
    @Published var name: String = "John Doe"
    @Published var email: String = "john.doe@example.com"
    @Published var age: Int = 30
    @Published var height: Double = 175.0 // cm
    @Published var weight: Double = 70.0 // kg
    @Published var dietaryPreferences: [String] = ["Balanced", "Low Carb"]
    @Published var allergies: [String] = ["Peanuts", "Shellfish"]
    @Published var goals: [String] = ["Weight Maintenance", "Healthy Eating"]
    @Published var profileImage: UIImage? = nil
    
    // Computed property for BMI
    var bmi: Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    // Computed property for BMI category
    var bmiCategory: String {
        switch bmi {
        case ..<18.5:
            return "Underweight"
        case 18.5..<25:
            return "Normal"
        case 25..<30:
            return "Overweight"
        default:
            return "Obese"
        }
    }
    
    // Singleton instance
    static let shared = UserProfile()
    
    private init() {
        // Load user data from UserDefaults
        if let savedData = UserDefaults.standard.data(forKey: "userProfile") {
            if let decoded = try? JSONDecoder().decode(SavedUserProfile.self, from: savedData) {
                self.name = decoded.name
                self.email = decoded.email
                self.age = decoded.age
                self.height = decoded.height
                self.weight = decoded.weight
                self.dietaryPreferences = decoded.dietaryPreferences
                self.allergies = decoded.allergies
                self.goals = decoded.goals
            }
        }
        
        // Load profile image if available
        if let imageData = UserDefaults.standard.data(forKey: "userProfileImage") {
            self.profileImage = UIImage(data: imageData)
        }
    }
    
    func save() {
        // Save user data to UserDefaults
        let savedData = SavedUserProfile(
            name: name,
            email: email,
            age: age,
            height: height,
            weight: weight,
            dietaryPreferences: dietaryPreferences,
            allergies: allergies,
            goals: goals
        )
        
        if let encoded = try? JSONEncoder().encode(savedData) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
        
        // Save profile image if available
        if let image = profileImage, let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "userProfileImage")
        }
    }
    
    // Helper struct for encoding/decoding
    private struct SavedUserProfile: Codable {
        let name: String
        let email: String
        let age: Int
        let height: Double
        let weight: Double
        let dietaryPreferences: [String]
        let allergies: [String]
        let goals: [String]
    }
} 