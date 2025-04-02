import Foundation
import SwiftKeychainWrapper

// Export the SwiftKeychainWrapper module so it's available to importers of Components
@_exported import SwiftKeychainWrapper

// Re-export APIKeyManager as part of the Components module's public interface
@available(iOS 13.0, *)
public typealias ComponentsAPIKeyManager = APIKeyManager

// Make sure APIKeyManager is accessible
@available(iOS 13.0, *)
public var ComponentsAPIKeyManagerShared: ComponentsAPIKeyManager {
    ComponentsAPIKeyManager.shared
}

// Export all public APIs from Components module 