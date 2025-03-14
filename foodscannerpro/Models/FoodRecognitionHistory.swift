import Foundation
import CoreData
import UIKit

@objc(FoodRecognitionHistory)
public class FoodRecognitionHistory: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var foodName: String?
    @NSManaged public var confidence: Float
    @NSManaged public var timestamp: Date?
    @NSManaged public var nutritionInfo: NutritionInfoEntity?
    @NSManaged public var warnings: [String]?
    @NSManaged public var isRecommended: Bool
    @NSManaged public var recommendationReason: String?
    @NSManaged public var imageData: Data?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        timestamp = Date()
    }
}

extension FoodRecognitionHistory {
    static func fetchRequest() -> NSFetchRequest<FoodRecognitionHistory> {
        return NSFetchRequest<FoodRecognitionHistory>(entityName: "FoodRecognitionHistory")
    }
}

@objc(NutritionInfoEntity)
public class NutritionInfoEntity: NSManagedObject {
    @NSManaged public var calories: Int32
    @NSManaged public var protein: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fat: Double
    @NSManaged public var fiber: NSNumber?
    @NSManaged public var sugar: NSNumber?
    @NSManaged public var sodium: NSNumber?
    @NSManaged public var cholesterol: NSNumber?
    @NSManaged public var potassium: NSNumber?
    @NSManaged public var calcium: NSNumber?
    @NSManaged public var iron: NSNumber?
    @NSManaged public var vitaminA: NSNumber?
    @NSManaged public var vitaminC: NSNumber?
    @NSManaged public var servingSize: NSNumber?
    @NSManaged public var servingUnit: String?
    @NSManaged public var source: String?
    @NSManaged public var foodRecognition: FoodRecognitionHistory?
}

extension NutritionInfoEntity {
    static func fetchRequest() -> NSFetchRequest<NutritionInfoEntity> {
        return NSFetchRequest<NutritionInfoEntity>(entityName: "NutritionInfoEntity")
    }
} 