import Foundation
import UIKit

/// A class to manage API keys for the Food Scanner Pro app
class APIKeyManager {
    
    /// Shared instance for singleton access
    static let shared = APIKeyManager()
    
    // UserDefaults keys
    private let clarifaiKeyKey = "com.foodscannerpro.clarifaiAPIKey"
    private let logMealKeyKey = "com.foodscannerpro.logMealAPIKey"
    private let usdaKeyKey = "com.foodscannerpro.usdaAPIKey"
    
    // Default API keys
    private var defaultClarifaiKey = "YOUR_CLARIFAI_API_KEY"
    private var defaultLogMealKey = "YOUR_LOGMEAL_API_KEY"
    private var defaultUsdaKey = "DEMO_KEY"
    
    /// Initialization
    private init() {
        // Nothing to initialize
    }
    
    /// Get the Clarifai API key
    var clarifaiAPIKey: String {
        return UserDefaults.standard.string(forKey: clarifaiKeyKey) ?? defaultClarifaiKey
    }
    
    /// Get the LogMeal API key
    var logMealAPIKey: String {
        return UserDefaults.standard.string(forKey: logMealKeyKey) ?? defaultLogMealKey
    }
    
    /// Get the USDA API key
    var usdaAPIKey: String {
        return UserDefaults.standard.string(forKey: usdaKeyKey) ?? defaultUsdaKey
    }
    
    /// Update the Clarifai API key
    /// - Parameter key: The API key to set
    /// - Returns: True if successful, false otherwise
    func updateClarifaiAPIKey(_ key: String) -> Bool {
        UserDefaults.standard.set(key, forKey: clarifaiKeyKey)
        return true
    }
    
    /// Update the LogMeal API key
    /// - Parameter key: The API key to set
    /// - Returns: True if successful, false otherwise
    func updateLogMealAPIKey(_ key: String) -> Bool {
        UserDefaults.standard.set(key, forKey: logMealKeyKey)
        return true
    }
    
    /// Update the USDA API key
    /// - Parameter key: The API key to set
    /// - Returns: True if successful, false otherwise
    func updateUSDAAPIKey(_ key: String) -> Bool {
        UserDefaults.standard.set(key, forKey: usdaKeyKey)
        return true
    }
}

// MARK: - UI Extension

extension APIKeyManager {
    
    /// Present an API key setup view controller
    /// - Parameter viewController: The view controller to present from
    func presentAPIKeySetupView(from viewController: UIViewController) {
        let alertController = UIAlertController(title: "API Key Setup", 
                                               message: "Enter your API keys for external services", 
                                               preferredStyle: .alert)
        
        // Clarifai API Key
        alertController.addTextField { textField in
            textField.placeholder = "Clarifai API Key"
            textField.text = self.clarifaiAPIKey != self.defaultClarifaiKey ? self.clarifaiAPIKey : ""
        }
        
        // LogMeal API Key
        alertController.addTextField { textField in
            textField.placeholder = "LogMeal API Key"
            textField.text = self.logMealAPIKey != self.defaultLogMealKey ? self.logMealAPIKey : ""
        }
        
        // USDA API Key
        alertController.addTextField { textField in
            textField.placeholder = "USDA Food Data Central API Key"
            textField.text = self.usdaAPIKey != self.defaultUsdaKey ? self.usdaAPIKey : ""
        }
        
        // Add Save action
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self, weak alertController] _ in
            guard let self = self, let alertController = alertController else { return }
            
            // Get text fields
            let textFields = alertController.textFields!
            let clarifaiKey = textFields[0].text ?? ""
            let logMealKey = textFields[1].text ?? ""
            let usdaKey = textFields[2].text ?? ""
            
            // Update API keys
            var successMessage = "API Keys updated:"
            var success = false
            
            if !clarifaiKey.isEmpty {
                if self.updateClarifaiAPIKey(clarifaiKey) {
                    successMessage += "\n✓ Clarifai API key"
                    success = true
                }
            }
            
            if !logMealKey.isEmpty {
                if self.updateLogMealAPIKey(logMealKey) {
                    successMessage += "\n✓ LogMeal API key"
                    success = true
                }
            }
            
            if !usdaKey.isEmpty {
                if self.updateUSDAAPIKey(usdaKey) {
                    successMessage += "\n✓ USDA API key"
                    success = true
                }
            }
            
            // Show result
            let resultAlert = UIAlertController(
                title: success ? "Success" : "No Changes",
                message: success ? successMessage : "No API keys were updated.",
                preferredStyle: .alert
            )
            resultAlert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(resultAlert, animated: true)
        }
        
        // Add Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Add actions to alert controller
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        // Present alert controller
        viewController.present(alertController, animated: true)
    }
} 