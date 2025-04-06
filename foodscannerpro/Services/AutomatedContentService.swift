import Foundation
import UIKit
import CoreML

class AutomatedContentService: ObservableObject {
    static let shared = AutomatedContentService()
    
    // MARK: - Properties
    private let edamamAPIKey = "YOUR_EDAMAM_API_KEY" // You'll need to get this
    private let spoonacularAPIKey = "YOUR_SPOONACULAR_API_KEY" // You'll need to get this
    private let unsplashAPIKey = "YOUR_UNSPLASH_API_KEY" // For food images
    
    // MARK: - Food Data Fetching
    
    /// Automatically fetch and generate food recommendations based on health profile
    func generateAutomatedRecommendations(for profile: HealthProfile) async throws -> [FoodRecommendation] {
        var recommendations: [FoodRecommendation] = []
        
        // Build API query parameters based on health profile
        let queryParams = buildQueryParameters(from: profile)
        
        // Fetch recipes from Edamam API
        let edamamRecipes = try await fetchEdamamRecipes(with: queryParams)
        recommendations += edamamRecipes
        
        // Fetch recipes from Spoonacular API as backup
        let spoonacularRecipes = try await fetchSpoonacularRecipes(with: queryParams)
        recommendations += spoonacularRecipes
        
        return recommendations
    }
    
    private func buildQueryParameters(from profile: HealthProfile) -> [String: String] {
        var params: [String: String] = [:]
        
        // Add dietary restrictions
        for restriction in profile.dietaryRestrictions {
            switch restriction {
            case .vegetarian:
                params["diet"] = "vegetarian"
            case .vegan:
                params["diet"] = "vegan"
            case .glutenFree:
                params["health"] = "gluten-free"
            case .dairyFree:
                params["health"] = "dairy-free"
            case .kosher:
                params["health"] = "kosher"
            case .halal:
                params["health"] = "halal"
            }
        }
        
        // Add health conditions
        for condition in profile.healthConditions {
            switch condition {
            case .diabetes:
                params["health"] = "sugar-conscious"
                params["glycemicIndex"] = "low"
            case .heartDisease, .highCholesterol:
                params["health"] = "low-fat"
                params["nutrients[cholesterol]"] = "0-50"
            case .highBloodPressure:
                params["nutrients[sodium]"] = "0-500"
            default:
                break
            }
        }
        
        // Add dietary goals
        switch profile.dietaryGoal {
        case .weightLoss:
            params["calories"] = "0-500"
            params["diet"] = "low-fat"
        case .muscleGain:
            params["nutrients[protein]"] = "25-100"
        case .lowCarb:
            params["nutrients[carbs]"] = "0-30"
        case .highProtein:
            params["nutrients[protein]"] = "25-100"
        default:
            break
        }
        
        return params
    }
    
    // MARK: - API Calls
    
    private func fetchEdamamRecipes(with params: [String: String]) async throws -> [FoodRecommendation] {
        let baseURL = "https://api.edamam.com/api/recipes/v2"
        var urlComponents = URLComponents(string: baseURL)!
        
        // Add API credentials
        var queryItems = [
            URLQueryItem(name: "app_id", value: "YOUR_APP_ID"),
            URLQueryItem(name: "app_key", value: edamamAPIKey)
        ]
        
        // Add search parameters
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        urlComponents.queryItems = queryItems
        
        let (data, _) = try await URLSession.shared.data(from: urlComponents.url!)
        let recipes = try JSONDecoder().decode(EdamamResponse.self, from: data)
        
        return try await convertEdamamToRecommendations(recipes.hits)
    }
    
    private func fetchSpoonacularRecipes(with params: [String: String]) async throws -> [FoodRecommendation] {
        let baseURL = "https://api.spoonacular.com/recipes/complexSearch"
        var urlComponents = URLComponents(string: baseURL)!
        
        // Add API key
        var queryItems = [URLQueryItem(name: "apiKey", value: spoonacularAPIKey)]
        
        // Convert Edamam params to Spoonacular format
        let spoonacularParams = convertToSpoonacularParams(params)
        for (key, value) in spoonacularParams {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        urlComponents.queryItems = queryItems
        
        let (data, _) = try await URLSession.shared.data(from: urlComponents.url!)
        let recipes = try JSONDecoder().decode(SpoonacularResponse.self, from: data)
        
        return try await convertSpoonacularToRecommendations(recipes.results)
    }
    
    // MARK: - Image Fetching
    
    private func convertEdamamToRecommendations(_ recipes: [EdamamRecipe]) async throws -> [FoodRecommendation] {
        var recommendations: [FoodRecommendation] = []
        
        for recipe in recipes {
            // Instead of fetching the image, we'll store the URL
            let imageURL = try? await getImageURL(for: recipe.label)
            
            // Create recommendation
            let recommendation = FoodRecommendation(
                id: UUID(),
                foodName: recipe.label,
                category: determineCategory(for: recipe),
                nutritionInfo: FoodNutritionInfo(
                    foodName: recipe.label,
                    calories: recipe.nutrients.calories,
                    protein: recipe.nutrients.protein,
                    carbs: recipe.nutrients.carbs,
                    fat: recipe.nutrients.fat,
                    fiber: recipe.nutrients.fiber,
                    sugar: recipe.nutrients.sugar,
                    sodium: recipe.nutrients.sodium,
                    cholesterol: recipe.nutrients.cholesterol,
                    potassium: nil,
                    calcium: nil,
                    iron: nil,
                    vitaminA: nil,
                    vitaminC: nil,
                    servingSize: recipe.yield,
                    servingUnit: "serving",
                    source: .estimated
                ),
                reason: generateReason(for: recipe),
                image: imageURL ?? "",  // Store the URL as a string
                dietaryWarnings: [],
                isRecommended: true,
                recommendationReason: generateReason(for: recipe)
            )
            
            recommendations.append(recommendation)
        }
        
        return recommendations
    }
    
    // New method to get image URL instead of downloading the image
    private func getImageURL(for foodName: String) async throws -> String? {
        let baseURL = "https://api.unsplash.com/search/photos"
        var urlComponents = URLComponents(string: baseURL)!
        
        let queryItems = [
            URLQueryItem(name: "query", value: "\(foodName) food"),
            URLQueryItem(name: "client_id", value: unsplashAPIKey),
            URLQueryItem(name: "orientation", value: "squarish"),
            URLQueryItem(name: "per_page", value: "1")
        ]
        
        urlComponents.queryItems = queryItems
        
        let (data, _) = try await URLSession.shared.data(from: urlComponents.url!)
        let response = try JSONDecoder().decode(UnsplashResponse.self, from: data)
        
        return response.results.first?.urls.regular
    }
    
    // MARK: - Conversion Helpers
    
    private func convertSpoonacularToRecommendations(_ recipes: [SpoonacularRecipe]) async throws -> [FoodRecommendation] {
        // Similar to Edamam conversion but with Spoonacular data structure
        // Implementation would be similar to convertEdamamToRecommendations
        return []
    }
    
    private func convertToSpoonacularParams(_ edamamParams: [String: String]) -> [String: String] {
        // Convert Edamam API parameters to Spoonacular format
        var spoonacularParams: [String: String] = [:]
        
        for (key, value) in edamamParams {
            switch key {
            case "diet":
                spoonacularParams["diet"] = value
            case "health":
                if value == "gluten-free" {
                    spoonacularParams["intolerances"] = "gluten"
                }
                // Add more conversions as needed
            default:
                break
            }
        }
        
        return spoonacularParams
    }
    
    private func determineCategory(for recipe: EdamamRecipe) -> RecommendationCategory {
        // Logic to determine category based on recipe metadata
        // This would use ML or keyword analysis
        return .all
    }
    
    private func generateReason(for recipe: EdamamRecipe) -> String {
        // Generate personalized reason based on recipe nutrients and health benefits
        return "Healthy and nutritious meal option"
    }
}

// MARK: - API Response Structures

struct EdamamResponse: Codable {
    let hits: [EdamamRecipe]
}

struct EdamamRecipe: Codable {
    let label: String
    let nutrients: RecipeNutrients
    let yield: Double
    // Add more fields as needed
}

struct RecipeNutrients: Codable {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let cholesterol: Double?
}

struct SpoonacularResponse: Codable {
    let results: [SpoonacularRecipe]
}

struct SpoonacularRecipe: Codable {
    let title: String
    let nutrition: SpoonacularNutrition
    // Add more fields as needed
}

struct SpoonacularNutrition: Codable {
    let nutrients: [SpoonacularNutrient]
}

struct SpoonacularNutrient: Codable {
    let name: String
    let amount: Double
    let unit: String
}

struct UnsplashResponse: Codable {
    let results: [UnsplashPhoto]
}

struct UnsplashPhoto: Codable {
    let urls: UnsplashURLs
}

struct UnsplashURLs: Codable {
    let regular: String
} 
