import Foundation
import Combine

class HealthService: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = HealthService()
    
    /// Published properties for UI updates
    @Published var healthProfile: HealthProfile
    @Published var isLoading = false
    @Published var lastError: String?
    
    /// File name for storing health profile
    private let profileFileName = "health_profile.json"
    
    /// Cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default profile
        self.healthProfile = HealthProfile()
        
        // Try to load saved profile
        loadProfileFromDisk()
    }
    
    // MARK: - Profile Management
    
    /// Update the health profile
    func updateProfile(_ profile: HealthProfile) {
        healthProfile = profile
        healthProfile.updatedAt = Date()
        saveProfileToDisk()
    }
    
    /// Add a health condition to the profile
    func addHealthCondition(_ condition: HealthCondition) {
        if !healthProfile.healthConditions.contains(condition) {
            healthProfile.healthConditions.append(condition)
            healthProfile.updatedAt = Date()
            saveProfileToDisk()
        }
    }
    
    /// Remove a health condition from the profile
    func removeHealthCondition(_ condition: HealthCondition) {
        healthProfile.healthConditions.removeAll { $0 == condition }
        healthProfile.updatedAt = Date()
        saveProfileToDisk()
    }
    
    /// Update dietary goal and recalculate targets
    func updateDietaryGoal(_ goal: DietaryGoal) {
        healthProfile.dietaryGoal = goal
        healthProfile.calculateRecommendedCalories()
        healthProfile.updatedAt = Date()
        saveProfileToDisk()
    }
    
    // MARK: - Dietary Analysis
    
    /// Check if a food item has any warnings based on health conditions
    func checkForWarnings(foodName: String, ingredients: [String]? = nil) -> [DietaryWarning] {
        var warnings: [DietaryWarning] = []
        
        // Skip if no health conditions
        if healthProfile.healthConditions.isEmpty || healthProfile.healthConditions.contains(.none) {
            return warnings
        }
        
        // Normalize food name for better matching
        let normalizedFoodName = foodName.lowercased()
        
        // Check each health condition
        for condition in healthProfile.healthConditions {
            // Skip "none" condition
            if condition == .none {
                continue
            }
            
            // Check restricted ingredients against food name
            for restrictedItem in condition.restrictedIngredients {
                if normalizedFoodName.contains(restrictedItem) {
                    // Create warning
                    let message: String
                    let alternative: String?
                    
                    switch condition {
                    case .diabetes:
                        message = "\(foodName) may contain high sugar content, which can affect blood sugar levels."
                        alternative = "Consider sugar-free alternatives or foods with lower glycemic index."
                    case .heartDisease, .highCholesterol:
                        message = "\(foodName) may contain saturated fats or cholesterol, which can affect heart health."
                        alternative = "Consider lean protein sources or plant-based alternatives."
                    case .highBloodPressure:
                        message = "\(foodName) may contain high sodium, which can raise blood pressure."
                        alternative = "Look for low-sodium or sodium-free alternatives."
                    case .celiacDisease, .gluten:
                        message = "\(foodName) may contain gluten, which can trigger digestive issues."
                        alternative = "Consider gluten-free alternatives."
                    case .lactoseIntolerance:
                        message = "\(foodName) may contain lactose, which can cause digestive discomfort."
                        alternative = "Consider lactose-free or plant-based alternatives."
                    case .nutAllergy:
                        message = "\(foodName) may contain nuts or nut traces, which can cause allergic reactions."
                        alternative = "Avoid this food and check for cross-contamination."
                    case .shellfish:
                        message = "\(foodName) may contain shellfish, which can cause allergic reactions."
                        alternative = "Avoid this food and check for cross-contamination."
                    default:
                        message = "\(foodName) may not be suitable for your dietary needs."
                        alternative = nil
                    }
                    
                    let warning = DietaryWarning(
                        foodName: foodName,
                        condition: condition,
                        message: message,
                        suggestedAlternative: alternative
                    )
                    
                    warnings.append(warning)
                    break // Only add one warning per condition
                }
            }
            
            // If ingredients are provided, check them too
            if let ingredients = ingredients {
                for ingredient in ingredients {
                    let normalizedIngredient = ingredient.lowercased()
                    
                    for restrictedItem in condition.restrictedIngredients {
                        if normalizedIngredient.contains(restrictedItem) {
                            // Create warning for ingredient
                            let message = "\(foodName) contains \(ingredient), which may not be suitable for your \(condition.rawValue) condition."
                            let alternative: String?
                            
                            switch condition {
                            case .nutAllergy, .shellfish:
                                alternative = "This food should be avoided completely."
                            default:
                                alternative = "Consider alternatives without \(ingredient)."
                            }
                            
                            let warning = DietaryWarning(
                                foodName: foodName,
                                condition: condition,
                                message: message,
                                suggestedAlternative: alternative
                            )
                            
                            // Only add if not already added for this condition
                            if !warnings.contains(where: { $0.condition == condition }) {
                                warnings.append(warning)
                            }
                            
                            break // Only add one warning per ingredient
                        }
                    }
                }
            }
        }
        
        return warnings
    }
    
    /// Generate personalized food recommendations based on profile
    func generateRecommendations() -> [FoodRecommendation] {
        var recommendations: [FoodRecommendation] = []
        
        // Base recommendations on dietary goal
        let goal = healthProfile.dietaryGoal
        
        // Add recommendations for the goal
        for food in goal.recommendedFoods.prefix(3) {
            let recommendation = FoodRecommendation(
                foodName: food.capitalized,
                reason: "Supports your \(goal.rawValue) goal",
                nutritionalBenefits: getNutritionalBenefits(for: food),
                goal: goal
            )
            recommendations.append(recommendation)
        }
        
        // Add recommendations based on health conditions
        for condition in healthProfile.healthConditions {
            if condition == .none {
                continue
            }
            
            // Get recommended foods for this condition
            let recommendedFoods = getRecommendedFoods(for: condition)
            
            for food in recommendedFoods.prefix(2) {
                let recommendation = FoodRecommendation(
                    foodName: food.capitalized,
                    reason: "Beneficial for \(condition.rawValue)",
                    nutritionalBenefits: getNutritionalBenefits(for: food),
                    goal: goal
                )
                
                // Only add if not already added
                if !recommendations.contains(where: { $0.foodName.lowercased() == food.lowercased() }) {
                    recommendations.append(recommendation)
                }
            }
        }
        
        return recommendations
    }
    
    /// Get recommended foods for a specific health condition
    private func getRecommendedFoods(for condition: HealthCondition) -> [String] {
        switch condition {
        case .diabetes:
            return ["non-starchy vegetables", "whole grains", "lean protein", "nuts", "berries"]
        case .heartDisease, .highCholesterol:
            return ["salmon", "oats", "berries", "nuts", "olive oil", "avocado", "leafy greens"]
        case .highBloodPressure:
            return ["bananas", "leafy greens", "berries", "beets", "yogurt", "oats"]
        case .celiacDisease, .gluten:
            return ["rice", "quinoa", "corn", "potatoes", "gluten-free oats"]
        case .lactoseIntolerance:
            return ["almond milk", "coconut yogurt", "tofu", "leafy greens"]
        case .nutAllergy:
            return ["seeds", "legumes", "lean meats", "fish", "fruits", "vegetables"]
        case .shellfish:
            return ["chicken", "beef", "tofu", "legumes", "eggs"]
        case .none:
            return []
        }
    }
    
    /// Get nutritional benefits for a food
    private func getNutritionalBenefits(for food: String) -> String {
        let normalizedFood = food.lowercased()
        
        // Return specific benefits based on food
        switch normalizedFood {
        case "salmon":
            return "Rich in omega-3 fatty acids, high-quality protein, and vitamin D"
        case "chicken breast", "chicken":
            return "Excellent source of lean protein, low in fat, contains B vitamins"
        case "eggs":
            return "Complete protein with all essential amino acids, vitamin D, and choline"
        case "oats", "oatmeal":
            return "High in soluble fiber, helps lower cholesterol, provides steady energy"
        case "berries", "blueberry", "strawberry":
            return "High in antioxidants, fiber, and vitamin C, low in calories"
        case "leafy greens", "spinach", "kale":
            return "Rich in vitamins A, C, K, folate, iron, and calcium"
        case "nuts", "almonds", "walnuts":
            return "Good source of healthy fats, protein, fiber, and various minerals"
        case "yogurt", "greek yogurt":
            return "High in protein, calcium, probiotics for gut health"
        case "olive oil":
            return "Rich in monounsaturated fats and antioxidants"
        case "avocado":
            return "Contains healthy fats, fiber, potassium, and various nutrients"
        case "quinoa":
            return "Complete protein, rich in fiber, magnesium, and various nutrients"
        case "sweet potato":
            return "High in vitamin A, fiber, and potassium"
        case "lean protein":
            return "Essential for muscle maintenance and repair, helps with satiety"
        case "whole grains":
            return "Provides fiber, B vitamins, and sustained energy"
        case "fruits":
            return "Rich in vitamins, minerals, antioxidants, and fiber"
        case "vegetables":
            return "Low in calories, high in fiber, vitamins, and minerals"
        default:
            return "Provides essential nutrients as part of a balanced diet"
        }
    }
    
    // MARK: - Persistence
    
    private func loadProfileFromDisk() {
        guard let profileURL = getProfileFileURL() else { return }
        
        do {
            if FileManager.default.fileExists(atPath: profileURL.path) {
                let data = try Data(contentsOf: profileURL)
                let decoder = JSONDecoder()
                let profile = try decoder.decode(HealthProfile.self, from: data)
                self.healthProfile = profile
                print("Loaded health profile from disk")
            } else {
                // Create default profile if none exists
                self.healthProfile = HealthProfile()
                self.healthProfile.calculateRecommendedCalories()
                saveProfileToDisk()
                print("Created new default health profile")
            }
        } catch {
            print("Failed to load health profile: \(error.localizedDescription)")
            // If loading fails, start with default profile
            self.healthProfile = HealthProfile()
            self.healthProfile.calculateRecommendedCalories()
        }
    }
    
    private func saveProfileToDisk() {
        guard let profileURL = getProfileFileURL() else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(healthProfile)
            try data.write(to: profileURL)
            print("Saved health profile to disk")
        } catch {
            print("Failed to save health profile: \(error.localizedDescription)")
        }
    }
    
    private func getProfileFileURL() -> URL? {
        do {
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, 
                                                                in: .userDomainMask, 
                                                                appropriateFor: nil, 
                                                                create: true)
            return documentsDirectory.appendingPathComponent(profileFileName)
        } catch {
            print("Failed to get documents directory: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Check if a food is recommended based on health profile
    func isRecommendedFood(_ foodName: String) -> Bool {
        let normalizedName = foodName.lowercased()
        let goal = healthProfile.dietaryGoal
        
        // Check if food is in recommended foods for the goal
        for recommendedFood in goal.recommendedFoods {
            if normalizedName.contains(recommendedFood.lowercased()) {
                return true
            }
        }
        
        // Check if food is recommended for any health conditions
        for condition in healthProfile.healthConditions {
            if condition == .none {
                continue
            }
            
            let recommendedFoods = getRecommendedFoodsForCondition(condition)
            for recommendedFood in recommendedFoods {
                if normalizedName.contains(recommendedFood.lowercased()) {
                    return true
                }
            }
        }
        
        // Check if food is generally nutritious
        let generallyNutritiousFoods = [
            "vegetable", "fruit", "lean protein", "fish", "whole grain", "legume", "bean",
            "lentil", "quinoa", "oat", "berry", "nut", "seed", "olive oil", "avocado"
        ]
        
        for nutritiousFood in generallyNutritiousFoods {
            if normalizedName.contains(nutritiousFood.lowercased()) {
                return true
            }
        }
        
        return false
    }
    
    /// Get recommendation reason for a food
    func getRecommendationReason(_ foodName: String) -> String? {
        if !isRecommendedFood(foodName) {
            return nil
        }
        
        let normalizedName = foodName.lowercased()
        let goal = healthProfile.dietaryGoal
        
        // Check if food is in recommended foods for the goal
        for recommendedFood in goal.recommendedFoods {
            if normalizedName.contains(recommendedFood.lowercased()) {
                return "Supports your \(goal.rawValue) goal"
            }
        }
        
        // Check if food is recommended for any health conditions
        for condition in healthProfile.healthConditions {
            if condition == .none {
                continue
            }
            
            let recommendedFoods = getRecommendedFoodsForCondition(condition)
            for recommendedFood in recommendedFoods {
                if normalizedName.contains(recommendedFood.lowercased()) {
                    return "Beneficial for \(condition.rawValue)"
                }
            }
        }
        
        // Get nutritional benefits
        return getNutritionalBenefits(for: foodName)
    }
    
    /// Get recommended foods for a specific health condition
    private func getRecommendedFoodsForCondition(_ condition: HealthCondition) -> [String] {
        switch condition {
        case .diabetes:
            return ["non-starchy vegetables", "whole grains", "lean protein", "nuts", "berries"]
        case .heartDisease, .highCholesterol:
            return ["salmon", "oats", "berries", "nuts", "olive oil", "avocado", "leafy greens"]
        case .highBloodPressure:
            return ["bananas", "leafy greens", "berries", "beets", "yogurt", "oats"]
        case .celiacDisease, .gluten:
            return ["rice", "quinoa", "corn", "potatoes", "gluten-free oats"]
        case .lactoseIntolerance:
            return ["almond milk", "coconut yogurt", "tofu", "leafy greens"]
        case .nutAllergy:
            return ["seeds", "legumes", "lean meats", "fish", "fruits", "vegetables"]
        case .shellfish:
            return ["chicken", "beef", "tofu", "legumes", "eggs"]
        case .none:
            return []
        }
    }
} 