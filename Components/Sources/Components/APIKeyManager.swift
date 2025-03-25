import Foundation
import SwiftUI
import SwiftKeychainWrapper

/// A class to manage API keys for the Food Scanner Pro app
public class APIKeyManager: ObservableObject {
    /// Shared instance for singleton access
    public static let shared = APIKeyManager()
    
    // Published properties for SwiftUI updates
    @Published public private(set) var chatGPTAPIKey: String = ""
    @Published public private(set) var clarifaiAPIKey: String = ""
    @Published public private(set) var logMealAPIKey: String = ""
    @Published public private(set) var usdaAPIKey: String = ""
    
    // Keys for storing in Keychain
    private let clarifaiKey = "CLARIFAI_API_KEY"
    private let logMealKey = "LOGMEAL_API_KEY"
    private let usdaKey = "USDA_API_KEY"
    private let chatGPTKey = "CHATGPT_API_KEY"
    
    // Default values
    public let defaultClarifaiKey = "YOUR_CLARIFAI_API_KEY"
    public let defaultLogMealKey = "YOUR_LOGMEAL_API_KEY"
    public let defaultUsdaKey = "DEMO_KEY"
    public let defaultChatGPTKey = "YOUR_CHATGPT_API_KEY"
    
    /// Initialization
    private init() {
        // Load initial values
        loadAllKeys()
    }
    
    /// Load all keys from Keychain
    private func loadAllKeys() {
        chatGPTAPIKey = KeychainWrapper.standard.string(forKey: chatGPTKey) ?? defaultChatGPTKey
        clarifaiAPIKey = KeychainWrapper.standard.string(forKey: clarifaiKey) ?? defaultClarifaiKey
        logMealAPIKey = KeychainWrapper.standard.string(forKey: logMealKey) ?? defaultLogMealKey
        usdaAPIKey = KeychainWrapper.standard.string(forKey: usdaKey) ?? defaultUsdaKey
        
        print("DEBUG: Loaded ChatGPT Key: \(chatGPTAPIKey)")
    }
    
    /// Update the Clarifai API key
    /// - Parameter key: The API key to set
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func updateClarifaiAPIKey(_ key: String) -> Bool {
        let success = KeychainWrapper.standard.set(key, forKey: clarifaiKey)
        if success {
            clarifaiAPIKey = key
            objectWillChange.send()
        }
        return success
    }
    
    /// Update the LogMeal API key
    /// - Parameter key: The API key to set
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func updateLogMealAPIKey(_ key: String) -> Bool {
        let success = KeychainWrapper.standard.set(key, forKey: logMealKey)
        if success {
            logMealAPIKey = key
            objectWillChange.send()
        }
        return success
    }
    
    /// Update the USDA API key
    /// - Parameter key: The API key to set
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func updateUSDAAPIKey(_ key: String) -> Bool {
        let success = KeychainWrapper.standard.set(key, forKey: usdaKey)
        if success {
            usdaAPIKey = key
            objectWillChange.send()
        }
        return success
    }
    
    /// Update the ChatGPT API key
    /// - Parameter key: The API key to set
    /// - Returns: True if successful, false otherwise
    @discardableResult
    public func updateChatGPTAPIKey(_ key: String) -> Bool {
        print("DEBUG SAVING KEY: \(key)")  // Simple print for debugging
        
        // Save the key
        let success = KeychainWrapper.standard.set(key, forKey: chatGPTKey)
        
        if success {
            chatGPTAPIKey = key
            objectWillChange.send()
            
            // Verify the save immediately
            let savedKey = KeychainWrapper.standard.string(forKey: chatGPTKey)
            print("DEBUG VERIFIED KEY: \(savedKey ?? "nil")")  // Simple print for debugging
        } else {
            print("DEBUG: Failed to save ChatGPT key")
        }
        
        return success
    }
    
    /// Validate the Clarifai API key
    /// - Returns: True if the key is valid, false otherwise
    public func hasValidClarifaiKey() -> Bool {
        return clarifaiAPIKey != defaultClarifaiKey
    }
    
    /// Validate the LogMeal API key
    /// - Returns: True if the key is valid, false otherwise
    public func hasValidLogMealKey() -> Bool {
        return logMealAPIKey != defaultLogMealKey
    }
    
    /// Validate the USDA API key
    /// - Returns: True if the key is valid, false otherwise
    public func hasValidUsdaKey() -> Bool {
        return usdaAPIKey != defaultUsdaKey
    }
    
    /// Validate the ChatGPT API key
    /// - Returns: True if the key is valid, false otherwise
    public func hasValidChatGPTKey() -> Bool {
        return chatGPTAPIKey != defaultChatGPTKey
    }
    
    /// Reset all keys
    public func resetAllKeys() {
        KeychainWrapper.standard.removeObject(forKey: clarifaiKey)
        KeychainWrapper.standard.removeObject(forKey: logMealKey)
        KeychainWrapper.standard.removeObject(forKey: usdaKey)
        KeychainWrapper.standard.removeObject(forKey: chatGPTKey)
        
        // Reset to default values
        loadAllKeys()
        objectWillChange.send()
    }
} 