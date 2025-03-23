import Foundation
import CoreData

struct FeaturedMeal: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let type: MealType
    let calories: Double
    let protein: Double
    let carbs: Double
    let fats: Double
    let ingredients: [String]
    let preparationSteps: [String]
    let imageUrl: String
    let category: FeaturedCategory
}

enum FeaturedCategory: String, CaseIterable {
    case healthyBreakfast = "Healthy Breakfast"
    case mediterraneanDiet = "Mediterranean Diet"
    case proteinRich = "Protein-Rich Meals"
    
    var description: String {
        switch self {
        case .healthyBreakfast:
            return "Start your day with nutritious and energizing meals"
        case .mediterraneanDiet:
            return "Heart-healthy choices inspired by Mediterranean cuisine"
        case .proteinRich:
            return "High-protein meals for muscle building and recovery"
        }
    }
    
    var iconName: String {
        switch self {
        case .healthyBreakfast:
            return "sunrise.fill"
        case .mediterraneanDiet:
            return "leaf.fill"
        case .proteinRich:
            return "figure.strengthtraining.traditional"
        }
    }
    
    var imageName: String {
        switch self {
        case .healthyBreakfast:
            return "healthy_breakfast"
        case .mediterraneanDiet:
            return "mediterranean_diet"
        case .proteinRich:
            return "protein_rich"
        }
    }
}

class FeaturedMealsManager {
    static let shared = FeaturedMealsManager()
    
    let healthyBreakfasts: [FeaturedMeal] = [
        FeaturedMeal(name: "Greek Yogurt Parfait", description: "Layered with fresh berries and honey", type: .breakfast, calories: 320, protein: 15, carbs: 45, fats: 8, ingredients: ["Greek yogurt", "Mixed berries", "Honey", "Granola"], preparationSteps: [
            "In a serving glass, start with a layer of Greek yogurt",
            "Add a layer of mixed berries",
            "Drizzle with honey",
            "Add another layer of yogurt",
            "Top with granola and remaining berries",
            "Finish with a final drizzle of honey"
        ], imageUrl: "greek_yogurt_parfait", category: .healthyBreakfast),
        FeaturedMeal(name: "Avocado Toast", description: "Whole grain toast with mashed avocado and eggs", type: .breakfast, calories: 380, protein: 18, carbs: 35, fats: 22, ingredients: ["Whole grain bread", "Avocado", "Eggs", "Cherry tomatoes"], preparationSteps: [], imageUrl: "avocado_toast", category: .healthyBreakfast),
        FeaturedMeal(name: "Oatmeal Bowl", description: "Steel-cut oats with nuts and fruits", type: .breakfast, calories: 290, protein: 12, carbs: 48, fats: 9, ingredients: ["Steel-cut oats", "Almonds", "Banana", "Cinnamon"], preparationSteps: [], imageUrl: "oatmeal_bowl", category: .healthyBreakfast),
        FeaturedMeal(name: "Smoothie Bowl", description: "Antioxidant-rich smoothie with toppings", type: .breakfast, calories: 340, protein: 14, carbs: 52, fats: 10, ingredients: ["Mixed berries", "Banana", "Greek yogurt", "Chia seeds"], preparationSteps: [], imageUrl: "smoothie_bowl", category: .healthyBreakfast),
        FeaturedMeal(name: "Protein Pancakes", description: "Fluffy pancakes with protein powder", type: .breakfast, calories: 420, protein: 28, carbs: 48, fats: 12, ingredients: ["Protein powder", "Oats", "Egg whites", "Maple syrup"], preparationSteps: [], imageUrl: "protein_pancakes", category: .healthyBreakfast),
        FeaturedMeal(name: "Veggie Frittata", description: "Egg-based dish with vegetables", type: .breakfast, calories: 310, protein: 22, carbs: 12, fats: 20, ingredients: ["Eggs", "Spinach", "Bell peppers", "Feta cheese"], preparationSteps: [], imageUrl: "veggie_frittata", category: .healthyBreakfast),
        FeaturedMeal(name: "Chia Pudding", description: "Overnight chia seed pudding", type: .breakfast, calories: 280, protein: 10, carbs: 38, fats: 14, ingredients: ["Chia seeds", "Almond milk", "Honey", "Fresh fruits"], preparationSteps: [], imageUrl: "chia_pudding", category: .healthyBreakfast),
        FeaturedMeal(name: "Breakfast Burrito", description: "Healthy wrap with eggs and veggies", type: .breakfast, calories: 450, protein: 24, carbs: 42, fats: 22, ingredients: ["Whole wheat tortilla", "Eggs", "Black beans", "Avocado"], preparationSteps: [], imageUrl: "breakfast_burrito", category: .healthyBreakfast),
        FeaturedMeal(name: "Quinoa Breakfast Bowl", description: "Warm quinoa with fruits and nuts", type: .breakfast, calories: 360, protein: 16, carbs: 54, fats: 12, ingredients: ["Quinoa", "Almond milk", "Mixed berries", "Pecans"], preparationSteps: [], imageUrl: "quinoa_breakfast", category: .healthyBreakfast),
        FeaturedMeal(name: "Toast with Cottage Cheese", description: "High-protein breakfast toast", type: .breakfast, calories: 290, protein: 20, carbs: 32, fats: 8, ingredients: ["Whole grain bread", "Cottage cheese", "Cucumber", "Herbs"], preparationSteps: [], imageUrl: "cottage_cheese_toast", category: .healthyBreakfast)
    ]
    
    let mediterraneanMeals: [FeaturedMeal] = [
        FeaturedMeal(name: "Greek Salad", description: "Classic Mediterranean salad", type: .lunch, calories: 320, protein: 12, carbs: 18, fats: 24, ingredients: ["Tomatoes", "Cucumber", "Olives", "Feta cheese"], preparationSteps: [], imageUrl: "greek_salad", category: .mediterraneanDiet),
        FeaturedMeal(name: "Grilled Fish", description: "Fresh fish with herbs and lemon", type: .dinner, calories: 380, protein: 42, carbs: 8, fats: 18, ingredients: ["Sea bass", "Olive oil", "Lemon", "Mediterranean herbs"], preparationSteps: [], imageUrl: "grilled_fish", category: .mediterraneanDiet),
        FeaturedMeal(name: "Hummus Plate", description: "Chickpea hummus with vegetables", type: .lunch, calories: 420, protein: 15, carbs: 48, fats: 22, ingredients: ["Chickpeas", "Tahini", "Olive oil", "Pita bread"], preparationSteps: [], imageUrl: "hummus_plate", category: .mediterraneanDiet),
        FeaturedMeal(name: "Ratatouille", description: "French Provençal stewed vegetables", type: .dinner, calories: 280, protein: 8, carbs: 32, fats: 16, ingredients: ["Eggplant", "Zucchini", "Tomatoes", "Bell peppers"], preparationSteps: [], imageUrl: "ratatouille", category: .mediterraneanDiet),
        FeaturedMeal(name: "Mediterranean Pasta", description: "Whole grain pasta with vegetables", type: .dinner, calories: 450, protein: 16, carbs: 68, fats: 14, ingredients: ["Whole grain pasta", "Cherry tomatoes", "Olives", "Fresh basil"], preparationSteps: [], imageUrl: "mediterranean_pasta", category: .mediterraneanDiet),
        FeaturedMeal(name: "Falafel Wrap", description: "Chickpea patties in pita bread", type: .lunch, calories: 520, protein: 18, carbs: 62, fats: 24, ingredients: ["Chickpeas", "Herbs", "Pita bread", "Tahini sauce"], preparationSteps: [], imageUrl: "falafel_wrap", category: .mediterraneanDiet),
        FeaturedMeal(name: "Seafood Paella", description: "Spanish rice dish with seafood", type: .dinner, calories: 580, protein: 32, carbs: 72, fats: 18, ingredients: ["Rice", "Mixed seafood", "Saffron", "Bell peppers"], preparationSteps: [], imageUrl: "seafood_paella", category: .mediterraneanDiet),
        FeaturedMeal(name: "Tabbouleh", description: "Bulgur wheat and herb salad", type: .lunch, calories: 260, protein: 8, carbs: 46, fats: 8, ingredients: ["Bulgur", "Parsley", "Tomatoes", "Mint"], preparationSteps: [], imageUrl: "tabbouleh", category: .mediterraneanDiet),
        FeaturedMeal(name: "Stuffed Peppers", description: "Bell peppers with rice and herbs", type: .dinner, calories: 340, protein: 12, carbs: 48, fats: 14, ingredients: ["Bell peppers", "Rice", "Pine nuts", "Mediterranean herbs"], preparationSteps: [], imageUrl: "stuffed_peppers", category: .mediterraneanDiet),
        FeaturedMeal(name: "Shakshuka", description: "Eggs poached in tomato sauce", type: .breakfast, calories: 380, protein: 22, carbs: 24, fats: 24, ingredients: ["Eggs", "Tomatoes", "Bell peppers", "Feta cheese"], preparationSteps: [], imageUrl: "shakshuka", category: .mediterraneanDiet)
    ]
    
    let proteinRichMeals: [FeaturedMeal] = [
        FeaturedMeal(name: "Grilled Chicken Breast", description: "Lean protein with vegetables", type: .dinner, calories: 420, protein: 48, carbs: 12, fats: 18, ingredients: ["Chicken breast", "Broccoli", "Sweet potato", "Olive oil"], preparationSteps: [], imageUrl: "grilled_chicken", category: .proteinRich),
        FeaturedMeal(name: "Salmon Bowl", description: "Fresh salmon with quinoa", type: .lunch, calories: 520, protein: 42, carbs: 38, fats: 24, ingredients: ["Salmon", "Quinoa", "Avocado", "Mixed greens"], preparationSteps: [], imageUrl: "salmon_bowl", category: .proteinRich),
        FeaturedMeal(name: "Turkey Meatballs", description: "Lean turkey with whole grain pasta", type: .dinner, calories: 480, protein: 38, carbs: 42, fats: 20, ingredients: ["Ground turkey", "Whole grain pasta", "Marinara sauce", "Parmesan"], preparationSteps: [], imageUrl: "turkey_meatballs", category: .proteinRich),
        FeaturedMeal(name: "Lentil Curry", description: "Plant-based protein curry", type: .dinner, calories: 440, protein: 24, carbs: 62, fats: 12, ingredients: ["Red lentils", "Coconut milk", "Spinach", "Brown rice"], preparationSteps: [], imageUrl: "lentil_curry", category: .proteinRich),
        FeaturedMeal(name: "Tuna Steak", description: "Seared tuna with vegetables", type: .dinner, calories: 380, protein: 44, carbs: 14, fats: 16, ingredients: ["Tuna steak", "Asparagus", "Quinoa", "Lemon"], preparationSteps: [], imageUrl: "tuna_steak", category: .proteinRich),
        FeaturedMeal(name: "Protein Power Bowl", description: "Mixed protein sources bowl", type: .lunch, calories: 550, protein: 40, carbs: 48, fats: 22, ingredients: ["Chicken", "Chickpeas", "Quinoa", "Edamame"], preparationSteps: [], imageUrl: "protein_bowl", category: .proteinRich),
        FeaturedMeal(name: "Tofu Stir-Fry", description: "Plant-based protein stir-fry", type: .dinner, calories: 420, protein: 28, carbs: 38, fats: 20, ingredients: ["Tofu", "Mixed vegetables", "Brown rice", "Soy sauce"], preparationSteps: [], imageUrl: "tofu_stirfry", category: .proteinRich),
        FeaturedMeal(name: "Greek Yogurt Bowl", description: "High-protein breakfast bowl", type: .breakfast, calories: 340, protein: 24, carbs: 42, fats: 8, ingredients: ["Greek yogurt", "Protein granola", "Berries", "Honey"], preparationSteps: [], imageUrl: "yogurt_bowl", category: .proteinRich),
        FeaturedMeal(name: "Egg White Omelette", description: "Low-fat high-protein breakfast", type: .breakfast, calories: 280, protein: 32, carbs: 8, fats: 12, ingredients: ["Egg whites", "Spinach", "Turkey breast", "Low-fat cheese"], preparationSteps: [], imageUrl: "egg_white_omelette", category: .proteinRich),
        FeaturedMeal(name: "Shrimp Skewers", description: "Grilled shrimp with vegetables", type: .dinner, calories: 320, protein: 36, carbs: 18, fats: 14, ingredients: ["Shrimp", "Bell peppers", "Zucchini", "Brown rice"], preparationSteps: [], imageUrl: "shrimp_skewers", category: .proteinRich)
    ]
    
    func getMealsForCategory(_ category: FeaturedCategory) -> [FeaturedMeal] {
        switch category {
        case .healthyBreakfast:
            return healthyBreakfasts
        case .mediterraneanDiet:
            return mediterraneanMeals
        case .proteinRich:
            return proteinRichMeals
        }
    }
} 