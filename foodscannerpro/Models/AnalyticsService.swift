import Foundation
import CoreData
import Combine
import SwiftUI

/// Service for analyzing nutrition data and generating insights
class AnalyticsService: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = AnalyticsService()
    
    /// Published properties for UI updates
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var dailyCalorieIntake: [DailyNutritionData] = []
    @Published var macronutrientDistribution: MacronutrientDistribution = MacronutrientDistribution()
    @Published var nutritionTrends: NutritionTrends = NutritionTrends()
    @Published var mealTypeDistribution: [MealTypeData] = []
    @Published var frequentFoods: [FrequentFoodItem] = []
    @Published var healthInsights: [HealthInsight] = []
    
    /// Reference to the health service
    private let healthService = HealthService.shared
    
    /// Cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        // Subscribe to health profile changes
        healthService.$healthProfile
            .sink { [weak self] _ in
                self?.generateHealthInsights()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Analysis
    
    /// Analyze meal history data and update all analytics
    func analyzeData(in context: NSManagedObjectContext) {
        isLoading = true
        
        // Fetch all meals
        let fetchRequest: NSFetchRequest<Meal> = Meal.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Meal.date, ascending: true)]
        
        do {
            let meals = try context.fetch(fetchRequest)
            
            // Process the data
            processDailyCalorieIntake(meals: meals)
            processMacronutrientDistribution(meals: meals)
            processNutritionTrends(meals: meals)
            processMealTypeDistribution(meals: meals)
            processFrequentFoods(meals: meals)
            generateHealthInsights()
            
            isLoading = false
        } catch {
            lastError = "Failed to fetch meal data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Process daily calorie intake data
    private func processDailyCalorieIntake(meals: [Meal]) {
        // Group meals by day
        let calendar = Calendar.current
        var dailyData: [Date: DailyNutritionData] = [:]
        
        for meal in meals {
            guard let date = meal.date else { continue }
            
            // Get date components for grouping by day
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let dayDate = calendar.date(from: components) else { continue }
            
            // Initialize or update daily data
            var dayData = dailyData[dayDate] ?? DailyNutritionData(date: dayDate)
            
            // Sum up nutrition from all food items in the meal
            let foodItems = meal.foodItems as? Set<FoodItem> ?? []
            for food in foodItems {
                dayData.calories += food.calories
                dayData.protein += food.protein
                dayData.carbs += food.carbs
                dayData.fats += food.fats
            }
            
            dailyData[dayDate] = dayData
        }
        
        // Convert dictionary to sorted array
        dailyCalorieIntake = dailyData.values.sorted { $0.date < $1.date }
        
        // Calculate 7-day moving average
        if dailyCalorieIntake.count > 7 {
            for i in 7..<dailyCalorieIntake.count {
                let weekSum = dailyCalorieIntake[(i-7)..<i].reduce(0) { $0 + $1.calories }
                dailyCalorieIntake[i].caloriesMovingAverage = weekSum / 7
            }
        }
    }
    
    /// Process macronutrient distribution data
    private func processMacronutrientDistribution(meals: [Meal]) {
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFats: Double = 0
        var totalCalories: Double = 0
        
        // Sum up all macronutrients
        for meal in meals {
            let foodItems = meal.foodItems as? Set<FoodItem> ?? []
            for food in foodItems {
                totalProtein += food.protein
                totalCarbs += food.carbs
                totalFats += food.fats
                totalCalories += food.calories
            }
        }
        
        // Calculate percentages
        let proteinCalories = totalProtein * 4 // 4 calories per gram of protein
        let carbCalories = totalCarbs * 4 // 4 calories per gram of carbs
        let fatCalories = totalFats * 9 // 9 calories per gram of fat
        
        // Update macronutrient distribution
        macronutrientDistribution = MacronutrientDistribution(
            proteinPercentage: totalCalories > 0 ? (proteinCalories / totalCalories) * 100 : 0,
            carbsPercentage: totalCalories > 0 ? (carbCalories / totalCalories) * 100 : 0,
            fatsPercentage: totalCalories > 0 ? (fatCalories / totalCalories) * 100 : 0,
            totalProtein: totalProtein,
            totalCarbs: totalCarbs,
            totalFats: totalFats
        )
    }
    
    /// Process nutrition trends over time
    private func processNutritionTrends(meals: [Meal]) {
        // Group meals by week
        let calendar = Calendar.current
        var weeklyData: [Date: WeeklyNutritionData] = [:]
        
        for meal in meals {
            guard let date = meal.date else { continue }
            
            // Get week start date
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
            guard let weekStart = calendar.date(from: components) else { continue }
            
            // Initialize or update weekly data
            var weekData = weeklyData[weekStart] ?? WeeklyNutritionData(weekStartDate: weekStart)
            
            // Sum up nutrition from all food items in the meal
            let foodItems = meal.foodItems as? Set<FoodItem> ?? []
            for food in foodItems {
                weekData.totalCalories += food.calories
                weekData.totalProtein += food.protein
                weekData.totalCarbs += food.carbs
                weekData.totalFats += food.fats
                weekData.mealCount += 1
                weekData.foodItemCount += 1
            }
            
            weeklyData[weekStart] = weekData
        }
        
        // Convert dictionary to sorted array
        let sortedWeeklyData = weeklyData.values.sorted { $0.weekStartDate < $1.weekStartDate }
        
        // Calculate trends
        if sortedWeeklyData.count >= 2 {
            let firstWeek = sortedWeeklyData.first!
            let lastWeek = sortedWeeklyData.last!
            
            // Calculate percentage changes
            let calorieChange = calculatePercentageChange(from: firstWeek.totalCalories, to: lastWeek.totalCalories)
            let proteinChange = calculatePercentageChange(from: firstWeek.totalProtein, to: lastWeek.totalProtein)
            let carbsChange = calculatePercentageChange(from: firstWeek.totalCarbs, to: lastWeek.totalCarbs)
            let fatsChange = calculatePercentageChange(from: firstWeek.totalFats, to: lastWeek.totalFats)
            
            // Update nutrition trends
            nutritionTrends = NutritionTrends(
                caloriesTrend: calorieChange,
                proteinTrend: proteinChange,
                carbsTrend: carbsChange,
                fatsTrend: fatsChange,
                weeklyData: sortedWeeklyData
            )
        }
    }
    
    /// Process meal type distribution
    private func processMealTypeDistribution(meals: [Meal]) {
        var mealTypes: [String: MealTypeData] = [:]
        
        for meal in meals {
            let type = meal.type ?? "Other"
            
            // Initialize or update meal type data
            var typeData = mealTypes[type] ?? MealTypeData(type: type, count: 0, totalCalories: 0)
            typeData.count += 1
            
            // Sum up calories from all food items in the meal
            let foodItems = meal.foodItems as? Set<FoodItem> ?? []
            for food in foodItems {
                typeData.totalCalories += food.calories
            }
            
            mealTypes[type] = typeData
        }
        
        // Convert dictionary to array and sort by count
        mealTypeDistribution = mealTypes.values.sorted { $0.count > $1.count }
    }
    
    /// Process frequent foods data
    private func processFrequentFoods(meals: [Meal]) {
        var foodCounts: [String: FrequentFoodItem] = [:]
        
        for meal in meals {
            let foodItems = meal.foodItems as? Set<FoodItem> ?? []
            for food in foodItems {
                guard let name = food.name else { continue }
                
                // Initialize or update food count
                var foodData = foodCounts[name] ?? FrequentFoodItem(name: name, count: 0, averageCalories: 0)
                foodData.count += 1
                
                // Update running average of calories
                foodData.totalCalories += food.calories
                foodData.averageCalories = foodData.totalCalories / Double(foodData.count)
                
                foodCounts[name] = foodData
            }
        }
        
        // Convert dictionary to array and sort by count
        frequentFoods = foodCounts.values.sorted { $0.count > $1.count }
    }
    
    /// Generate health insights based on nutrition data and health profile
    func generateHealthInsights() {
        var insights: [HealthInsight] = []
        
        // Get health profile
        let profile = healthService.healthProfile
        
        // Check if daily calorie intake matches target
        if !dailyCalorieIntake.isEmpty {
            let recentDays = min(dailyCalorieIntake.count, 7)
            let recentIntake = dailyCalorieIntake.suffix(recentDays)
            let averageCalories = recentIntake.reduce(0) { $0 + $1.calories } / Double(recentDays)
            
            let calorieTarget = Double(profile.dailyCalorieTarget)
            let caloriePercentage = (averageCalories / calorieTarget) * 100
            
            if caloriePercentage < 80 {
                insights.append(HealthInsight(
                    title: "Low Calorie Intake",
                    description: "Your average calorie intake is significantly below your target. Consider adding more nutrient-dense foods to your diet.",
                    type: .warning
                ))
            } else if caloriePercentage > 120 {
                insights.append(HealthInsight(
                    title: "High Calorie Intake",
                    description: "Your average calorie intake is significantly above your target. Consider portion control and choosing lower-calorie options.",
                    type: .warning
                ))
            } else {
                insights.append(HealthInsight(
                    title: "Balanced Calorie Intake",
                    description: "Your average calorie intake is well-aligned with your target. Keep up the good work!",
                    type: .positive
                ))
            }
        }
        
        // Check macronutrient balance
        if macronutrientDistribution.proteinPercentage > 0 {
            // Protein check
            let proteinTarget = Double(profile.dailyProteinTarget)
            let proteinAverage = macronutrientDistribution.totalProtein / Double(max(dailyCalorieIntake.count, 1))
            
            if proteinAverage < proteinTarget * 0.8 {
                insights.append(HealthInsight(
                    title: "Low Protein Intake",
                    description: "Your protein intake is below your target. Consider adding more lean protein sources like chicken, fish, or legumes.",
                    type: .suggestion
                ))
            }
            
            // Carbs check based on dietary goal
            switch profile.dietaryGoal {
            case .lowCarb:
                if macronutrientDistribution.carbsPercentage > 30 {
                    insights.append(HealthInsight(
                        title: "High Carb Intake for Low-Carb Goal",
                        description: "Your carbohydrate intake is higher than recommended for your low-carb goal. Consider reducing starchy foods and sugars.",
                        type: .warning
                    ))
                }
            case .highProtein:
                if macronutrientDistribution.proteinPercentage < 25 {
                    insights.append(HealthInsight(
                        title: "Low Protein for High-Protein Goal",
                        description: "Your protein intake is lower than recommended for your high-protein goal. Consider adding more protein-rich foods.",
                        type: .suggestion
                    ))
                }
            default:
                break
            }
        }
        
        // Check for health condition specific insights
        for condition in profile.healthConditions {
            switch condition {
            case .diabetes:
                insights.append(HealthInsight(
                    title: "Diabetes Management",
                    description: "Track your carbohydrate intake carefully and aim for consistent meal timing to help manage blood sugar levels.",
                    type: .information
                ))
            case .heartDisease, .highCholesterol:
                insights.append(HealthInsight(
                    title: "Heart Health",
                    description: "Focus on reducing saturated fats and increasing fiber intake through fruits, vegetables, and whole grains.",
                    type: .information
                ))
            case .highBloodPressure:
                insights.append(HealthInsight(
                    title: "Blood Pressure Management",
                    description: "Monitor your sodium intake and aim for foods rich in potassium, calcium, and magnesium.",
                    type: .information
                ))
            default:
                break
            }
        }
        
        // Add general insights based on frequent foods
        if !frequentFoods.isEmpty {
            let topFoods = frequentFoods.prefix(3).map { $0.name }.joined(separator: ", ")
            insights.append(HealthInsight(
                title: "Frequent Foods",
                description: "Your most frequently consumed foods are: \(topFoods). Consider adding variety to ensure a wide range of nutrients.",
                type: .information
            ))
        }
        
        // Update published property
        healthInsights = insights
    }
    
    // MARK: - Helper Methods
    
    /// Calculate percentage change between two values
    private func calculatePercentageChange(from startValue: Double, to endValue: Double) -> Double {
        guard startValue > 0 else { return 0 }
        return ((endValue - startValue) / startValue) * 100
    }
    
    /// Get color for trend value
    func getTrendColor(value: Double) -> Color {
        if value > 10 {
            return .red
        } else if value < -10 {
            return .green
        } else {
            return .blue
        }
    }
    
    /// Get formatted trend string
    func getFormattedTrend(value: Double) -> String {
        if value > 0 {
            return "+\(String(format: "%.1f", value))%"
        } else {
            return "\(String(format: "%.1f", value))%"
        }
    }
    
    /// Get data for specific date range
    func getDataForRange(_ range: DateRange) -> [DailyNutritionData] {
        let calendar = Calendar.current
        let today = Date()
        
        switch range {
        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: today)!
            return dailyCalorieIntake.filter { $0.date >= startDate }
        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: today)!
            return dailyCalorieIntake.filter { $0.date >= startDate }
        case .threeMonths:
            let startDate = calendar.date(byAdding: .month, value: -3, to: today)!
            return dailyCalorieIntake.filter { $0.date >= startDate }
        case .sixMonths:
            let startDate = calendar.date(byAdding: .month, value: -6, to: today)!
            return dailyCalorieIntake.filter { $0.date >= startDate }
        case .year:
            let startDate = calendar.date(byAdding: .year, value: -1, to: today)!
            return dailyCalorieIntake.filter { $0.date >= startDate }
        case .all:
            return dailyCalorieIntake
        }
    }
}

// MARK: - Data Models

/// Represents daily nutrition data
struct DailyNutritionData: Identifiable {
    let id = UUID()
    let date: Date
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fats: Double = 0
    var caloriesMovingAverage: Double?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

/// Represents macronutrient distribution
struct MacronutrientDistribution {
    var proteinPercentage: Double = 0
    var carbsPercentage: Double = 0
    var fatsPercentage: Double = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFats: Double = 0
}

/// Represents weekly nutrition data
struct WeeklyNutritionData: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    var totalCalories: Double = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFats: Double = 0
    var mealCount: Int = 0
    var foodItemCount: Int = 0
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: weekStartDate)
    }
}

/// Represents nutrition trends over time
struct NutritionTrends {
    var caloriesTrend: Double = 0
    var proteinTrend: Double = 0
    var carbsTrend: Double = 0
    var fatsTrend: Double = 0
    var weeklyData: [WeeklyNutritionData] = []
}

/// Represents meal type distribution data
struct MealTypeData: Identifiable {
    let id = UUID()
    let type: String
    var count: Int
    var totalCalories: Double
    
    var averageCalories: Double {
        return count > 0 ? totalCalories / Double(count) : 0
    }
}

/// Represents a frequent food item
struct FrequentFoodItem: Identifiable {
    let id = UUID()
    let name: String
    var count: Int
    var totalCalories: Double = 0
    var averageCalories: Double
}

/// Represents a health insight
struct HealthInsight: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: InsightType
    let date: Date = Date()
    
    enum InsightType {
        case positive
        case warning
        case suggestion
        case information
        
        var color: Color {
            switch self {
            case .positive:
                return .green
            case .warning:
                return .red
            case .suggestion:
                return .orange
            case .information:
                return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .positive:
                return "checkmark.circle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .suggestion:
                return "lightbulb.fill"
            case .information:
                return "info.circle.fill"
            }
        }
    }
}

/// Date range for filtering data
enum DateRange: String, CaseIterable, Identifiable {
    case week = "Last Week"
    case month = "Last Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case year = "Last Year"
    case all = "All Time"
    
    var id: String { self.rawValue }
} 