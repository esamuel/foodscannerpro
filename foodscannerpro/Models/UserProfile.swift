import Foundation
import SwiftUI
import UIKit

class UserProfile: ObservableObject {
    static let shared = UserProfile()
    
    @Published var name: String = "John Doe"
    @Published var email: String = "john.doe@example.com"
    @Published var age: Int = 30
    @Published var height: Double = 175.0 // cm
    @Published var weight: Double = 70.0 // kg
    @Published var profileImage: UIImage? = nil
    @Published var dietaryPreferences: [String] = ["Vegetarian", "Low Carb"]
    @Published var allergies: [String] = ["Peanuts", "Shellfish"]
    @Published var goals: [String] = ["Weight Loss", "Muscle Gain"]
    
    // New health metrics
    @Published var bloodPressure: String = "120/80"
    @Published var bloodSugar: Double = 5.5 // mmol/L
    @Published var cholesterol: Cholesterol = Cholesterol()
    
    // Alert preferences
    @Published var alertPreferences: AlertPreferences = AlertPreferences()
    
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
    
    private init() {
        load()
    }
    
    func save() {
        let encoder = JSONEncoder()
        
        // Save basic profile data
        if let encoded = try? encoder.encode(ProfileData(from: self)) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
        
        // Save profile image separately
        if let image = profileImage, let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "userProfileImage")
        }
    }
    
    func load() {
        // Load basic profile data
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let decoded = try? JSONDecoder().decode(ProfileData.self, from: data) {
            self.name = decoded.name
            self.email = decoded.email
            self.age = decoded.age
            self.height = decoded.height
            self.weight = decoded.weight
            self.dietaryPreferences = decoded.dietaryPreferences
            self.allergies = decoded.allergies
            self.goals = decoded.goals
            self.bloodPressure = decoded.bloodPressure
            self.bloodSugar = decoded.bloodSugar
            self.cholesterol = decoded.cholesterol
            self.alertPreferences = decoded.alertPreferences
        }
        
        // Load profile image
        if let imageData = UserDefaults.standard.data(forKey: "userProfileImage") {
            self.profileImage = UIImage(data: imageData)
        }
    }
    
    // Helper struct for encoding/decoding
    private struct ProfileData: Codable {
        let name: String
        let email: String
        let age: Int
        let height: Double
        let weight: Double
        let dietaryPreferences: [String]
        let allergies: [String]
        let goals: [String]
        let bloodPressure: String
        let bloodSugar: Double
        let cholesterol: Cholesterol
        let alertPreferences: AlertPreferences
        
        init(from profile: UserProfile) {
            self.name = profile.name
            self.email = profile.email
            self.age = profile.age
            self.height = profile.height
            self.weight = profile.weight
            self.dietaryPreferences = profile.dietaryPreferences
            self.allergies = profile.allergies
            self.goals = profile.goals
            self.bloodPressure = profile.bloodPressure
            self.bloodSugar = profile.bloodSugar
            self.cholesterol = profile.cholesterol
            self.alertPreferences = profile.alertPreferences
        }
    }
}

// Cholesterol data structure
struct Cholesterol: Codable, Equatable {
    var total: Double = 5.2 // mmol/L
    var hdl: Double = 1.3   // mmol/L (good cholesterol)
    var ldl: Double = 3.4   // mmol/L (bad cholesterol)
    
    var ratio: Double {
        return total / hdl
    }
    
    var status: CholesterolStatus {
        if total < 5.2 && ldl < 3.4 && hdl > 1.0 {
            return .optimal
        } else if total < 6.2 && ldl < 4.1 && hdl > 1.0 {
            return .borderline
        } else {
            return .high
        }
    }
    
    enum CholesterolStatus: String, Codable {
        case optimal = "Optimal"
        case borderline = "Borderline"
        case high = "High"
    }
}

// Alert preferences structure
struct AlertPreferences: Codable, Equatable {
    var alertForSugar: Bool = true
    var alertForSodium: Bool = true
    var alertForFat: Bool = true
    var alertForCalories: Bool = true
    var alertForAllergens: Bool = true
    
    var sugarThreshold: Double = 25.0 // grams
    var sodiumThreshold: Double = 2300.0 // mg
    var fatThreshold: Double = 65.0 // grams
    var calorieThreshold: Double = 600.0 // per meal
} 