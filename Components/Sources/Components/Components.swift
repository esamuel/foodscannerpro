import Foundation
import SwiftUI

// Export all public types
public enum BMICategory: String, Codable {
    case underweight = "Underweight"
    case normal = "Normal"
    case overweight = "Overweight"
    case obese = "Obese"
}

public enum CholesterolStatus: String, Codable {
    case optimal = "Optimal"
    case normal = "Normal"
    case borderline = "Borderline"
    case high = "High"
}

public struct Cholesterol: Codable {
    public var total: Double
    public var hdl: Double
    public var ldl: Double
    public var status: CholesterolStatus
    
    public init(total: Double = 0.0, hdl: Double = 0.0, ldl: Double = 0.0) {
        self.total = total
        self.hdl = hdl
        self.ldl = ldl
        self.status = Self.calculateStatus(total: total, hdl: hdl, ldl: ldl)
    }
    
    private static func calculateStatus(total: Double, hdl: Double, ldl: Double) -> CholesterolStatus {
        if total < 5.2 && ldl < 3.4 && hdl >= 1.0 {
            return .optimal
        } else if total < 6.2 && ldl < 4.1 && hdl >= 1.0 {
            return .normal
        } else if total < 7.2 && ldl < 4.9 {
            return .borderline
        } else {
            return .high
        }
    }
    
    // Implement Codable
    enum CodingKeys: String, CodingKey {
        case total
        case hdl
        case ldl
        case status
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Double.self, forKey: .total)
        hdl = try container.decode(Double.self, forKey: .hdl)
        ldl = try container.decode(Double.self, forKey: .ldl)
        status = try container.decode(CholesterolStatus.self, forKey: .status)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(total, forKey: .total)
        try container.encode(hdl, forKey: .hdl)
        try container.encode(ldl, forKey: .ldl)
        try container.encode(status, forKey: .status)
    }
}

public struct AlertPreferences: Codable {
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
        alertForSugar: Bool = false,
        alertForSodium: Bool = false,
        alertForFat: Bool = false,
        alertForCalories: Bool = false,
        alertForAllergens: Bool = false,
        sugarThreshold: Double = 25.0,
        sodiumThreshold: Double = 2300.0,
        fatThreshold: Double = 65.0,
        calorieThreshold: Double = 2000.0
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