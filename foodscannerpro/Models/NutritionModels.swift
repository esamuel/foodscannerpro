import Foundation

// MARK: - Nutrition Models

/// Represents comprehensive nutrition information for a food item
struct FoodNutritionInfo: Codable, Identifiable {
    var id = UUID()
    let foodName: String
    let calories: Int
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
    let source: NutritionSource
    let timestamp: Date
    
    init(foodName: String, 
         calories: Int, 
         protein: Double, 
         carbs: Double, 
         fat: Double, 
         fiber: Double? = nil, 
         sugar: Double? = nil, 
         sodium: Double? = nil, 
         cholesterol: Double? = nil, 
         potassium: Double? = nil, 
         calcium: Double? = nil, 
         iron: Double? = nil, 
         vitaminA: Double? = nil, 
         vitaminC: Double? = nil, 
         servingSize: Double? = nil, 
         servingUnit: String? = nil, 
         source: NutritionSource,
         timestamp: Date = Date()) {
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.cholesterol = cholesterol
        self.potassium = potassium
        self.calcium = calcium
        self.iron = iron
        self.vitaminA = vitaminA
        self.vitaminC = vitaminC
        self.servingSize = servingSize
        self.servingUnit = servingUnit
        self.source = source
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case foodName, calories, protein, carbs, fat, fiber, sugar, sodium, cholesterol, potassium, calcium, iron, vitaminA, vitaminC, servingSize, servingUnit, source, timestamp
    }
}

/// Represents the source of nutrition data
enum NutritionSource: String, Codable {
    case usda = "USDA"
    case cache = "Cache"
    case fallback = "Fallback"
    case userProvided = "User Provided"
}

// MARK: - USDA API Response Models

/// Root response from USDA API
struct USDAResponse: Codable {
    let foods: [USDAFood]
    let totalHits: Int
    
    enum CodingKeys: String, CodingKey {
        case foods
        case totalHits = "totalHits"
    }
}

/// Food item from USDA API
struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]
    let servingSize: Double?
    let servingSizeUnit: String?
    
    enum CodingKeys: String, CodingKey {
        case fdcId
        case description
        case foodNutrients
        case servingSize
        case servingSizeUnit
    }
}

/// Nutrient from USDA API
struct USDANutrient: Codable {
    let nutrientId: Int
    let nutrientName: String
    let value: Double
    let unitName: String
    
    enum CodingKeys: String, CodingKey {
        case nutrientId
        case nutrientName
        case value
        case unitName
    }
}

// MARK: - Nutrient ID Constants
struct NutrientIDs {
    static let calories = 1008
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

// MARK: - Conversion Extensions

extension FoodNutritionInfo {
    /// Converts FoodNutritionInfo to NutritionInfo
    func toNutritionInfo() -> NutritionInfo {
        // Create vitamins dictionary
        let vitamins: [String: Double] = [
            "A": vitaminA ?? 0.0,
            "C": vitaminC ?? 0.0
        ]
        
        // Create minerals dictionary
        let minerals: [String: Double] = [
            "Calcium": calcium ?? 0.0,
            "Iron": iron ?? 0.0,
            "Potassium": potassium ?? 0.0,
            "Sodium": sodium ?? 0.0
        ]
        
        return NutritionInfo(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fat,
            fiber: fiber,
            sugar: sugar,
            vitamins: vitamins,
            minerals: minerals
        )
    }
} 