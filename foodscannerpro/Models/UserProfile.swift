import Foundation
import SwiftUI
import UIKit
import Components

class UserProfile: ObservableObject {
    static let shared = UserProfile()
    
    @Published var name: String = "John Doe"
    @Published var email: String = "john@example.com"
    @Published var age: Int = 30
    @Published var height: Double = 175.0 // cm
    @Published var weight: Double = 70.0 // kg
    @Published var profileImage: UIImage?
    @Published var bloodPressure: String = "120/80"
    @Published var bloodSugar: Double = 5.5 // mmol/L
    @Published var cholesterol: Components.Cholesterol = Components.Cholesterol()
    @Published var alertPreferences: Components.AlertPreferences = Components.AlertPreferences()
    @Published var dietaryPreferences: [String] = []
    @Published var allergies: [String] = []
    @Published var goals: [String] = []
    
    var bmi: Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    var bmiCategory: Components.BMICategory {
        switch bmi {
        case ..<18.5:
            return .underweight
        case 18.5..<25:
            return .normal
        case 25..<30:
            return .overweight
        default:
            return .obese
        }
    }
    
    private init() {
        loadProfile()
    }
    
    func updateProfileImage(_ image: UIImage) {
        profileImage = image
        save()
    }
    
    func save() {
        let data = ProfileData(
            name: name,
            email: email,
            age: age,
            height: height,
            weight: weight,
            bloodPressure: bloodPressure,
            bloodSugar: bloodSugar,
            cholesterol: cholesterol,
            alertPreferences: alertPreferences,
            dietaryPreferences: dietaryPreferences,
            allergies: allergies,
            goals: goals
        )
        
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
        }
        
        // Save profile image separately
        if let image = profileImage,
           let imageData = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(imageData, forKey: "profileImage")
        }
    }
    
    private func loadProfile() {
        // Load profile data
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let decoded = try? JSONDecoder().decode(ProfileData.self, from: data) {
            name = decoded.name
            email = decoded.email
            age = decoded.age
            height = decoded.height
            weight = decoded.weight
            bloodPressure = decoded.bloodPressure
            bloodSugar = decoded.bloodSugar
            cholesterol = decoded.cholesterol
            alertPreferences = decoded.alertPreferences
            dietaryPreferences = decoded.dietaryPreferences
            allergies = decoded.allergies
            goals = decoded.goals
        }
        
        // Load profile image
        if let imageData = UserDefaults.standard.data(forKey: "profileImage"),
           let image = UIImage(data: imageData) {
            profileImage = image
        }
    }
    
    private struct ProfileData: Codable {
        let name: String
        let email: String
        let age: Int
        let height: Double
        let weight: Double
        let bloodPressure: String
        let bloodSugar: Double
        let cholesterol: Components.Cholesterol
        let alertPreferences: Components.AlertPreferences
        let dietaryPreferences: [String]
        let allergies: [String]
        let goals: [String]
    }
} 