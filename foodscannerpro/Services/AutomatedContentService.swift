import Foundation
import UIKit
import CoreML
import SwiftUI
import Network

class AutomatedContentService: ObservableObject {
    static let shared = AutomatedContentService()
    
    // MARK: - Properties
    @Published var isConnected = true
    @Published var lastNetworkError: String?
    @Published var lastRequestURL: String?
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    // Use APIConfig to get the keys instead of hardcoding them
    private var edamamAPIKey: String {
        return APIConfig.edamamAPIKey
    }
    
    private var edamamAppID: String {
        return APIConfig.edamamAppID
    }
    
    private var spoonacularAPIKey: String {
        return APIConfig.spoonacularAPIKey
    }
    
    private var unsplashAPIKey: String {
        return APIConfig.unsplashAPIKey
    }
    
    init() {
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                print("Network status: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    // MARK: - Food Data Fetching
    
    /// Automatically fetch and generate food recommendations based on health profile
    func generateAutomatedRecommendations(for profile: HealthProfile) async throws -> [FoodRecommendation] {
        print("🔍 Generating recommendations for profile with dietary goal: \(profile.dietaryGoal)")
        
        guard isConnected else {
            print("❌ Network is not connected")
            throw NetworkError.noConnection
        }
        
        var recommendations: [FoodRecommendation] = []
        
        // Build API query parameters based on health profile
        let queryParams = buildQueryParameters(from: profile)
        print("📝 Query parameters: \(queryParams)")
        
        do {
            // Fetch recipes from Edamam API
            print("🌐 Attempting to fetch from Edamam API...")
            let edamamRecipes = try await fetchEdamamRecipes(with: queryParams)
            print("✅ Successfully fetched \(edamamRecipes.count) recipes from Edamam")
            recommendations += edamamRecipes
        } catch {
            print("❌ Edamam API error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.lastNetworkError = "Edamam API: \(error.localizedDescription)"
            }
        }
        
        do {
            // Fetch recipes from Spoonacular API as backup
            print("🌐 Attempting to fetch from Spoonacular API...")
            let spoonacularRecipes = try await fetchSpoonacularRecipes(with: queryParams)
            print("✅ Successfully fetched \(spoonacularRecipes.count) recipes from Spoonacular")
            recommendations += spoonacularRecipes
        } catch {
            print("❌ Spoonacular API error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.lastNetworkError = "Spoonacular API: \(error.localizedDescription)"
            }
        }
        
        print("📋 Total recommendations generated: \(recommendations.count)")
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
        let baseURL = APIConfig.edamamBaseURL
        var urlComponents = URLComponents(string: baseURL)!
        
        // Add API credentials
        var queryItems = [
            URLQueryItem(name: "app_id", value: edamamAppID),
            URLQueryItem(name: "app_key", value: edamamAPIKey)
        ]
        
        // Add search parameters
        for (key, value) in params {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        print("🔗 Edamam API URL: \(url.absoluteString)")
        DispatchQueue.main.async {
            self.lastRequestURL = url.absoluteString
        }
        
        do {
            // Create a URLRequest to include proper headers
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP status code
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("📡 Edamam API Response Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                // Log error response
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Edamam API Error: \(errorText)")
                }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            // Try to decode response
            do {
                let recipes = try JSONDecoder().decode(EdamamResponse.self, from: data)
                return try await convertEdamamToRecommendations(recipes.hits)
            } catch {
                print("❌ JSON Decoding Error: \(error.localizedDescription)")
                // Log the raw response for debugging
                if let responseText = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(responseText.prefix(500))...")
                }
                throw NetworkError.decodingError(error.localizedDescription)
            }
        } catch {
            throw error
        }
    }
    
    private func fetchSpoonacularRecipes(with params: [String: String]) async throws -> [FoodRecommendation] {
        let baseURL = "\(APIConfig.spoonacularBaseURL)/recipes/complexSearch"
        var urlComponents = URLComponents(string: baseURL)!
        
        // Add API key
        var queryItems = [URLQueryItem(name: "apiKey", value: spoonacularAPIKey)]
        
        // Convert Edamam params to Spoonacular format
        let spoonacularParams = convertToSpoonacularParams(params)
        for (key, value) in spoonacularParams {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        
        urlComponents.queryItems = queryItems
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        print("🔗 Spoonacular API URL: \(url.absoluteString)")
        DispatchQueue.main.async {
            self.lastRequestURL = url.absoluteString
        }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            print("📡 Spoonacular API Response Code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Spoonacular API Error: \(errorText)")
                }
                throw NetworkError.serverError(statusCode: httpResponse.statusCode)
            }
            
            do {
                let recipes = try JSONDecoder().decode(SpoonacularResponse.self, from: data)
                return try await convertSpoonacularToRecommendations(recipes.results)
            } catch {
                print("❌ JSON Decoding Error: \(error.localizedDescription)")
                if let responseText = String(data: data, encoding: .utf8) {
                    print("📄 Raw response: \(responseText.prefix(500))...")
                }
                throw NetworkError.decodingError(error.localizedDescription)
            }
        } catch {
            throw error
        }
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
    
    private func getImageURL(for foodName: String) async throws -> String? {
        // Use the predefined URL construction helper in APIConfig but add per_page parameter
        let baseURL = APIConfig.unsplashBaseURL + "/search/photos"
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

// MARK: - Error Types

enum NetworkError: Error, LocalizedError {
    case noConnection
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available."
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError(let description):
            return "Failed to decode response: \(description)"
        }
    }
} 
