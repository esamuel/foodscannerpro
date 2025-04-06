import SwiftUI
import CoreData

struct RecommendationsView: View {
    @StateObject private var contentManager = ContentManager.shared
    @State private var selectedCategory = RecommendationCategory.all
    @State private var recommendations: [FoodRecommendation] = []
    @State private var selectedRecommendation: FoodRecommendation?
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                } else if recommendations.isEmpty {
                    EmptyStateView()
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
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadRecommendations()
            }
        }
    }
    
    private func loadRecommendations() {
        Task {
            do {
                recommendations = try await contentManager.getPersonalizedRecommendations()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
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

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.green)
            Text("No Recommendations")
                .font(.title2)
                .bold()
            Text("Try refreshing or changing your dietary preferences")
                .foregroundColor(.secondary)
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