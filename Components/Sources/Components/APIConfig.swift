import Foundation
import SwiftKeychainWrapper

public struct APIConfig {
    public static let shared = APIConfig()
    
    private init() {}
    
    public func getAPIKey() -> String? {
        return KeychainWrapper.standard.string(forKey: "API_KEY")
    }
    
    public func setAPIKey(_ apiKey: String) {
        KeychainWrapper.standard.set(apiKey, forKey: "API_KEY")
    }
    
    public func removeAPIKey() {
        KeychainWrapper.standard.removeObject(forKey: "API_KEY")
    }
} 