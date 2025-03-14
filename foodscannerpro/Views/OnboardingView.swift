import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingCompleted: Bool
    @State private var currentPage = 0
    
    // Onboarding pages content
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Food Scanner Pro",
            description: "Your personal food recognition and nutrition assistant. Let's get started!",
            imageName: "fork.knife.circle.fill",
            backgroundColor: .green
        ),
        OnboardingPage(
            title: "Scan Food Items",
            description: "Take a photo or select from your gallery to instantly identify food and get nutrition information.",
            imageName: "camera.fill",
            backgroundColor: .blue
        ),
        OnboardingPage(
            title: "Track Your Nutrition",
            description: "Keep track of your meals and monitor your nutrition intake over time.",
            imageName: "chart.bar.fill",
            backgroundColor: .orange
        ),
        OnboardingPage(
            title: "Get Personalized Recommendations",
            description: "Receive food recommendations based on your health profile and dietary goals.",
            imageName: "heart.fill",
            backgroundColor: .red
        ),
        OnboardingPage(
            title: "Set Up Your Profile",
            description: "Customize your health profile to get the most accurate recommendations.",
            imageName: "person.fill",
            backgroundColor: .purple
        )
    ]
    
    var body: some View {
        ZStack {
            // Background color that changes with the page
            pages[currentPage].backgroundColor
                .opacity(0.2)
                .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation {
                            isOnboardingCompleted = true
                        }
                    }
                    .padding()
                    .foregroundColor(.primary)
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Navigation buttons
                HStack {
                    // Back button (hidden on first page)
                    Button(action: {
                        withAnimation {
                            currentPage = max(currentPage - 1, 0)
                        }
                    }) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(currentPage > 0 ? pages[currentPage].backgroundColor : .gray)
                    }
                    .disabled(currentPage == 0)
                    .opacity(currentPage > 0 ? 1.0 : 0.0)
                    
                    Spacer()
                    
                    // Next/Get Started button
                    Button(action: {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                isOnboardingCompleted = true
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .fontWeight(.bold)
                            
                            Image(systemName: currentPage < pages.count - 1 ? "arrow.right" : "checkmark")
                        }
                        .padding()
                        .background(pages[currentPage].backgroundColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
}

// Individual onboarding page view
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundColor(page.backgroundColor)
                .padding()
            
            // Title
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Description
            Text(page.description)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Onboarding page model
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(isOnboardingCompleted: .constant(false))
    }
} 