//
//  ContentManager.swift
//  foodscannerpro
//
//  Created by Samuel Eskenasy
//

import Foundation
import SwiftUI
import CoreData

@MainActor
class ContentManager: ObservableObject {
    static let shared = ContentManager()
    
    @Published private(set) var isLoading = false
    @Published private(set) var lastError: String?
    
    private let healthService = HealthService.shared
    private let userProfile = UserProfile.shared
    private let automatedService = AutomatedContentService.shared
    
    // MARK: - Content Categories
    
    enum ContentCategory {
        case general
        case dietaryGoal(DietaryGoal)
        case healthCondition(HealthCondition)
        case culturalPreference(String)
    }
    
    // MARK: - Image Management
    
    func getImage(named imageName: String, for category: ContentCategory) -> Image {
        let basePath: String
        
        switch category {
        case .general:
            basePath = "General"
        case .dietaryGoal(let goal):
            basePath = goal.rawValue
        case .healthCondition(let condition):
            basePath = condition.rawValue
        case .culturalPreference(let preference):
            basePath = preference.replacingOccurrences(of: " ", with: "")
        }
        
        // Try to load image from the specified path
        let specificPath = "\(basePath)/\(imageName)"
        let generalPath = "General/\(imageName)"
        
        // First try specific category
        if let _ = UIImage(named: specificPath) {
            return Image(specificPath)
        }
        
        // Then try general category
        if let _ = UIImage(named: generalPath) {
            return Image(generalPath)
        }
        
        // Return placeholder if no image found
        return Image(systemName: "photo")
    }
    
    // MARK: - Text Content
    
    func getLocalizedText(key: String, category: ContentCategory) -> String {
        var fullKey: String
        
        switch category {
        case .general:
            fullKey = "general.\(key)"
        case .dietaryGoal(let goal):
            fullKey = "goal.\(goal.rawValue).\(key)"
        case .healthCondition(let condition):
            fullKey = "condition.\(condition.rawValue).\(key)"
        case .culturalPreference(let preference):
            fullKey = "cultural.\(preference).\(key)"
        }
        
        return NSLocalizedString(fullKey, comment: "")
    }
    
    // MARK: - Recommendation Content
    
    func getPersonalizedRecommendations() async throws -> [FoodRecommendation] {
        // Use DispatchQueue.main to set the loading state
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            // Capture needed data at the start
            let healthProfile = await MainActor.run { self.healthService.healthProfile }
            let restrictions = await MainActor.run { healthProfile.dietaryRestrictions }
            
            // Get recommendations from automated service
            let recommendations = try await automatedService.generateAutomatedRecommendations(
                for: healthProfile
            )
            
            // Filter based on restrictions
            let filteredRecommendations = recommendations.filter { recommendation in
                // Check if the recommendation is compatible with all dietary restrictions
                for restriction in restrictions {
                    switch restriction {
                    case .vegetarian:
                        if recommendation.containsMeat { return false }
                    case .vegan:
                        if recommendation.containsAnimalProducts { return false }
                    case .glutenFree:
                        if recommendation.containsGluten { return false }
                    case .dairyFree:
                        if recommendation.containsDairy { return false }
                    case .kosher:
                        // For kosher, we'll check for pork and shellfish
                        if recommendation.foodName.lowercased().contains("pork") ||
                           recommendation.foodName.lowercased().contains("shellfish") {
                            return false
                        }
                    case .halal:
                        // For halal, we'll check for pork and alcohol
                        if recommendation.foodName.lowercased().contains("pork") ||
                           recommendation.foodName.lowercased().contains("alcohol") ||
                           recommendation.foodName.lowercased().contains("wine") ||
                           recommendation.foodName.lowercased().contains("beer") {
                            return false
                        }
                    }
                }
                return true
            }
            
            // Sort by relevance and limit to reasonable number
            let finalResults = Array(filteredRecommendations.prefix(10))
            
            // Update state on main thread
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            return finalResults
        } catch {
            // Handle error on main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.lastError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Cache Management
    
    private let imageCache = NSCache<NSString, NSData>()
    
    func cacheImageData(_ data: Data, for key: String) {
        imageCache.setObject(data as NSData, forKey: key as NSString)
    }
    
    func getCachedImageData(for key: String) -> Data? {
        return imageCache.object(forKey: key as NSString) as Data?
    }
} 