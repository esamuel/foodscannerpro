import SwiftUI
import Components

struct APISettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var apiKeyManager = APIKeyManager.shared
    
    @State private var clarifaiKey: String = ""
    @State private var logMealKey: String = ""
    @State private var usdaKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Keys")) {
                    SecureField("Clarifai API Key", text: $clarifaiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                    if apiKeyManager.hasValidClarifaiKey() {
                        Text("✓ Key is set")
                            .foregroundColor(.green)
                    }
                    
                    SecureField("LogMeal API Key", text: $logMealKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                    if apiKeyManager.hasValidLogMealKey() {
                        Text("✓ Key is set")
                            .foregroundColor(.green)
                    }
                    
                    SecureField("USDA API Key", text: $usdaKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                    if apiKeyManager.hasValidUsdaKey() {
                        Text("✓ Key is set")
                            .foregroundColor(.green)
                    }
                }
                
                Section {
                    Button(action: saveAPIKeys) {
                        Text("Save API Keys")
                    }
                    
                    Button(action: clearAPIKeys) {
                        Text("Clear All API Keys")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("API Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("API Keys"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: loadAPIKeys)
        }
    }
    
    private func loadAPIKeys() {
        clarifaiKey = apiKeyManager.clarifaiAPIKey
        logMealKey = apiKeyManager.logMealAPIKey
        usdaKey = apiKeyManager.usdaAPIKey
    }
    
    private func saveAPIKeys() {
        var success = false
        var successMessage = "API Keys updated:"
        
        if !clarifaiKey.isEmpty {
            if apiKeyManager.updateClarifaiAPIKey(clarifaiKey) {
                successMessage += "\n✓ Clarifai API key"
                success = true
            }
        }
        
        if !logMealKey.isEmpty {
            if apiKeyManager.updateLogMealAPIKey(logMealKey) {
                successMessage += "\n✓ LogMeal API key"
                success = true
            }
        }
        
        if !usdaKey.isEmpty {
            if apiKeyManager.updateUSDAAPIKey(usdaKey) {
                successMessage += "\n✓ USDA API key"
                success = true
            }
        }
        
        alertMessage = success ? successMessage : "No API keys were updated."
        showingAlert = true
    }
    
    private func clearAPIKeys() {
        apiKeyManager.clearAllAPIKeys()
        clarifaiKey = ""
        logMealKey = ""
        usdaKey = ""
        
        alertMessage = "All API keys have been cleared."
        showingAlert = true
    }
} 
