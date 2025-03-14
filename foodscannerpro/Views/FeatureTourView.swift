import SwiftUI

struct FeatureTourView: View {
    @Binding var isShowingTour: Bool
    @State private var currentStep = 0
    
    private let tourSteps = [
        TourStep(
            title: "Welcome to Food Scanner Pro!",
            description: "Let's take a quick tour of the app's features.",
            icon: "camera.fill"
        ),
        TourStep(
            title: "Scan Food",
            description: "Use the camera to scan food items and get instant nutrition information.",
            icon: "camera.viewfinder"
        ),
        TourStep(
            title: "Track Nutrition",
            description: "View detailed nutrition information and track your daily intake.",
            icon: "chart.bar.fill"
        ),
        TourStep(
            title: "Get Recommendations",
            description: "Receive personalized food recommendations based on your goals.",
            icon: "heart.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                if currentStep < tourSteps.count {
                    let step = tourSteps[currentStep]
                    
                    Image(systemName: step.icon)
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                        .padding()
                    
                    Text(step.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(step.description)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<tourSteps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? Color.green : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top)
                    
                    Button(action: {
                        if currentStep < tourSteps.count - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            withAnimation {
                                isShowingTour = false
                            }
                        }
                    }) {
                        Text(currentStep < tourSteps.count - 1 ? "Next" : "Get Started")
                            .fontWeight(.semibold)
                            .frame(width: 200)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
    }
}

struct TourStep {
    let title: String
    let description: String
    let icon: String
} 