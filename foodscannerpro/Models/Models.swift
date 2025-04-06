import Foundation
import SwiftUI

// MARK: - USDA API Types
struct USDAResponse: Codable {
    let foods: [USDAFood]
}

struct USDAFood: Codable {
    let description: String
    let foodNutrients: [USDANutrient]
    let servingSize: Double?
    let servingSizeUnit: String?
    
    enum CodingKeys: String, CodingKey {
        case description
        case foodNutrients
        case servingSize = "servingSize"
        case servingSizeUnit = "servingSizeUnit"
    }
}

struct USDANutrient: Codable {
    let nutrientId: Int
    let nutrientName: String
    let value: Double
    let unitName: String
    
    enum CodingKeys: String, CodingKey {
        case nutrientId = "nutrientId"
        case nutrientName = "nutrientName"
        case value
        case unitName = "unitName"
    }
}

enum NutrientIDs {
    static let energy = 1008
    static let protein = 1003
    static let carbs = 1005
    static let fat = 1004
    static let fiber = 1079
    static let sugar = 2000
    static let sodium = 1093
    static let cholesterol = 1253
    static let potassium = 1092
    static let calcium = 1087
    static let iron = 1089
    static let vitaminA = 1106
    static let vitaminC = 1162
}

// MARK: - Health Models
struct HealthProfile: Codable {
    var healthConditions: [HealthCondition]
    var dietaryGoal: DietaryGoal
    var dietaryRestrictions: [DietaryRestriction]
    var height: Double
    var weight: Double
    var age: Int
    var gender: Gender
    var activityLevel: ActivityLevel
    var updatedAt: Date
    
    var dailyCalorieTarget: Int {
        get {
            return calculateRecommendedCalories()
        }
    }
    
    var dailyProteinTarget: Int {
        get {
            switch dietaryGoal {
            case .muscleGain:
                return Int(weight * 2.0) // 2g per kg bodyweight
            case .weightLoss:
                return Int(weight * 1.8) // 1.8g per kg bodyweight
            default:
                return Int(weight * 1.6) // 1.6g per kg bodyweight
            }
        }
    }
    
    static var `default`: HealthProfile {
        HealthProfile(
            healthConditions: [.none],
            dietaryGoal: .maintenance,
            dietaryRestrictions: [],
            height: 170,
            weight: 70,
            age: 30,
            gender: .notSpecified,
            activityLevel: .moderate,
            updatedAt: Date()
        )
    }
    
    func calculateRecommendedCalories() -> Int {
        // Mifflin-St Jeor Equation
        let bmr: Double
        switch gender {
        case .male:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) + 5
        case .female:
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 161
        case .notSpecified:
            // Use average of male and female
            bmr = 10 * weight + 6.25 * height - 5 * Double(age) - 78
        }
        
        // Activity multiplier
        let activityMultiplier = activityLevel.calorieMultiplier
        
        // Goal adjustment
        let goalAdjustment: Double
        switch dietaryGoal {
        case .weightLoss:
            goalAdjustment = -500 // Calorie deficit
        case .muscleGain:
            goalAdjustment = 300 // Calorie surplus
        default:
            goalAdjustment = 0
        }
        
        return Int((bmr * activityMultiplier) + goalAdjustment)
    }
}

enum Gender: String, Codable {
    case male = "Male"
    case female = "Female"
    case notSpecified = "Not Specified"
}

enum ActivityLevel: String, Codable {
    case sedentary = "Sedentary"
    case light = "Light"
    case moderate = "Moderate"
    case active = "Active"
    case veryActive = "Very Active"
    
    var calorieMultiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

enum HealthCondition: String, Codable {
    case diabetes = "Diabetes"
    case hypertension = "Hypertension"
    case heartDisease = "Heart Disease"
    case celiacDisease = "Celiac Disease"
    case lactoseIntolerance = "Lactose Intolerance"
    case highCholesterol = "High Cholesterol"
    case highBloodPressure = "High Blood Pressure"
    case gluten = "Gluten Sensitivity"
    case nutAllergy = "Nut Allergy"
    case shellfish = "Shellfish Allergy"
    case none = "None"
    
    var restrictedIngredients: [String] {
        switch self {
        case .diabetes:
            return ["sugar", "syrup", "honey", "candy", "soda", "sweet"]
        case .hypertension, .highBloodPressure:
            return ["salt", "sodium", "msg", "soy sauce"]
        case .heartDisease, .highCholesterol:
            return ["saturated fat", "trans fat", "cholesterol", "fried"]
        case .celiacDisease, .gluten:
            return ["wheat", "barley", "rye", "gluten", "bread", "pasta"]
        case .lactoseIntolerance:
            return ["milk", "dairy", "cheese", "cream", "yogurt", "butter"]
        case .nutAllergy:
            return ["nut", "peanut", "almond", "cashew", "walnut", "pecan"]
        case .shellfish:
            return ["shrimp", "crab", "lobster", "shellfish", "seafood"]
        case .none:
            return []
        }
    }
}

enum DietaryGoal: String, Codable {
    case weightLoss = "Weight Loss"
    case muscleGain = "Muscle Gain"
    case maintenance = "Maintenance"
    case heartHealth = "Heart Health"
    case diabetesManagement = "Diabetes Management"
    case lowCarb = "Low Carb"
    case highProtein = "High Protein"
    
    var recommendedFoods: [String] {
        switch self {
        case .weightLoss:
            return ["lean protein", "vegetables", "fruits", "whole grains", "legumes"]
        case .muscleGain:
            return ["chicken breast", "eggs", "salmon", "quinoa", "greek yogurt", "lean beef"]
        case .maintenance:
            return ["balanced meals", "whole foods", "fruits", "vegetables", "lean proteins"]
        case .heartHealth:
            return ["salmon", "nuts", "olive oil", "avocado", "leafy greens", "berries"]
        case .diabetesManagement:
            return ["non-starchy vegetables", "whole grains", "lean protein", "nuts", "berries"]
        case .lowCarb:
            return ["eggs", "meat", "fish", "cheese", "low-carb vegetables", "nuts"]
        case .highProtein:
            return ["chicken breast", "turkey", "fish", "eggs", "greek yogurt", "lean beef"]
        }
    }
}

enum DietaryRestriction: String, Codable {
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case glutenFree = "Gluten Free"
    case dairyFree = "Dairy Free"
    case kosher = "Kosher"
    case halal = "Halal"
    
    var restrictedFoods: [String] {
        switch self {
        case .vegetarian:
            return ["meat", "fish", "poultry"]
        case .vegan:
            return ["meat", "fish", "poultry", "dairy", "eggs", "honey"]
        case .glutenFree:
            return ["wheat", "barley", "rye", "oats"]
        case .dairyFree:
            return ["milk", "cheese", "yogurt", "butter", "cream"]
        case .kosher:
            return ["pork", "shellfish", "non-kosher meat"]
        case .halal:
            return ["pork", "alcohol", "non-halal meat"]
        }
    }
}

// MARK: - Food Recommendation Models

struct FoodRecommendation: Identifiable, Codable, Equatable {
    let id: UUID
    let foodName: String
    let category: RecommendationCategory
    let nutritionInfo: FoodNutritionInfo
    let reason: String
    let image: String
    var dietaryWarnings: [DietaryWarning]
    var isRecommended: Bool
    var recommendationReason: String?
    
    static func == (lhs: FoodRecommendation, rhs: FoodRecommendation) -> Bool {
        lhs.id == rhs.id
    }
    
    // Helper properties for dietary restrictions
    var containsMeat: Bool {
        let meatKeywords = ["meat", "beef", "chicken", "pork", "lamb", "turkey", "duck", "veal", "bacon", "ham", "sausage"]
        return meatKeywords.contains { foodName.lowercased().contains($0) }
    }
    
    var containsAnimalProducts: Bool {
        let animalProductKeywords = ["meat", "beef", "chicken", "pork", "lamb", "turkey", "duck", "veal", "bacon", "ham", 
                                   "sausage", "milk", "cheese", "cream", "yogurt", "butter", "egg", "honey"]
        return animalProductKeywords.contains { foodName.lowercased().contains($0) }
    }
    
    var containsGluten: Bool {
        let glutenKeywords = ["wheat", "barley", "rye", "bread", "pasta", "flour", "gluten"]
        return glutenKeywords.contains { foodName.lowercased().contains($0) }
    }
    
    var containsDairy: Bool {
        let dairyKeywords = ["milk", "cheese", "cream", "yogurt", "butter", "dairy"]
        return dairyKeywords.contains { foodName.lowercased().contains($0) }
    }
    
    var containsNuts: Bool {
        let nutKeywords = ["nut", "peanut", "almond", "cashew", "walnut", "pecan", "pistachio", "hazelnut"]
        return nutKeywords.contains { foodName.lowercased().contains($0) }
    }
}

enum RecommendationCategory: String, Codable, CaseIterable {
    case all = "All"
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
    case healthyAlternatives = "Healthy Alternatives"
}

// MARK: - Nutrition Models

struct FoodNutritionInfo: Codable, Equatable {
    let foodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let cholesterol: Double?
    let potassium: Double?
    let calcium: Double?
    let iron: Double?
    let vitaminA: Double?
    let vitaminC: Double?
    let servingSize: Double?
    let servingUnit: String?
    let source: NutritionSource?
}

enum NutritionSource: String, Codable {
    case usda = "USDA"
    case userProvided = "User Provided"
    case estimated = "Estimated"
}

// MARK: - Health Warning Models

struct DietaryWarning: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let condition: DietaryCondition
    let warningLevel: WarningLevel
    let message: String
    let suggestedAlternative: String?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DietaryWarning, rhs: DietaryWarning) -> Bool {
        lhs.id == rhs.id
    }
}

enum DietaryCondition: String, Codable {
    case highSugar = "High Sugar"
    case highFat = "High Fat"
    case highSodium = "High Sodium"
    case gluten = "Gluten"
    case dairy = "Dairy"
    case nuts = "Nuts"
    case shellfish = "Shellfish"
}

enum WarningLevel: String, Codable {
    case mild = "Mild"
    case moderate = "Moderate"
    case severe = "Severe"
    case none = "None"
    
    var color: Color {
        switch self {
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        case .none: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .mild: return "exclamationmark.triangle"
        case .moderate: return "exclamationmark.triangle.fill"
        case .severe: return "exclamationmark.octagon.fill"
        case .none: return "checkmark.circle"
        }
    }
}

// MARK: - User Preferences Models

struct UserPreferences: Codable {
    var dietaryPreferences: DietaryPreferences
    var healthGoals: HealthGoals
    var allergies: Allergies
    var updatedAt: Date
    
    static var `default`: UserPreferences {
        UserPreferences(
            dietaryPreferences: DietaryPreferences(
                isVegetarian: false,
                isVegan: false,
                isKeto: false,
                isPaleo: false,
                isGlutenFree: false,
                isDairyFree: false
            ),
            healthGoals: HealthGoals(
                targetWeight: nil,
                targetCalories: 2000,
                targetProtein: 150,
                targetCarbs: 250,
                targetFat: 70
            ),
            allergies: Allergies(
                hasNutAllergy: false,
                hasShellfish: false,
                hasEggs: false,
                hasSoy: false,
                hasDairy: false,
                hasGluten: false,
                otherAllergies: []
            ),
            updatedAt: Date()
        )
    }
}

struct DietaryPreferences: Codable {
    var isVegetarian: Bool
    var isVegan: Bool
    var isKeto: Bool
    var isPaleo: Bool
    var isGlutenFree: Bool
    var isDairyFree: Bool
}

struct HealthGoals: Codable {
    var targetWeight: Double?
    var targetCalories: Int?
    var targetProtein: Int?
    var targetCarbs: Int?
    var targetFat: Int?
}

struct Allergies: Codable {
    var hasNutAllergy: Bool
    var hasShellfish: Bool
    var hasEggs: Bool
    var hasSoy: Bool
    var hasDairy: Bool
    var hasGluten: Bool
    var otherAllergies: [String]
}

// MARK: - User Preferences Manager

class UserPreferencesManager: ObservableObject {
    static let shared = UserPreferencesManager()
    
    @Published var preferences: UserPreferences {
        didSet {
            savePreferences()
        }
    }
    
    private let preferencesKey = "user_preferences"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: preferencesKey),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = decoded
        } else {
            // Default preferences
            self.preferences = UserPreferences(
                dietaryPreferences: DietaryPreferences(
                    isVegetarian: false,
                    isVegan: false,
                    isKeto: false,
                    isPaleo: false,
                    isGlutenFree: false,
                    isDairyFree: false
                ),
                healthGoals: HealthGoals(
                    targetWeight: nil,
                    targetCalories: 2000,
                    targetProtein: 150,
                    targetCarbs: 250,
                    targetFat: 70
                ),
                allergies: Allergies(
                    hasNutAllergy: false,
                    hasShellfish: false,
                    hasEggs: false,
                    hasSoy: false,
                    hasDairy: false,
                    hasGluten: false,
                    otherAllergies: []
                ),
                updatedAt: Date()
            )
        }
    }
    
    private func savePreferences() {
        if let encoded = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(encoded, forKey: preferencesKey)
        }
    }
} 