import Foundation
import UIKit
import SwiftUI
import Components

class ChatGPTVisionService: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    
    private var apiKey: String? {
        let key = APIKeyManager.shared.chatGPTAPIKey
        return key != "YOUR_CHATGPT_API_KEY" ? key : nil
    }
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    struct VisionAnalysisResult {
        let foodName: String
        let nutritionInfo: NutritionInfo
        let healthConsiderations: [String]
        let diabetesFriendly: Bool
        let glycemicIndex: Int?
        let allergyWarnings: [String]
        let preparationMethod: String?
        let freshness: String?
        let portionSize: String?
        
        struct NutritionInfo {
            let calories: Int
            let protein: Double
            let carbs: Double
            let fats: Double
            let fiber: Double?
            let sugar: Double?
            let vitamins: [String: Double]
            let minerals: [String: Double]
        }
    }
    
    func analyzeImage(_ image: UIImage) async throws -> VisionAnalysisResult {
        guard let apiKey = apiKey else {
            throw NSError(domain: "ChatGPTVisionService", code: 401, userInfo: [NSLocalizedDescriptionKey: "API key not configured"])
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ChatGPTVisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])
        }
        
        let base64Image = imageData.base64EncodedString()
        
        let prompt = """
        Analyze this food image and provide detailed information about:
        1. Food name and description
        2. Detailed nutritional information (calories, macronutrients, vitamins, minerals)
        3. Health considerations (diabetes-friendly, allergies, etc.)
        4. Portion size estimation
        5. Preparation method
        6. Freshness indicators
        7. Any relevant dietary warnings or recommendations
        Format the response as structured data that can be parsed into the VisionAnalysisResult type.
        """
        
        // Prepare the request body
        let requestBody: [String: Any] = [
            "model": "gpt-4-vision-preview",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 1000
        ]
        
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ChatGPTVisionService", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
                         userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }
        
        // Parse the response and create a VisionAnalysisResult
        // This is a simplified example - you would need to parse the actual GPT response
        let result = try JSONDecoder().decode(GPTResponse.self, from: data)
        return try parseGPTResponse(result)
    }
    
    private func parseGPTResponse(_ response: GPTResponse) throws -> VisionAnalysisResult {
        guard let content = response.choices.first?.message.content else {
            throw NSError(domain: "ChatGPTVisionService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        // Use regular expressions to extract information from the structured response
        let foodNamePattern = "Food name: (.+)"
        let caloriesPattern = "Calories: (\\d+)"
        let proteinPattern = "Protein: ([\\d.]+)g"
        let carbsPattern = "Carbs: ([\\d.]+)g"
        let fatsPattern = "Fats: ([\\d.]+)g"
        let fiberPattern = "Fiber: ([\\d.]+)g"
        let sugarPattern = "Sugar: ([\\d.]+)g"
        let portionPattern = "Portion size: (.+)"
        let diabeticPattern = "Diabetes-friendly: (Yes|No)"
        let giPattern = "Glycemic Index: (\\d+)"
        let allergensPattern = "Allergens: (.+)"
        let preparationPattern = "Preparation: (.+)"
        let freshnessPattern = "Freshness: (.+)"
        let healthConsiderationsPattern = "Health considerations: (.+)"
        
        func extract(_ pattern: String, from text: String) -> String? {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex?.firstMatch(in: text, options: [], range: range) else { return nil }
            guard let captureRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[captureRange])
        }
        
        func extractDouble(_ pattern: String, from text: String) -> Double? {
            guard let value = extract(pattern, from: text) else { return nil }
            return Double(value)
        }
        
        func extractInt(_ pattern: String, from text: String) -> Int? {
            guard let value = extract(pattern, from: text) else { return nil }
            return Int(value)
        }
        
        // Extract vitamins and minerals from the response
        var vitamins: [String: Double] = [:]
        var minerals: [String: Double] = [:]
        
        let vitaminPattern = "Vitamin ([A-Z]): ([\\d.]+)\\s*\\w*"
        let mineralPattern = "(Iron|Calcium|Zinc|Magnesium|Potassium): ([\\d.]+)\\s*\\w*"
        
        if let vitaminRegex = try? NSRegularExpression(pattern: vitaminPattern, options: []) {
            let vitaminMatches = vitaminRegex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
            for match in vitaminMatches {
                if let vitaminRange = Range(match.range(at: 1), in: content),
                   let valueRange = Range(match.range(at: 2), in: content),
                   let value = Double(content[valueRange]) {
                    let vitamin = String(content[vitaminRange])
                    vitamins["Vitamin \(vitamin)"] = value
                }
            }
        }
        
        if let mineralRegex = try? NSRegularExpression(pattern: mineralPattern, options: []) {
            let mineralMatches = mineralRegex.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content))
            for match in mineralMatches {
                if let mineralRange = Range(match.range(at: 1), in: content),
                   let valueRange = Range(match.range(at: 2), in: content),
                   let value = Double(content[valueRange]) {
                    let mineral = String(content[mineralRange])
                    minerals[mineral] = value
                }
            }
        }
        
        // Extract health considerations and allergens as arrays
        let healthConsiderations = extract(healthConsiderationsPattern, from: content)?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        
        let allergyWarnings = extract(allergensPattern, from: content)?
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        
        // Create the nutrition info
        let nutritionInfo = VisionAnalysisResult.NutritionInfo(
            calories: extractInt(caloriesPattern, from: content) ?? 0,
            protein: extractDouble(proteinPattern, from: content) ?? 0,
            carbs: extractDouble(carbsPattern, from: content) ?? 0,
            fats: extractDouble(fatsPattern, from: content) ?? 0,
            fiber: extractDouble(fiberPattern, from: content),
            sugar: extractDouble(sugarPattern, from: content),
            vitamins: vitamins,
            minerals: minerals
        )
        
        // Create and return the final result
        return VisionAnalysisResult(
            foodName: extract(foodNamePattern, from: content) ?? "Unknown Food",
            nutritionInfo: nutritionInfo,
            healthConsiderations: healthConsiderations,
            diabetesFriendly: extract(diabeticPattern, from: content)?.lowercased() == "yes",
            glycemicIndex: extractInt(giPattern, from: content),
            allergyWarnings: allergyWarnings,
            preparationMethod: extract(preparationPattern, from: content),
            freshness: extract(freshnessPattern, from: content),
            portionSize: extract(portionPattern, from: content)
        )
    }
}

// MARK: - Response Models
private struct GPTResponse: Codable {
    // Add properties to match the GPT API response structure
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let content: String
    }
} 