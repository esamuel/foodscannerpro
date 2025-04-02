import Foundation
import CoreData
import UIKit

// MARK: - Food Category Enum
public enum FoodCategory: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
    case desserts = "Desserts"
    case beverages = "Beverages"
    case other = "Other"
}

enum MealType: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "cup.and.saucer.fill"
        }
    }
    
    var color: UIColor {
        switch self {
        case .breakfast: return .systemOrange
        case .lunch: return .systemYellow
        case .dinner: return .systemIndigo
        case .snack: return .systemTeal
        }
    }
}

// MARK: - Meal Core Data Class
@objc(Meal)
public class Meal: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var date: Date?
    @NSManaged public var type: String?
    @NSManaged public var notes: String?
    @NSManaged public var foodItems: NSSet?
    
    public var foodItemsArray: [FoodItem] {
        let set = foodItems as? Set<FoodItem> ?? []
        return set.sorted { $0.name ?? "" < $1.name ?? "" }
    }
    
    public var totalCalories: Double {
        foodItemsArray.reduce(0) { $0 + $1.calories }
    }
    
    public var totalProtein: Double {
        foodItemsArray.reduce(0) { $0 + $1.protein }
    }
    
    public var totalCarbs: Double {
        foodItemsArray.reduce(0) { $0 + $1.carbs }
    }
    
    public var totalFats: Double {
        foodItemsArray.reduce(0) { $0 + $1.fats }
    }
    
    var mealTypeEnum: MealType {
        MealType(rawValue: type ?? "Snack") ?? .snack
    }
}

// MARK: - Meal Extension for Core Data
extension Meal {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Meal> {
        return NSFetchRequest<Meal>(entityName: "Meal")
    }
    
    @objc(addFoodItemsObject:)
    @NSManaged public func addToFoodItems(_ value: FoodItem)
    
    @objc(removeFoodItemsObject:)
    @NSManaged public func removeFromFoodItems(_ value: FoodItem)
    
    @objc(addFoodItems:)
    @NSManaged public func addToFoodItems(_ values: NSSet)
    
    @objc(removeFoodItems:)
    @NSManaged public func removeFromFoodItems(_ values: NSSet)
    
    @discardableResult
    static func createSampleMeal(in context: NSManagedObjectContext) -> Meal {
        let meal = Meal(context: context)
        meal.id = UUID()
        meal.name = "Sample Meal"
        meal.date = Date()
        meal.type = MealType.lunch.rawValue
        meal.notes = "This is a sample meal for testing"
        
        // Add some food items
        let apple = FoodItem(context: context)
        apple.id = UUID()
        apple.name = "Apple"
        apple.calories = 95
        apple.protein = 0.5
        apple.carbs = 25
        apple.fats = 0.3
        
        let chicken = FoodItem(context: context)
        chicken.id = UUID()
        chicken.name = "Grilled Chicken Breast"
        chicken.calories = 165
        chicken.protein = 31
        chicken.carbs = 0
        chicken.fats = 3.6
        
        meal.addToFoodItems(apple)
        meal.addToFoodItems(chicken)
        
        try? context.save()
        
        return meal
    }
}

// MARK: - FoodItem Core Data Class
@objc(FoodItem)
public class FoodItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var calories: Double
    @NSManaged public var protein: Double
    @NSManaged public var carbs: Double
    @NSManaged public var fats: Double
    @NSManaged public var image: Data?
    @NSManaged public var dateScanned: Date?
    @NSManaged public var meal: Meal?
    
    public var uiImage: UIImage? {
        if let imageData = image {
            return UIImage(data: imageData)
        }
        return nil
    }
}

// MARK: - FoodItem Extension for Core Data
extension FoodItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FoodItem> {
        return NSFetchRequest<FoodItem>(entityName: "FoodItem")
    }
} 