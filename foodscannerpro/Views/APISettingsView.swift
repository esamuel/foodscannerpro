import SwiftUI
import Components

@MainActor
struct APISettingsView: View {
    @StateObject private var apiKeyManager = APIKeyManager.shared
    @State private var chatGPTKey: String = ""
    @State private var clarifaiKey: String = ""
    @State private var logMealKey: String = ""
    @State private var usdaKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("CHATGPT API KEY")) {
                    SecureField("Enter your API key", text: $chatGPTKey)
                    if apiKeyManager.hasValidChatGPTKey() {
                        Text("✓ Key is set")
                            .foregroundColor(.green)
                    } else {
                        Text("Get your key from OpenAI")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("CLARIFAI API KEY")) {
                    SecureField("Enter your API key", text: $clarifaiKey)
                    if apiKeyManager.hasValidClarifaiKey() {
                        Text("✓ Key is set")
                            .foregroundColor(.green)
                    } else {
                        Text("Get your key from")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("LOGMEAL API KEY")) {
                    SecureField("Enter your API key", text: $logMealKey)
                    if apiKeyManager.hasValidLogMealKey() {
                        Text("✓ Key is set")
                            .foregroundColor(.green)
                    } else {
                        Text("Get your key from")
                            .foregroundColor(.blue)
                    }
                }
                
                Section(header: Text("USDA FOOD DATA CENTRAL API KEY")) {
                    SecureField("Enter your API key", text: $usdaKey)
                    if apiKeyManager.hasValidUsdaKey() {
                        Text("✓ Key is set")
                            .foregroundColor(.green)
                    } else {
                        Text("Get your key from")
                            .foregroundColor(.blue)
                    }
                }
                
                Button("Save API Keys") {
                    var success = false
                    var successMessage = "API Keys updated:"
                    
                    if !chatGPTKey.isEmpty {
                        if apiKeyManager.updateChatGPTAPIKey(chatGPTKey) {
                            successMessage += "\n✓ ChatGPT API key"
                            success = true
                        }
                    }
                    
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
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                
                Section(header: Text("Note")) {
                    Text("Your API keys are stored securely in the device's Keychain.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("API Key Setup")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("API Keys"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK")) {
                        if alertMessage.contains("updated") {
                            dismiss()
                        }
                    }
                )
            }
            .onAppear {
                // Load existing API keys if available
                if apiKeyManager.hasValidChatGPTKey() {
                    chatGPTKey = apiKeyManager.chatGPTAPIKey
                }
                
                if apiKeyManager.hasValidClarifaiKey() {
                    clarifaiKey = apiKeyManager.clarifaiAPIKey
                }
                
                if apiKeyManager.hasValidLogMealKey() {
                    logMealKey = apiKeyManager.logMealAPIKey
                }
                
                if apiKeyManager.hasValidUsdaKey() {
                    usdaKey = apiKeyManager.usdaAPIKey
                }
            }
        }
    }
} 