import Foundation
import Combine

class NutritionService: ObservableObject {
    // MARK: - Properties
    
    /// Shared instance for singleton access
    static let shared = NutritionService()
    
    /// Published properties for UI updates
    @Published var isLoading = false
    @Published var lastError: String?
    
    /// USDA API Key - Replace with your actual API key
    private let apiKey = "DEMO_KEY" // TODO: Replace with your key from https://fdc.nal.usda.gov/api-key-signup.html
    private let baseURL = "https://api.nal.usda.gov/fdc/v1"
    
    /// Cache for storing nutrition data
    private var nutritionCache: [String: FoodNutritionInfo] = [:]
    private let cacheFileName = "nutrition_cache.json"
    
    /// Fallback nutrition database for common foods
    private var fallbackDatabase: [String: FoodNutritionInfo] = [:]
    
    /// Cancellables for managing Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    /// API request retry count
    private let maxRetryCount = 3
    
    // MARK: - Initialization
    
    private init() {
        loadCacheFromDisk()
        setupFallbackDatabase()
    }
    
    // MARK: - Public Methods
    
    /// Get nutrition information for a food item
    /// - Parameters:
    ///   - foodName: Name of the food to search for
    ///   - completion: Completion handler with nutrition info or error
    func getNutritionInfo(for foodName: String, completion: @escaping (Result<FoodNutritionInfo, Error>) -> Void) {
        // Check cache first
        if let cachedInfo = nutritionCache[foodName.lowercased()] {
            completion(.success(cachedInfo))
            return
        }
        
        // Try to get from USDA API
        fetchFromUSDA(foodName: foodName, retryCount: 0) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let nutritionInfo):
                // Add to cache
                self.nutritionCache[foodName.lowercased()] = nutritionInfo
                self.saveCacheToDisk()
                completion(.success(nutritionInfo))
                
            case .failure(let error):
                // Try fallback database
                if let fallbackInfo = self.getFallbackNutrition(for: foodName) {
                    completion(.success(fallbackInfo))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Clear the nutrition cache
    func clearCache() {
        nutritionCache.removeAll()
        saveCacheToDisk()
    }
    
    /// Get basic nutrition information for a food item
    /// - Parameters:
    ///   - foodName: Name of the food to search for
    ///   - completion: Completion handler with nutrition info or error
    func getBasicNutritionInfo(for foodName: String, completion: @escaping (Result<NutritionInfo, Error>) -> Void) {
        getNutritionInfo(for: foodName) { result in
            switch result {
            case .success(let foodNutritionInfo):
                completion(.success(foodNutritionInfo.toNutritionInfo()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - USDA API Methods
    
    private func fetchFromUSDA(foodName: String, retryCount: Int, completion: @escaping (Result<FoodNutritionInfo, Error>) -> Void) {
        isLoading = true
        lastError = nil
        
        // Create URL components
        guard var urlComponents = URLComponents(string: "\(baseURL)/foods/search") else {
            isLoading = false
            let error = NSError(domain: "NutritionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        // Add query parameters
        urlComponents.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: foodName),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy"),
            URLQueryItem(name: "pageSize", value: "1")
        ]
        
        // Create URL request
        guard let url = urlComponents.url else {
            isLoading = false
            let error = NSError(domain: "NutritionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            completion(.failure(error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Make API request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle network errors
            if let error = error {
                // Retry logic for network errors
                if retryCount < self.maxRetryCount {
                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                        self.fetchFromUSDA(foodName: foodName, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                
                self.isLoading = false
                self.lastError = error.localizedDescription
                completion(.failure(error))
                return
            }
            
            // Check HTTP status code
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 429 { // Too Many Requests
                    // Retry with exponential backoff
                    if retryCount < self.maxRetryCount {
                        let delay = pow(2.0, Double(retryCount)) // Exponential backoff: 1, 2, 4 seconds
                        DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                            self.fetchFromUSDA(foodName: foodName, retryCount: retryCount + 1, completion: completion)
                        }
                        return
                    }
                }
                
                if httpResponse.statusCode != 200 {
                    self.isLoading = false
                    let error = NSError(domain: "NutritionService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP Error: \(httpResponse.statusCode)"])
                    self.lastError = "HTTP Error: \(httpResponse.statusCode)"
                    completion(.failure(error))
                    return
                }
            }
            
            // Parse response data
            guard let data = data else {
                self.isLoading = false
                let error = NSError(domain: "NutritionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                self.lastError = "No data received"
                completion(.failure(error))
                return
            }
            
            do {
                // Parse JSON response
                let decoder = JSONDecoder()
                let response = try decoder.decode(USDAResponse.self, from: data)
                
                // Check if any foods were found
                if response.foods.isEmpty {
                    self.isLoading = false
                    let error = NSError(domain: "NutritionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No food items found for '\(foodName)'"])
                    self.lastError = "No food items found"
                    completion(.failure(error))
                    return
                }
                
                // Get the first food item
                let food = response.foods[0]
                
                // Create nutrition info
                let nutritionInfo = self.parseUSDAFood(food, originalQuery: foodName)
                
                self.isLoading = false
                completion(.success(nutritionInfo))
                
            } catch {
                self.isLoading = false
                self.lastError = "Failed to parse response: \(error.localizedDescription)"
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parseUSDAFood(_ food: USDAFood, originalQuery: String) -> FoodNutritionInfo {
        // Extract nutrients
        func getNutrientValue(id: Int) -> Double {
            return food.foodNutrients.first(where: { $0.nutrientId == id })?.value ?? 0
        }
        
        // Create nutrition info
        return FoodNutritionInfo(
            foodName: food.description,
            calories: Int(getNutrientValue(id: NutrientIDs.calories)),
            protein: getNutrientValue(id: NutrientIDs.protein),
            carbs: getNutrientValue(id: NutrientIDs.carbs),
            fat: getNutrientValue(id: NutrientIDs.fat),
            fiber: getNutrientValue(id: NutrientIDs.fiber),
            sugar: getNutrientValue(id: NutrientIDs.sugar),
            sodium: getNutrientValue(id: NutrientIDs.sodium),
            cholesterol: getNutrientValue(id: NutrientIDs.cholesterol),
            potassium: getNutrientValue(id: NutrientIDs.potassium),
            calcium: getNutrientValue(id: NutrientIDs.calcium),
            iron: getNutrientValue(id: NutrientIDs.iron),
            vitaminA: getNutrientValue(id: NutrientIDs.vitaminA),
            vitaminC: getNutrientValue(id: NutrientIDs.vitaminC),
            servingSize: food.servingSize ?? 100,
            servingUnit: food.servingSizeUnit ?? "g",
            source: .usda
        )
    }
    
    // MARK: - Cache Methods
    
    private func loadCacheFromDisk() {
        guard let cacheURL = getCacheURL() else { return }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            nutritionCache = try decoder.decode([String: FoodNutritionInfo].self, from: data)
        } catch {
            nutritionCache = [:]
        }
    }
    
    private func saveCacheToDisk() {
        guard let cacheURL = getCacheURL() else { return }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(nutritionCache)
            try data.write(to: cacheURL)
        } catch {
            // Handle error silently
        }
    }
    
    private func getCacheURL() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(cacheFileName)
    }
    
    private func getFallbackNutrition(for foodName: String) -> FoodNutritionInfo? {
        return fallbackDatabase[foodName.lowercased()]
    }
    
    private func setupFallbackDatabase() {
        // Fruits
        fallbackDatabase["apple"] = FoodNutritionInfo(foodName: "Apple", calories: 52, protein: 0.3, carbs: 14, fat: 0.2, fiber: 2.4, source: .fallback)
        fallbackDatabase["banana"] = FoodNutritionInfo(foodName: "Banana", calories: 89, protein: 1.1, carbs: 23, fat: 0.3, fiber: 2.6, source: .fallback)
        fallbackDatabase["orange"] = FoodNutritionInfo(foodName: "Orange", calories: 47, protein: 0.9, carbs: 12, fat: 0.1, fiber: 2.4, source: .fallback)
        fallbackDatabase["strawberry"] = FoodNutritionInfo(foodName: "Strawberry", calories: 32, protein: 0.7, carbs: 7.7, fat: 0.3, fiber: 2.0, source: .fallback)
        fallbackDatabase["blueberry"] = FoodNutritionInfo(foodName: "Blueberry", calories: 57, protein: 0.7, carbs: 14.5, fat: 0.3, fiber: 2.4, source: .fallback)
        
        // Vegetables
        fallbackDatabase["carrot"] = FoodNutritionInfo(foodName: "Carrot", calories: 41, protein: 0.9, carbs: 10, fat: 0.2, fiber: 2.8, source: .fallback)
        fallbackDatabase["broccoli"] = FoodNutritionInfo(foodName: "Broccoli", calories: 34, protein: 2.8, carbs: 7, fat: 0.4, fiber: 2.6, source: .fallback)
        fallbackDatabase["spinach"] = FoodNutritionInfo(foodName: "Spinach", calories: 23, protein: 2.9, carbs: 3.6, fat: 0.4, fiber: 2.2, source: .fallback)
        fallbackDatabase["potato"] = FoodNutritionInfo(foodName: "Potato", calories: 77, protein: 2.0, carbs: 17, fat: 0.1, fiber: 2.2, source: .fallback)
        fallbackDatabase["tomato"] = FoodNutritionInfo(foodName: "Tomato", calories: 18, protein: 0.9, carbs: 3.9, fat: 0.2, fiber: 1.2, source: .fallback)
        
        // Proteins
        fallbackDatabase["chicken"] = FoodNutritionInfo(foodName: "Chicken Breast", calories: 165, protein: 31, carbs: 0, fat: 3.6, source: .fallback)
        fallbackDatabase["beef"] = FoodNutritionInfo(foodName: "Beef", calories: 250, protein: 26, carbs: 0, fat: 17, source: .fallback)
        fallbackDatabase["salmon"] = FoodNutritionInfo(foodName: "Salmon", calories: 206, protein: 22, carbs: 0, fat: 13, source: .fallback)
        fallbackDatabase["egg"] = FoodNutritionInfo(foodName: "Egg", calories: 155, protein: 13, carbs: 1.1, fat: 11, source: .fallback)
        fallbackDatabase["tofu"] = FoodNutritionInfo(foodName: "Tofu", calories: 76, protein: 8, carbs: 2, fat: 4.2, source: .fallback)
        
        // Grains
        fallbackDatabase["rice"] = FoodNutritionInfo(foodName: "White Rice", calories: 130, protein: 2.7, carbs: 28, fat: 0.3, fiber: 0.4, source: .fallback)
        fallbackDatabase["bread"] = FoodNutritionInfo(foodName: "White Bread", calories: 265, protein: 9, carbs: 49, fat: 3.2, fiber: 2.7, source: .fallback)
        fallbackDatabase["pasta"] = FoodNutritionInfo(foodName: "Pasta", calories: 158, protein: 5.8, carbs: 31, fat: 0.9, fiber: 1.8, source: .fallback)
        fallbackDatabase["oats"] = FoodNutritionInfo(foodName: "Oats", calories: 389, protein: 16.9, carbs: 66, fat: 6.9, fiber: 10.6, source: .fallback)
        fallbackDatabase["quinoa"] = FoodNutritionInfo(foodName: "Quinoa", calories: 120, protein: 4.4, carbs: 21.3, fat: 1.9, fiber: 2.8, source: .fallback)
        
        // Dairy
        fallbackDatabase["milk"] = FoodNutritionInfo(foodName: "Milk", calories: 42, protein: 3.4, carbs: 5, fat: 1, source: .fallback)
    }
} 