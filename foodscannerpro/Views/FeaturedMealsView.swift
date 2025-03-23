import SwiftUI

struct FeaturedMealsView: View {
    @State private var selectedCategory: FeaturedCategory = .healthyBreakfast
    private let featuredMealsManager = FeaturedMealsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Featured Meals")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            // Category Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(FeaturedCategory.allCases, id: \.self) { category in
                        NavigationLink(destination: FeaturedMealListView(category: category)) {
                            CategoryCard(category: category)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CategoryCard: View {
    let category: FeaturedCategory
    
    var body: some View {
        ZStack {
            // Background with image
            Image(category.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 180, height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            // Optional text overlay in case images don't have text
            VStack(spacing: 8) {
                Spacer()
                
                Text(category.rawValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.7), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
            }
            .padding(.horizontal)
        }
        .frame(width: 180, height: 180)
        .shadow(radius: 5)
    }
}

// Extension to add colors to FeaturedCategory
extension FeaturedCategory {
    var backgroundColor: Color {
        switch self {
        case .healthyBreakfast:
            return Color(red: 0.78, green: 1.0, blue: 0.78)  // Light green
        case .mediterraneanDiet:
            return Color(red: 0.78, green: 0.78, blue: 1.0)  // Light blue
        case .proteinRich:
            return Color(red: 1.0, green: 0.78, blue: 0.78)  // Light red
        }
    }
    
    var textColor: Color {
        switch self {
        case .healthyBreakfast:
            return Color(red: 0.2, green: 0.47, blue: 0.2)  // Dark green
        case .mediterraneanDiet:
            return Color(red: 0.2, green: 0.2, blue: 0.6)  // Dark blue
        case .proteinRich:
            return Color(red: 0.6, green: 0.2, blue: 0.2)  // Dark red
        }
    }
}

struct FeaturedMealsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeaturedMealsView()
        }
    }
} 