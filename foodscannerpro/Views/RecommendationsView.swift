import SwiftUI
import CoreData

struct RecommendationsView: View {
    @StateObject private var contentManager = ContentManager.shared
    @StateObject private var automatedService = AutomatedContentService.shared
    @State private var selectedCategory = RecommendationCategory.all
    @State private var recommendations: [FoodRecommendation] = []
    @State private var selectedRecommendation: FoodRecommendation?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingDiagnostics = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var filteredRecommendations: [FoodRecommendation] {
        if selectedCategory == .all {
            return recommendations
        }
        return recommendations.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Network Status Indicator
                if !automatedService.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.red)
                        Text("No Internet Connection")
                            .font(.callout)
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                }
                
                // Category Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(RecommendationCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                if contentManager.isLoading {
                    ProgressView("Loading recommendations...")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if recommendations.isEmpty {
                    EmptyStateView(
                        networkConnected: automatedService.isConnected,
                        errorMessage: automatedService.lastNetworkError ?? "",
                        onRetry: loadRecommendations
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(filteredRecommendations) { recommendation in
                                NavigationLink(destination: RecommendationDetailView(recommendation: recommendation)) {
                                    RecommendationCard(recommendation: recommendation)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recommendations")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: loadRecommendations) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingDiagnostics = true }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingDiagnostics) {
                DiagnosticsView(
                    networkConnected: automatedService.isConnected,
                    lastAPIURL: automatedService.lastRequestURL ?? "None",
                    lastAPIError: automatedService.lastNetworkError ?? "None",
                    onClose: { showingDiagnostics = false }
                )
            }
            .task {
                await loadRecommendations()
            }
        }
    }
    
    private func loadRecommendations() {
        Task {
            do {
                // Reset error state
                automatedService.lastNetworkError = nil
                
                // Attempt to get recommendations
                recommendations = try await contentManager.getPersonalizedRecommendations()
                
                if recommendations.isEmpty && automatedService.lastNetworkError != nil {
                    errorMessage = "Failed to load recommendations: \(automatedService.lastNetworkError ?? "Unknown error")"
                    showError = true
                }
            } catch {
                recommendations = []
                errorMessage = "Error: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

struct DiagnosticsView: View {
    let networkConnected: Bool
    let lastAPIURL: String
    let lastAPIError: String
    let onClose: () -> Void
    @State private var apiKeysStatus = [String: Bool]()
    @State private var apiConnectivity = [String: Bool]()
    @State private var isTestingAPI = false
    @StateObject private var contentManager = ContentManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Network Status")) {
                    HStack {
                        Text("Internet Connection")
                        Spacer()
                        if networkConnected {
                            Label("Connected", systemImage: "wifi")
                                .foregroundColor(.green)
                        } else {
                            Label("Disconnected", systemImage: "wifi.slash")
                                .foregroundColor(.red)
                        }
                    }
                    
                    if let diagnosticInfo = contentManager.diagnosticInfo {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Diagnostic Information")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(diagnosticInfo)
                                .font(.body)
                                .lineLimit(5)
                        }
                    }
                }
                
                Section(header: Text("API Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last API URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastAPIURL)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last API Error")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(lastAPIError)
                            .font(.body)
                            .foregroundColor(lastAPIError == "None" ? .green : .red)
                            .lineLimit(5)
                    }
                }
                
                Section(header: Text("API Keys Check")) {
                    Button("Check API Keys") {
                        validateAPIKeys()
                    }
                    
                    if !apiKeysStatus.isEmpty {
                        ForEach(Array(apiKeysStatus.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()
                                Image(systemName: apiKeysStatus[key] == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(apiKeysStatus[key] == true ? .green : .red)
                            }
                        }
                    }
                }
                
                Section(header: Text("API Connectivity Test")) {
                    if isTestingAPI {
                        ProgressView("Testing API connectivity...")
                    } else {
                        Button("Test API Connectivity") {
                            testAPIConnectivity()
                        }
                    }
                    
                    if !apiConnectivity.isEmpty {
                        ForEach(Array(apiConnectivity.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                Spacer()
                                if apiConnectivity[key] == true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button("Clear Cache") {
                        // Add cache clearing logic
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onClose()
                    }
                }
            }
        }
    }
    
    private func validateAPIKeys() {
        let edamamKey = APIConfig.edamamAPIKey
        let edamamAppID = APIConfig.edamamAppID
        let spoonacularKey = APIConfig.spoonacularAPIKey
        let unsplashKey = APIConfig.unsplashAPIKey
        
        apiKeysStatus["Edamam API Key"] = !edamamKey.isEmpty && !edamamKey.contains("YOUR_")
        apiKeysStatus["Edamam App ID"] = !edamamAppID.isEmpty && !edamamAppID.contains("YOUR_")
        apiKeysStatus["Spoonacular API Key"] = !spoonacularKey.isEmpty && !spoonacularKey.contains("YOUR_")
        apiKeysStatus["Unsplash API Key"] = !unsplashKey.isEmpty && !unsplashKey.contains("YOUR_")
    }
    
    private func testAPIConnectivity() {
        // Set loading state
        isTestingAPI = true
        
        // Run API connectivity test
        Task {
            apiConnectivity = await contentManager.testAPIConnectivity()
            isTestingAPI = false
        }
    }
}

struct EmptyStateView: View {
    let networkConnected: Bool
    let errorMessage: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if !networkConnected {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                Text("No Internet Connection")
                    .font(.title2)
                    .bold()
                Text("Check your connection and try again")
                    .foregroundColor(.secondary)
            } else if !errorMessage.isEmpty {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                Text("Error Loading Recommendations")
                    .font(.title2)
                    .bold()
                Text(errorMessage)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Image(systemName: "fork.knife.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                Text("No Recommendations")
                    .font(.title2)
                    .bold()
                Text("Try refreshing or changing your dietary preferences")
                    .foregroundColor(.secondary)
            }
            
            Button(action: onRetry) {
                Text("Try Again")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CategoryButton: View {
    let category: RecommendationCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.rawValue)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct RecommendationCard: View {
    let recommendation: FoodRecommendation
    @State private var image: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image loading with AsyncImage
            AsyncImage(url: URL(string: recommendation.image)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 150)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 150)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                        .foregroundColor(.gray)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.foodName)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("\(Int(recommendation.nutritionInfo.calories)) cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if !recommendation.dietaryWarnings.isEmpty {
                    Label("Dietary Warnings", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct RecommendationDetailView: View {
    let recommendation: FoodRecommendation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Food Image
                AsyncImage(url: URL(string: recommendation.image)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxHeight: 300)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                
                VStack(alignment: .leading, spacing: 24) {
                    // Nutrition Information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrition Information")
                            .font(.title2)
                            .bold()
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            NutritionItem(label: "Calories", value: "\(Int(recommendation.nutritionInfo.calories))")
                            NutritionItem(label: "Protein", value: "\(Int(recommendation.nutritionInfo.protein))g")
                            NutritionItem(label: "Carbs", value: "\(Int(recommendation.nutritionInfo.carbs))g")
                            NutritionItem(label: "Fat", value: "\(Int(recommendation.nutritionInfo.fat))g")
                            if let fiber = recommendation.nutritionInfo.fiber {
                                NutritionItem(label: "Fiber", value: "\(Int(fiber))g")
                            }
                            if let sugar = recommendation.nutritionInfo.sugar {
                                NutritionItem(label: "Sugar", value: "\(Int(sugar))g")
                            }
                        }
                    }
                    
                    // Health Benefits
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Benefits")
                            .font(.title2)
                            .bold()
                        
                        Text(recommendation.recommendationReason ?? "")
                            .foregroundColor(.secondary)
                    }
                    
                    // Dietary Warnings
                    if !recommendation.dietaryWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Dietary Considerations")
                                .font(.title2)
                                .bold()
                            
                            ForEach(recommendation.dietaryWarnings, id: \.self) { warning in
                                Label(warning.message, systemImage: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(recommendation.foodName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NutritionItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
    }
}

#Preview {
    RecommendationsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 