import CoreData
import UIKit
import Foundation
import SwiftUI

// Import RecognizedFood from ContentView
// This is a temporary fix until we properly organize the code

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleHistory = FoodRecognitionHistory(context: viewContext)
        sampleHistory.id = UUID()
        sampleHistory.foodName = "Apple"
        sampleHistory.confidence = 0.95
        sampleHistory.timestamp = Date()
        sampleHistory.isRecommended = true
        sampleHistory.recommendationReason = "Rich in vitamins and fiber"
        sampleHistory.warnings = []
        
        let sampleNutrition = NutritionInfoEntity(context: viewContext)
        sampleNutrition.calories = 95
        sampleNutrition.protein = 0.5
        sampleNutrition.carbs = 25.0
        sampleNutrition.fat = 0.3
        sampleNutrition.fiber = 4.4
        sampleNutrition.sugar = 19.0
        sampleNutrition.source = "USDA Food Database"
        sampleHistory.nutritionInfo = sampleNutrition
        
        // Add sample meal data
        let breakfast = Meal(context: viewContext)
        breakfast.id = UUID()
        breakfast.name = "Breakfast"
        breakfast.date = Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!
        breakfast.type = "Breakfast"
        breakfast.notes = "Morning meal"
        
        let lunch = Meal(context: viewContext)
        lunch.id = UUID()
        lunch.name = "Lunch"
        lunch.date = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!
        lunch.type = "Lunch"
        
        let dinner = Meal(context: viewContext)
        dinner.id = UUID()
        dinner.name = "Dinner"
        dinner.date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
        dinner.type = "Dinner"
        
        // Add sample food items
        let oatmeal = FoodItem(context: viewContext)
        oatmeal.id = UUID()
        oatmeal.name = "Oatmeal with Berries"
        oatmeal.calories = 350
        oatmeal.protein = 12
        oatmeal.carbs = 60
        oatmeal.fats = 8
        oatmeal.dateScanned = breakfast.date
        oatmeal.meal = breakfast
        
        let salad = FoodItem(context: viewContext)
        salad.id = UUID()
        salad.name = "Chicken Salad"
        salad.calories = 450
        salad.protein = 30
        salad.carbs = 15
        salad.fats = 25
        salad.dateScanned = lunch.date
        salad.meal = lunch
        
        let salmon = FoodItem(context: viewContext)
        salmon.id = UUID()
        salmon.name = "Grilled Salmon with Vegetables"
        salmon.calories = 550
        salmon.protein = 40
        salmon.carbs = 20
        salmon.fats = 30
        salmon.dateScanned = dinner.date
        salmon.meal = dinner
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
    
    let container: NSPersistentCloudKitContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "FoodScannerPro")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Save changes to Core Data
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Add a new food recognition entry
    func addFoodRecognition(food: RecognizedFood, image: UIImage) {
        // This method is temporarily disabled until we resolve the duplicate type issues
        print("Food recognition saving is disabled")
    }
    
    // Delete a food recognition entry
    func deleteFoodRecognition(_ history: FoodRecognitionHistory) {
        container.viewContext.delete(history)
        save()
    }
    
    // Clear all history
    func clearHistory() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = FoodRecognitionHistory.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try container.viewContext.execute(batchDeleteRequest)
            save()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }
    
    // MARK: - Meal Management
    
    // Add a new meal
    func addMeal(name: String, type: String, date: Date, notes: String? = nil) -> Meal {
        let context = container.viewContext
        let meal = Meal(context: context)
        meal.id = UUID()
        meal.name = name
        meal.type = type
        meal.date = date
        meal.notes = notes
        
        save()
        return meal
    }
    
    // Delete a meal
    func deleteMeal(_ meal: Meal) {
        container.viewContext.delete(meal)
        save()
    }
    
    // Update a meal
    func updateMeal(_ meal: Meal, name: String? = nil, type: String? = nil, date: Date? = nil, notes: String? = nil) {
        if let name = name {
            meal.name = name
        }
        
        if let type = type {
            meal.type = type
        }
        
        if let date = date {
            meal.date = date
        }
        
        if let notes = notes {
            meal.notes = notes
        }
        
        save()
    }
    
    // Fetch meals for a specific date
    func fetchMeals(for date: Date) -> [Meal] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: true)]
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals: \(error)")
            return []
        }
    }
    
    // Fetch meals for a date range
    func fetchMeals(from startDate: Date, to endDate: Date) -> [Meal] {
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: true)]
        
        do {
            return try container.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch meals: \(error)")
            return []
        }
    }
    
    // MARK: - Food Item Management
    
    // Add a food item to a meal
    func addFoodItem(to meal: Meal, name: String, calories: Double, protein: Double, carbs: Double, fats: Double, image: UIImage? = nil) -> FoodItem {
        let context = container.viewContext
        let foodItem = FoodItem(context: context)
        foodItem.id = UUID()
        foodItem.name = name
        foodItem.calories = calories
        foodItem.protein = protein
        foodItem.carbs = carbs
        foodItem.fats = fats
        foodItem.dateScanned = Date()
        foodItem.meal = meal
        
        if let image = image {
            foodItem.image = image.jpegData(compressionQuality: 0.8)
        }
        
        save()
        return foodItem
    }
    
    // Delete a food item
    func deleteFoodItem(_ foodItem: FoodItem) {
        container.viewContext.delete(foodItem)
        save()
    }
    
    // Update a food item
    func updateFoodItem(_ foodItem: FoodItem, name: String? = nil, calories: Double? = nil, protein: Double? = nil, carbs: Double? = nil, fats: Double? = nil, image: UIImage? = nil) {
        if let name = name {
            foodItem.name = name
        }
        
        if let calories = calories {
            foodItem.calories = calories
        }
        
        if let protein = protein {
            foodItem.protein = protein
        }
        
        if let carbs = carbs {
            foodItem.carbs = carbs
        }
        
        if let fats = fats {
            foodItem.fats = fats
        }
        
        if let image = image {
            foodItem.image = image.jpegData(compressionQuality: 0.8)
        }
        
        save()
    }
    
    // Convert a recognized food to a food item
    func convertRecognizedFoodToFoodItem(food: RecognizedFood, meal: Meal, image: UIImage? = nil) -> FoodItem {
        let context = container.viewContext
        let foodItem = FoodItem(context: context)
        foodItem.id = UUID()
        foodItem.name = food.name
        
        // Set default nutritional values
        foodItem.calories = 0
        foodItem.protein = 0
        foodItem.carbs = 0
        foodItem.fats = 0
        
        // Update with nutrition values from the recognized food
        let nutrition = food.estimatedNutrition
        foodItem.calories = nutrition.calories
        foodItem.protein = nutrition.protein
        foodItem.carbs = nutrition.carbs
        foodItem.fats = nutrition.fats
        
        foodItem.dateScanned = Date()
        foodItem.meal = meal
        
        if let image = image {
            foodItem.image = image.jpegData(compressionQuality: 0.8)
        }
        
        save()
        return foodItem
    }
} 