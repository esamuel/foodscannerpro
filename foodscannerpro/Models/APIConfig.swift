import Foundation
import Components

/// Configuration for API services
public enum APIConfig {
    /// Configure API keys
    /// - Parameter key: The API key to set
    public static func configure(withKey key: String, forService service: String) {
        switch service {
        case "clarifai":
            _ = APIKeyManager.shared.updateClarifaiAPIKey(key)
        case "logmeal":
            _ = APIKeyManager.shared.updateLogMealAPIKey(key)
        case "usda":
            _ = APIKeyManager.shared.updateUSDAAPIKey(key)
        default:
            break
        }
    }
} 