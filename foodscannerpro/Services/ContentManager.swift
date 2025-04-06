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
    @Published var diagnosticInfo: String?
    
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
        // Start loading
        withAnimation {
            isLoading = true
            lastError = nil
            diagnosticInfo = "Preparing to fetch recommendations..."
        }
        
        do {
            // Check network connectivity
            if !automatedService.isConnected {
                diagnosticInfo = "Network connection unavailable"
                throw NetworkError.noConnection
            }
            
            // Check if health profile is properly configured
            let healthProfile = healthService.healthProfile
            diagnosticInfo = "Health profile loaded with goal: \(healthProfile.dietaryGoal)"
            
            if healthProfile.dietaryGoal == .none {
                diagnosticInfo = "No dietary goal specified in health profile"
            }
            
            // Run API request in a detached task to avoid blocking the main thread
            let recommendations = try await Task.detached {
                // Get recommendations from automated service
                return try await AutomatedContentService.shared.generateAutomatedRecommendations(
                    for: healthProfile
                )
            }.value
            
            // Process the recommendations in another background task
            let finalRecommendations = await Task.detached {
                // Filter based on restrictions
                let restrictions = healthProfile.dietaryRestrictions
                let filtered = recommendations.filter { recommendation in
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
                
                // Sort and limit results
                return Array(filtered.prefix(10))
            }.value
            
            // Success, update diagnostic info
            if finalRecommendations.isEmpty {
                diagnosticInfo = "No recommendations found that match your dietary profile"
            } else {
                diagnosticInfo = "Successfully retrieved \(finalRecommendations.count) recommendations"
            }
            
            // Update state on main thread
            withAnimation {
                isLoading = false
            }
            
            return finalRecommendations
        } catch {
            // Handle error and update diagnostic info
            withAnimation {
                isLoading = false
                lastError = error.localizedDescription
                
                if let networkError = error as? NetworkError {
                    diagnosticInfo = "Network error: \(networkError.localizedDescription)"
                } else {
                    diagnosticInfo = "Error: \(error.localizedDescription)"
                }
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
    
    // MARK: - Testing API Connectivity
    
    func testAPIConnectivity() async -> [String: Bool] {
        var results = [String: Bool]()
        
        // Test Edamam API
        do {
            let url = APIConfig.edamamSearchURL(query: "apple")
            let (_, response) = try await URLSession.shared.data(from: url)
            results["Edamam API"] = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            results["Edamam API"] = false
        }
        
        // Test Spoonacular API
        do {
            let url = APIConfig.spoonacularSearchURL(query: "apple")
            let (_, response) = try await URLSession.shared.data(from: url)
            results["Spoonacular API"] = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            results["Spoonacular API"] = false
        }
        
        // Test Unsplash API
        do {
            let url = APIConfig.unsplashFoodImageURL(query: "apple")
            let (_, response) = try await URLSession.shared.data(from: url)
            results["Unsplash API"] = (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            results["Unsplash API"] = false
        }
        
        return results
    }
} 