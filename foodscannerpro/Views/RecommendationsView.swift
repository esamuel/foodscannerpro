import SwiftUI

struct RecommendationsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Personalized Food Recommendations")
                        .font(.title)
                        .padding()
                    
                    // Placeholder content
                    ForEach(0..<5) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 100)
                            .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Recommendations")
        }
    }
}

#Preview {
    RecommendationsView()
} 