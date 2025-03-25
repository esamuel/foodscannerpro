import Foundation
import Components

/// Configuration for API services
public enum APIConfig {
    /// The ChatGPT API key
    public static var chatGPTAPIKey: String {
        return APIKeyManager.shared.chatGPTAPIKey
    }
    
    /// Configure the ChatGPT API key
    /// - Parameter key: The API key to set
    public static func configure(withChatGPTKey key: String) {
        _ = APIKeyManager.shared.updateChatGPTAPIKey(key)
    }
} 