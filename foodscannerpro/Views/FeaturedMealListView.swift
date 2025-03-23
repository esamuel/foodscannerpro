import SwiftUI

extension Image {
    func mealImageStyle(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        self.resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.systemGray6))
            )
    }
}

struct MealImage: View {
    let imageUrl: String
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        if UIImage(named: imageUrl) != nil {
            Image(imageUrl)
                .mealImageStyle(width: width, height: height, cornerRadius: cornerRadius)
        } else {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: width ?? height > 100 ? 40 : 20))
                        .foregroundColor(.gray)
                    
                    Text(imageUrl.replacingOccurrences(of: "_", with: " ")
                        .split(separator: " ")
                        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                        .joined(separator: " "))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 4)
                }
            }
        }
    }
}

struct FeaturedMealListView: View {
    let category: FeaturedCategory
    private let featuredMealsManager = FeaturedMealsManager.shared
    
    var body: some View {
        List(featuredMealsManager.getMealsForCategory(category)) { meal in
            NavigationLink(destination: FeaturedMealDetailView(meal: meal)) {
                HStack(spacing: 12) {
                    // Meal Image
                    MealImage(imageUrl: meal.imageUrl, width: 80, height: 80)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meal.name)
                            .font(.headline)
                        
                        Text(meal.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            NutritionBadge(label: "Cal", value: "\(Int(meal.calories))", icon: "flame.fill")
                            NutritionBadge(label: "Protein", value: "\(Int(meal.protein))g", icon: "figure.walk")
                            NutritionBadge(label: "Carbs", value: "\(Int(meal.carbs))g", icon: "leaf.fill")
                            NutritionBadge(label: "Fats", value: "\(Int(meal.fats))g", icon: "drop.fill")
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle(category.rawValue)
    }
}

struct FeaturedMealDetailView: View {
    let meal: FeaturedMeal
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Meal Image
                ZStack {
                    MealImage(imageUrl: meal.imageUrl, height: 250, cornerRadius: 0)
                    
                    VStack {
                        Spacer()
                        Text(meal.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .frame(height: 250)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Meal Description
                    Text(meal.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Nutrition Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nutrition Information")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            NutritionBadge(label: "Calories", value: "\(Int(meal.calories))", icon: "flame.fill")
                            NutritionBadge(label: "Protein", value: "\(Int(meal.protein))g", icon: "figure.walk")
                            NutritionBadge(label: "Carbs", value: "\(Int(meal.carbs))g", icon: "leaf.fill")
                            NutritionBadge(label: "Fats", value: "\(Int(meal.fats))g", icon: "drop.fill")
                        }
                    }
                    .padding(.horizontal)
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.headline)
                        
                        ForEach(meal.ingredients, id: \.self) { ingredient in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.green)
                                Text(ingredient)
                                    .font(.body)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Preparation Steps
                    if !meal.preparationSteps.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("How to Prepare")
                                .font(.headline)
                            
                            ForEach(meal.preparationSteps.indices, id: \.self) { index in
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                    Text(meal.preparationSteps[index])
                                        .font(.body)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.top)
    }
}

struct FeaturedMealListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeaturedMealListView(category: .healthyBreakfast)
        }
    }
} 