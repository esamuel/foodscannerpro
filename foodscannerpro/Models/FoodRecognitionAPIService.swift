import Foundation
import UIKit

// Service for API-based food recognition
class FoodRecognitionAPIService {
    // API endpoints
    private let clarifaiEndpoint = "https://api.clarifai.com/v2/models/food-item-recognition/outputs"
    private let logMealEndpoint = "https://api.logmeal.es/v2/recognition/dish"
    
    // API keys (replace with your actual keys)
    private let clarifaiAPIKey = "YOUR_CLARIFAI_API_KEY" // TODO: Replace with actual Clarifai API key
    private let logMealAPIKey = "YOUR_LOGMEAL_API_KEY" // TODO: Replace with actual LogMeal API key
    
    // Recognize food in an image using external APIs
    func recognizeFood(image: UIImage, completion: @escaping (Result<[(identifier: String, confidence: Float)], Error>) -> Void) {
        // Convert image to base64 for API requests
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "com.foodscannerpro", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Use Clarifai API for food recognition
        recognizeWithClarifai(base64Image: base64Image) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let observations):
                if !observations.isEmpty {
                    completion(.success(observations))
                } else {
                    // If Clarifai returns no results, try LogMeal as fallback
                    self.recognizeWithLogMeal(imageData: imageData, completion: completion)
                }
            case .failure(let error):
                print("Clarifai API error: \(error.localizedDescription)")
                // Try LogMeal as fallback
                self.recognizeWithLogMeal(imageData: imageData, completion: completion)
            }
        }
    }
    
    // Recognize food using Clarifai API
    private func recognizeWithClarifai(base64Image: String, completion: @escaping (Result<[(identifier: String, confidence: Float)], Error>) -> Void) {
        // Create URL request
        var request = URLRequest(url: URL(string: clarifaiEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("Key \(clarifaiAPIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create request body
        let requestBody: [String: Any] = [
            "inputs": [
                [
                    "data": [
                        "image": [
                            "base64": base64Image
                        ]
                    ]
                ]
            ]
        ]
        
        // Convert request body to JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.foodscannerpro", code: 1002, userInfo: [NSLocalizedDescriptionKey: "No data received from Clarifai API"])))
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let outputs = json["outputs"] as? [[String: Any]],
                   let firstOutput = outputs.first,
                   let data = firstOutput["data"] as? [String: Any],
                   let concepts = data["concepts"] as? [[String: Any]] {
                    
                    // Extract food concepts
                    var observations: [(identifier: String, confidence: Float)] = []
                    
                    for concept in concepts {
                        if let name = concept["name"] as? String,
                           let confidence = concept["value"] as? NSNumber {
                            observations.append((identifier: name, confidence: confidence.floatValue))
                        }
                    }
                    
                    completion(.success(observations))
                } else {
                    completion(.failure(NSError(domain: "com.foodscannerpro", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Clarifai API response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Recognize food using LogMeal API
    private func recognizeWithLogMeal(imageData: Data, completion: @escaping (Result<[(identifier: String, confidence: Float)], Error>) -> Void) {
        // Create URL request
        var request = URLRequest(url: URL(string: logMealEndpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(logMealAPIKey)", forHTTPHeaderField: "Authorization")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Send request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "com.foodscannerpro", code: 1004, userInfo: [NSLocalizedDescriptionKey: "No data received from LogMeal API"])))
                return
            }
            
            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let recognition = json["recognition_results"] as? [[String: Any]] {
                    
                    // Extract food items
                    var observations: [(identifier: String, confidence: Float)] = []
                    
                    for item in recognition {
                        if let name = item["name"] as? String,
                           let confidence = item["prob"] as? NSNumber {
                            observations.append((identifier: name, confidence: confidence.floatValue))
                        }
                    }
                    
                    completion(.success(observations))
                } else {
                    completion(.failure(NSError(domain: "com.foodscannerpro", code: 1005, userInfo: [NSLocalizedDescriptionKey: "Failed to parse LogMeal API response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// Extension to help with multipart form data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 