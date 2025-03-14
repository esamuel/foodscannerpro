import Foundation
import SwiftUI

// MARK: - Health Condition Models

/// Represents a health condition that affects dietary needs
enum HealthCondition: String, CaseIterable, Identifiable, Codable {
    case diabetes = "Diabetes"
    case heartDisease = "Heart Disease"
    case highBloodPressure = "High Blood Pressure"
    case highCholesterol = "High Cholesterol"
    case celiacDisease = "Celiac Disease"
    case lactoseIntolerance = "Lactose Intolerance"
    case nutAllergy = "Nut Allergy"
    case shellfish = "Shellfish Allergy"
    case gluten = "Gluten Sensitivity"
    case none = "None"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .diabetes:
            return "Monitor carbohydrate intake and sugar levels"
        case .heartDisease:
            return "Limit saturated fats, trans fats, and sodium"
        case .highBloodPressure:
            return "Reduce sodium intake and maintain healthy weight"
        case .highCholesterol:
            return "Limit saturated fats and increase fiber intake"
        case .celiacDisease:
            return "Avoid all foods containing gluten"
        case .lactoseIntolerance:
            return "Avoid or limit dairy products"
        case .nutAllergy:
            return "Avoid all nut products and check for cross-contamination"
        case .shellfish:
            return "Avoid all shellfish and check for cross-contamination"
        case .gluten:
            return "Limit or avoid foods containing gluten"
        case .none:
            return "No specific dietary restrictions"
        }
    }
    
    var icon: String {
        switch self {
        case .diabetes:
            return "drop.fill"
        case .heartDisease:
            return "heart.fill"
        case .highBloodPressure:
            return "waveform.path.ecg"
        case .highCholesterol:
            return "chart.line.uptrend.xyaxis"
        case .celiacDisease:
            return "allergens"
        case .lactoseIntolerance:
            return "cup.and.saucer.fill"
        case .nutAllergy:
            return "leaf.fill"
        case .shellfish:
            return "fish.fill"
        case .gluten:
            return "g.circle.fill"
        case .none:
            return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .diabetes:
            return .blue
        case .heartDisease:
            return .red
        case .highBloodPressure:
            return .orange
        case .highCholesterol:
            return .yellow
        case .celiacDisease:
            return .brown
        case .lactoseIntolerance:
            return .mint
        case .nutAllergy:
            return .green
        case .shellfish:
            return .cyan
        case .gluten:
            return .indigo
        case .none:
            return .gray
        }
    }
    
    var restrictedIngredients: [String] {
        switch self {
        case .diabetes:
            return ["sugar", "corn syrup", "honey", "agave", "maple syrup", "molasses"]
        case .heartDisease:
            return ["saturated fat", "trans fat", "sodium", "salt", "cholesterol"]
        case .highBloodPressure:
            return ["sodium", "salt", "msg", "monosodium glutamate"]
        case .highCholesterol:
            return ["saturated fat", "trans fat", "cholesterol"]
        case .celiacDisease:
            return ["wheat", "barley", "rye", "malt", "brewer's yeast", "gluten"]
        case .lactoseIntolerance:
            return ["milk", "cheese", "yogurt", "cream", "butter", "whey", "lactose"]
        case .nutAllergy:
            return ["peanut", "almond", "hazelnut", "walnut", "cashew", "pistachio", "pecan", "nut"]
        case .shellfish:
            return ["shrimp", "crab", "lobster", "clam", "mussel", "oyster", "scallop", "shellfish"]
        case .gluten:
            return ["wheat", "barley", "rye", "malt", "gluten"]
        case .none:
            return []
        }
    }
    
    var warningLevel: WarningLevel {
        switch self {
        case .nutAllergy, .shellfish:
            return .severe
        case .celiacDisease, .lactoseIntolerance, .gluten:
            return .moderate
        case .diabetes, .heartDisease, .highBloodPressure, .highCholesterol:
            return .mild
        case .none:
            return .none
        }
    }
}

/// Represents the severity of a dietary warning
enum WarningLevel: String, Codable {
    case severe = "Severe"
    case moderate = "Moderate"
    case mild = "Mild"
    case none = "None"
    
    var color: Color {
        switch self {
        case .severe:
            return .red
        case .moderate:
            return .orange
        case .mild:
            return .yellow
        case .none:
            return .green
        }
    }
    
    var icon: String {
        switch self {
        case .severe:
            return "exclamationmark.triangle.fill"
        case .moderate:
            return "exclamationmark.circle.fill"
        case .mild:
            return "exclamationmark.circle"
        case .none:
            return "checkmark.circle.fill"
        }
    }
}

/// Represents a dietary goal
enum DietaryGoal: String, CaseIterable, Identifiable, Codable {
    case weightLoss = "Weight Loss"
    case weightGain = "Weight Gain"
    case maintenance = "Maintenance"
    case muscleGain = "Muscle Gain"
    case heartHealth = "Heart Health"
    case diabetesManagement = "Diabetes Management"
    case lowCarb = "Low Carb"
    case lowFat = "Low Fat"
    case highProtein = "High Protein"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .weightLoss:
            return "Focus on calorie deficit with balanced nutrition"
        case .weightGain:
            return "Focus on calorie surplus with nutritious foods"
        case .maintenance:
            return "Maintain current weight with balanced diet"
        case .muscleGain:
            return "Increase protein intake and strength training"
        case .heartHealth:
            return "Reduce sodium and saturated fats"
        case .diabetesManagement:
            return "Monitor carbs and maintain steady blood sugar"
        case .lowCarb:
            return "Limit carbohydrate intake"
        case .lowFat:
            return "Reduce overall fat consumption"
        case .highProtein:
            return "Increase protein sources in diet"
        }
    }
    
    var icon: String {
        switch self {
        case .weightLoss:
            return "arrow.down.circle.fill"
        case .weightGain:
            return "arrow.up.circle.fill"
        case .maintenance:
            return "equal.circle.fill"
        case .muscleGain:
            return "figure.strengthtraining.traditional"
        case .heartHealth:
            return "heart.fill"
        case .diabetesManagement:
            return "drop.fill"
        case .lowCarb:
            return "chart.bar.fill"
        case .lowFat:
            return "chart.pie.fill"
        case .highProtein:
            return "fork.knife"
        }
    }
    
    var recommendedFoods: [String] {
        switch self {
        case .weightLoss:
            return ["vegetables", "lean protein", "fruits", "whole grains", "water"]
        case .weightGain:
            return ["nuts", "avocado", "olive oil", "whole milk", "protein"]
        case .maintenance:
            return ["balanced meals", "variety", "whole foods"]
        case .muscleGain:
            return ["chicken breast", "eggs", "greek yogurt", "salmon", "quinoa"]
        case .heartHealth:
            return ["salmon", "oats", "berries", "nuts", "olive oil"]
        case .diabetesManagement:
            return ["non-starchy vegetables", "whole grains", "lean protein", "healthy fats"]
        case .lowCarb:
            return ["eggs", "meat", "fish", "cheese", "nuts", "vegetables"]
        case .lowFat:
            return ["fruits", "vegetables", "whole grains", "lean protein"]
        case .highProtein:
            return ["chicken", "turkey", "fish", "eggs", "greek yogurt", "tofu"]
        }
    }
    
    var limitedFoods: [String] {
        switch self {
        case .weightLoss:
            return ["processed foods", "sugary drinks", "alcohol", "fried foods"]
        case .weightGain:
            return ["low-calorie foods", "diet products"]
        case .maintenance:
            return ["excessive processed foods", "sugar"]
        case .muscleGain:
            return ["alcohol", "processed sugar", "fried foods"]
        case .heartHealth:
            return ["salt", "processed meats", "fried foods", "baked goods"]
        case .diabetesManagement:
            return ["sugar", "refined carbs", "fruit juice", "processed foods"]
        case .lowCarb:
            return ["bread", "pasta", "sugar", "potatoes", "rice"]
        case .lowFat:
            return ["butter", "oils", "fried foods", "fatty meats", "full-fat dairy"]
        case .highProtein:
            return ["processed carbs", "sugary foods", "empty calories"]
        }
    }
}

/// Represents a user's health profile
struct HealthProfile: Codable {
    var id: UUID = UUID()
    var name: String = ""
    var age: Int = 30
    var gender: String = "Not Specified"
    var height: Double = 170 // cm
    var weight: Double = 70 // kg
    var healthConditions: [HealthCondition] = []
    var dietaryGoal: DietaryGoal = .maintenance
    var dailyCalorieTarget: Int = 2000
    var dailyProteinTarget: Int = 50 // g
    var dailyCarbTarget: Int = 250 // g
    var dailyFatTarget: Int = 70 // g
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    var bmi: Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
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
    
    /// Calculate recommended daily calorie intake based on profile
    mutating func calculateRecommendedCalories() {
        // Basic BMR calculation using Mifflin-St Jeor Equation
        var bmr: Double
        
        if gender.lowercased() == "male" {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        }
        
        // Activity factor (assuming moderate activity)
        let activityFactor = 1.375
        var tdee = bmr * activityFactor
        
        // Adjust based on goal
        switch dietaryGoal {
        case .weightLoss:
            tdee *= 0.8 // 20% deficit
        case .weightGain, .muscleGain:
            tdee *= 1.15 // 15% surplus
        default:
            break // No adjustment for maintenance
        }
        
        dailyCalorieTarget = Int(tdee)
        
        // Calculate macronutrient targets
        switch dietaryGoal {
        case .highProtein, .muscleGain:
            // Higher protein (30%), moderate carbs (40%), moderate fat (30%)
            dailyProteinTarget = Int(tdee * 0.3 / 4) // 4 calories per gram of protein
            dailyCarbTarget = Int(tdee * 0.4 / 4) // 4 calories per gram of carbs
            dailyFatTarget = Int(tdee * 0.3 / 9) // 9 calories per gram of fat
        case .lowCarb:
            // Higher protein (30%), lower carbs (30%), higher fat (40%)
            dailyProteinTarget = Int(tdee * 0.3 / 4)
            dailyCarbTarget = Int(tdee * 0.3 / 4)
            dailyFatTarget = Int(tdee * 0.4 / 9)
        case .lowFat:
            // Moderate protein (25%), higher carbs (55%), lower fat (20%)
            dailyProteinTarget = Int(tdee * 0.25 / 4)
            dailyCarbTarget = Int(tdee * 0.55 / 4)
            dailyFatTarget = Int(tdee * 0.2 / 9)
        default:
            // Balanced: protein (20%), carbs (50%), fat (30%)
            dailyProteinTarget = Int(tdee * 0.2 / 4)
            dailyCarbTarget = Int(tdee * 0.5 / 4)
            dailyFatTarget = Int(tdee * 0.3 / 9)
        }
    }
}

/// Represents a dietary warning for a food item
struct DietaryWarning: Identifiable {
    let id = UUID()
    let foodName: String
    let condition: HealthCondition
    let warningLevel: WarningLevel
    let message: String
    let suggestedAlternative: String?
    
    init(foodName: String, condition: HealthCondition, message: String, suggestedAlternative: String? = nil) {
        self.foodName = foodName
        self.condition = condition
        self.warningLevel = condition.warningLevel
        self.message = message
        self.suggestedAlternative = suggestedAlternative
    }
}

/// Represents a personalized recommendation
struct FoodRecommendation: Identifiable {
    let id = UUID()
    let foodName: String
    let reason: String
    let nutritionalBenefits: String
    let goal: DietaryGoal
    
    init(foodName: String, reason: String, nutritionalBenefits: String, goal: DietaryGoal) {
        self.foodName = foodName
        self.reason = reason
        self.nutritionalBenefits = nutritionalBenefits
        self.goal = goal
    }
} 