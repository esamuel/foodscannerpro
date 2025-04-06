import Foundation

enum APIConfig {
    private static let apiKeys: [String: String] = {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: String] else {
            fatalError("APIKeys.plist not found or invalid format")
        }
        return plist
    }()
    
    // Base URLs
    static let edamamBaseURL = "https://api.edamam.com/api/food-database/v2"
    static let spoonacularBaseURL = "https://api.spoonacular.com"
    static let usdaBaseURL = "https://api.nal.usda.gov/fdc/v1"
    static let unsplashBaseURL = "https://api.unsplash.com"
    
    // API Keys
    static var edamamAPIKey: String {
        guard let key = apiKeys["EDAMAM_API_KEY"] else {
            fatalError("Edamam API key not found")
        }
        return key
    }
    
    static var edamamAppID: String {
        guard let id = apiKeys["EDAMAM_APP_ID"] else {
            fatalError("Edamam App ID not found")
        }
        return id
    }
    
    static var spoonacularAPIKey: String {
        guard let key = apiKeys["SPOONACULAR_API_KEY"] else {
            fatalError("Spoonacular API key not found")
        }
        return key
    }
    
    static var usdaAPIKey: String {
        guard let key = apiKeys["USDA_API_KEY"] else {
            fatalError("USDA API key not found")
        }
        return key
    }
    
    static var unsplashAPIKey: String {
        guard let key = apiKeys["UNSPLASH_API_KEY"] else {
            fatalError("Unsplash API key not found")
        }
        return key
    }
    
    // URL Construction Helpers
    static func edamamSearchURL(query: String) -> URL {
        var components = URLComponents(string: "\(edamamBaseURL)/parser")!
        components.queryItems = [
            URLQueryItem(name: "app_id", value: edamamAppID),
            URLQueryItem(name: "app_key", value: edamamAPIKey),
            URLQueryItem(name: "ingr", value: query)
        ]
        return components.url!
    }
    
    static func spoonacularSearchURL(query: String) -> URL {
        var components = URLComponents(string: "\(spoonacularBaseURL)/food/products/search")!
        components.queryItems = [
            URLQueryItem(name: "apiKey", value: spoonacularAPIKey),
            URLQueryItem(name: "query", value: query)
        ]
        return components.url!
    }
    
    static func unsplashFoodImageURL(query: String) -> URL {
        var components = URLComponents(string: "\(unsplashBaseURL)/search/photos")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: unsplashAPIKey),
            URLQueryItem(name: "query", value: "\(query) food"),
            URLQueryItem(name: "orientation", value: "landscape")
        ]
        return components.url!
    }
} 