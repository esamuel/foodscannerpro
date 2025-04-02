import Foundation

public enum BMICategory: String, Codable {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"
}

public enum CholesterolStatus: String, Codable {
    case normal = "Normal"
    case borderline = "Borderline"
    case high = "High"
    case optimal = "Optimal"
}

public struct Cholesterol: Codable, Equatable {
    public var total: Double
    public var hdl: Double
    public var ldl: Double
    
    public var ratio: Double {
        return total / hdl
    }
    
    public var status: CholesterolStatus {
        if total < 5.2 && ldl < 3.4 && hdl > 1.0 {
            return .optimal
        } else if total < 6.2 && ldl < 4.1 && hdl > 1.0 {
            return .borderline
        } else {
            return .high
        }
    }
    
    public init(total: Double = 5.2, hdl: Double = 1.3, ldl: Double = 3.4) {
        self.total = total
        self.hdl = hdl
        self.ldl = ldl
    }
}

public struct AlertPreferences: Codable, Equatable {
    public var alertForSugar: Bool
    public var alertForSodium: Bool
    public var alertForFat: Bool
    public var alertForCalories: Bool
    public var alertForAllergens: Bool
    
    public var sugarThreshold: Double
    public var sodiumThreshold: Double
    public var fatThreshold: Double
    public var calorieThreshold: Double
    
    public init(
        alertForSugar: Bool = true,
        alertForSodium: Bool = true,
        alertForFat: Bool = true,
        alertForCalories: Bool = true,
        alertForAllergens: Bool = true,
        sugarThreshold: Double = 25.0,
        sodiumThreshold: Double = 2300.0,
        fatThreshold: Double = 65.0,
        calorieThreshold: Double = 600.0
    ) {
        self.alertForSugar = alertForSugar
        self.alertForSodium = alertForSodium
        self.alertForFat = alertForFat
        self.alertForCalories = alertForCalories
        self.alertForAllergens = alertForAllergens
        self.sugarThreshold = sugarThreshold
        self.sodiumThreshold = sodiumThreshold
        self.fatThreshold = fatThreshold
        self.calorieThreshold = calorieThreshold
    }
} 