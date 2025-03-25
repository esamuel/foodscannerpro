//
//  FoodScannerProApp.swift
//  foodscannerpro
//
//  Created by Samuel Eskenasy on 3/12/25.
//

import SwiftUI
import CoreData

@main
struct FoodScannerProApp: App {
    let persistenceController = PersistenceController.shared
    
    // Track if onboarding has been completed
    @AppStorage("isOnboardingCompleted") private var isOnboardingCompleted: Bool = false
    
    init() {
        // Configure API key
        APIConfig.configure(withChatGPTKey: ProcessInfo.processInfo.environment["CHATGPT_API_KEY"] ?? "YOUR_CHATGPT_API_KEY")
    }
    
    var body: some Scene {
        WindowGroup {
            if isOnboardingCompleted {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            } else {
                OnboardingView(isOnboardingCompleted: $isOnboardingCompleted)
            }
        }
    }
}
