import Foundation
import SwiftKeychainWrapper
import SwiftUI

@available(iOS 13.0, macOS 10.15, *)
public final class APIKeyManager: ObservableObject {
    public static let shared = APIKeyManager()
    
    private let keychain = KeychainWrapper.standard
    private let servicePrefix = "com.foodscannerpro.apikeys"
    
    @Published public private(set) var clarifaiAPIKey: String = ""
    @Published public private(set) var logMealAPIKey: String = ""
    @Published public private(set) var usdaAPIKey: String = ""
    
    private init() {
        loadAPIKeys()
    }
    
    private func loadAPIKeys() {
        clarifaiAPIKey = getAPIKey(for: "clarifai") ?? ""
        logMealAPIKey = getAPIKey(for: "logmeal") ?? ""
        usdaAPIKey = getAPIKey(for: "usda") ?? ""
    }
    
    private func getAPIKey(for service: String) -> String? {
        return keychain.string(forKey: "\(servicePrefix).\(service)")
    }
    
    private func saveAPIKey(_ key: String, for service: String) -> Bool {
        return keychain.set(key, forKey: "\(servicePrefix).\(service)")
    }
    
    public func updateClarifaiAPIKey(_ key: String) -> Bool {
        let success = saveAPIKey(key, for: "clarifai")
        if success {
            clarifaiAPIKey = key
        }
        return success
    }
    
    public func updateLogMealAPIKey(_ key: String) -> Bool {
        let success = saveAPIKey(key, for: "logmeal")
        if success {
            logMealAPIKey = key
        }
        return success
    }
    
    public func updateUSDAAPIKey(_ key: String) -> Bool {
        let success = saveAPIKey(key, for: "usda")
        if success {
            usdaAPIKey = key
        }
        return success
    }
    
    public func hasValidClarifaiKey() -> Bool {
        !clarifaiAPIKey.isEmpty
    }
    
    public func hasValidLogMealKey() -> Bool {
        !logMealAPIKey.isEmpty
    }
    
    public func hasValidUsdaKey() -> Bool {
        !usdaAPIKey.isEmpty
    }
    
    public func clearAllAPIKeys() {
        keychain.removeAllKeys()
        loadAPIKeys()
    }
} 