import Foundation
import SwiftUI
import Combine

/// Manages API keys for the application
public final class APIKeyManager: ObservableObject {
    /// Shared instance
    public static let shared = APIKeyManager()
    
    /// Initialize the manager
    private init() {
        loadKeys()
    }
    
    /// Load keys from keychain
    private func loadKeys() {
        // Add any other API key loading here if needed
    }
    
    /// Clear all stored keys
    public func clearKeys() {
        // Add any other API key clearing here if needed
    }
} 