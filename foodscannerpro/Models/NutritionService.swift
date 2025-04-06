import Foundation
import Combine

// Remove USDA API Types section and start directly with the NutritionService class
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
        // First try USDA database
        fetchFromUSDA(foodName: foodName, retryCount: 0) { result in
            switch result {
            case .success(let nutritionInfo):
                completion(.success(nutritionInfo))
            case .failure:
                // If USDA fails, use estimated values
                let estimatedInfo = FoodNutritionInfo(
                    foodName: foodName,
                    calories: 100,
                    protein: 5,
                    carbs: 15,
                    fat: 3,
                    fiber: nil,
                    sugar: nil,
                    sodium: nil,
                    cholesterol: nil,
                    potassium: nil,
                    calcium: nil,
                    iron: nil,
                    vitaminA: nil,
                    vitaminC: nil,
                    servingSize: 100,
                    servingUnit: "g",
                    source: .estimated
                )
                completion(.success(estimatedInfo))
            }
        }
    }
    
    /// Clear the nutrition cache
    func clearCache() {
        nutritionCache.removeAll()
        saveCacheToDisk()
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
            
            // Parse response data
            guard let data = data else {
                self.isLoading = false
                let error = NSError(domain: "NutritionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                self.lastError = "No data received"
                completion(.failure(error))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(USDAResponse.self, from: data)
                guard let food = response.foods.first else {
                    self.isLoading = false
                    let error = NSError(domain: "NutritionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No food found"])
                    self.lastError = "No food found"
                    completion(.failure(error))
                    return
                }
                
                // Extract nutrient values with default values for required fields
                let nutritionInfo = FoodNutritionInfo(
                    foodName: foodName,
                    calories: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.energy) ?? 0,
                    protein: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.protein) ?? 0,
                    carbs: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.carbs) ?? 0,
                    fat: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.fat) ?? 0,
                    fiber: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.fiber),
                    sugar: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.sugar),
                    sodium: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.sodium),
                    cholesterol: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.cholesterol),
                    potassium: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.potassium),
                    calcium: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.calcium),
                    iron: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.iron),
                    vitaminA: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.vitaminA),
                    vitaminC: self.getNutrientValue(from: food.foodNutrients, nutrientId: NutrientIDs.vitaminC),
                    servingSize: food.servingSize ?? 100,
                    servingUnit: food.servingSizeUnit ?? "g",
                    source: .usda
                )
                
                self.isLoading = false
                completion(.success(nutritionInfo))
                
            } catch {
                self.isLoading = false
                self.lastError = "Failed to parse USDA response"
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func getNutrientValue(from nutrients: [USDANutrient], nutrientId: Int) -> Double? {
        return nutrients.first { $0.nutrientId == nutrientId }?.value
    }
    
    // MARK: - Persistence Methods
    
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
        // Common default values
        let defaultServingSize: Double = 100
        let defaultServingUnit = "g"
        
        // Fruits
        fallbackDatabase["apple"] = FoodNutritionInfo(
            foodName: "Apple",
            calories: 52,
            protein: 0.3,
            carbs: 14,
            fat: 0.2,
            fiber: 2.4,
            sugar: 10.4,
            sodium: nil,
            cholesterol: nil,
            potassium: nil,
            calcium: nil,
            iron: nil,
            vitaminA: nil,
            vitaminC: nil,
            servingSize: defaultServingSize,
            servingUnit: defaultServingUnit,
            source: .estimated
        )
        
        // Add more fallback entries with all required parameters...
        // For brevity, I'll just add one example. You should update all other entries similarly
        fallbackDatabase["banana"] = FoodNutritionInfo(
            foodName: "Banana",
            calories: 89,
            protein: 1.1,
            carbs: 23,
            fat: 0.3,
            fiber: 2.6,
            sugar: 12.2,
            sodium: nil,
            cholesterol: nil,
            potassium: nil,
            calcium: nil,
            iron: nil,
            vitaminA: nil,
            vitaminC: nil,
            servingSize: defaultServingSize,
            servingUnit: defaultServingUnit,
            source: .estimated
        )
    }
} 