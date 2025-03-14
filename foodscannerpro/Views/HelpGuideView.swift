import SwiftUI

struct HelpGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSection = 0
    
    // Help sections
    private let sections = [
        "Getting Started",
        "Scanning Food",
        "Nutrition Tracking",
        "Recommendations",
        "Profile Settings",
        "Troubleshooting"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Section picker
                Picker("Section", selection: $selectedSection) {
                    ForEach(0..<sections.count, id: \.self) { index in
                        Text(sections[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content for selected section
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedSection {
                        case 0:
                            gettingStartedSection
                        case 1:
                            scanningFoodSection
                        case 2:
                            nutritionTrackingSection
                        case 3:
                            recommendationsSection
                        case 4:
                            profileSettingsSection
                        case 5:
                            troubleshootingSection
                        default:
                            gettingStartedSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Help Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Section Content
    
    private var gettingStartedSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpItem(
                title: "Welcome to Food Scanner Pro",
                description: "Food Scanner Pro helps you identify food items, track nutrition, and get personalized recommendations.",
                icon: "app.fill"
            )
            
            helpItem(
                title: "Main Features",
                description: "• Scan food with your camera\n• Track nutrition intake\n• Get personalized recommendations\n• View detailed analytics\n• Maintain a meal history",
                icon: "star.fill"
            )
            
            helpItem(
                title: "Navigation",
                description: "Use the tab bar at the bottom to navigate between different sections of the app. The center camera button is for quick food scanning.",
                icon: "arrow.left.and.right"
            )
            
            helpItem(
                title: "First Steps",
                description: "1. Set up your health profile\n2. Scan your first food item\n3. Explore your nutrition analytics\n4. Check personalized recommendations",
                icon: "1.circle.fill"
            )
        }
    }
    
    private var scanningFoodSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpItem(
                title: "Camera Scanning",
                description: "Tap the camera button in the center of the tab bar to open the camera. Position your food in the frame and tap the capture button.",
                icon: "camera.fill"
            )
            
            helpItem(
                title: "Gallery Import",
                description: "You can also select photos from your gallery by tapping 'From Gallery' on the home screen.",
                icon: "photo.on.rectangle"
            )
            
            helpItem(
                title: "Recognition Results",
                description: "After scanning, you'll see the recognized food items with their nutrition information. You can save these to your meal history.",
                icon: "doc.text.magnifyingglass"
            )
            
            helpItem(
                title: "Camera Tips",
                description: "• Ensure good lighting\n• Position food clearly in frame\n• Use the guide frame for better results\n• Try different angles if needed",
                icon: "lightbulb.fill"
            )
        }
    }
    
    private var nutritionTrackingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpItem(
                title: "Nutrition Analytics",
                description: "The Analytics tab shows your nutrition trends, macronutrient distribution, and health insights based on your meal history.",
                icon: "chart.bar.fill"
            )
            
            helpItem(
                title: "Meal History",
                description: "The History tab shows all your saved meals. You can filter by date range and meal type, and search for specific foods.",
                icon: "clock.fill"
            )
            
            helpItem(
                title: "Tracking Progress",
                description: "Regular scanning and saving of meals helps build a comprehensive picture of your nutrition habits over time.",
                icon: "chart.line.uptrend.xyaxis"
            )
            
            helpItem(
                title: "Health Insights",
                description: "The app generates insights based on your eating patterns and health profile, helping you make better nutrition choices.",
                icon: "heart.text.square.fill"
            )
        }
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpItem(
                title: "Personalized Recommendations",
                description: "The Recommendations tab provides food suggestions based on your health profile, dietary goals, and eating patterns.",
                icon: "heart.fill"
            )
            
            helpItem(
                title: "Dietary Restrictions",
                description: "Recommendations take into account any health conditions or dietary restrictions you've set in your profile.",
                icon: "exclamationmark.shield.fill"
            )
            
            helpItem(
                title: "Nutritional Benefits",
                description: "Each recommendation includes information about its nutritional benefits and why it's suitable for your goals.",
                icon: "leaf.fill"
            )
            
            helpItem(
                title: "Refreshing Recommendations",
                description: "Tap the refresh button to generate new recommendations based on your latest profile and meal history.",
                icon: "arrow.clockwise"
            )
        }
    }
    
    private var profileSettingsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpItem(
                title: "Health Profile",
                description: "Set up your personal information, health conditions, and dietary goals in the Profile tab to get the most accurate recommendations.",
                icon: "person.fill"
            )
            
            helpItem(
                title: "Dietary Goals",
                description: "Select your primary dietary goal (weight loss, muscle gain, etc.) to receive tailored nutrition targets and food recommendations.",
                icon: "target"
            )
            
            helpItem(
                title: "Health Conditions",
                description: "Add any health conditions or dietary restrictions to receive appropriate warnings about foods that may not be suitable for you.",
                icon: "heart.circle.fill"
            )
            
            helpItem(
                title: "App Settings",
                description: "Customize app behavior, notification preferences, and access help resources in the Profile tab.",
                icon: "gearshape.fill"
            )
        }
    }
    
    private var troubleshootingSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            helpItem(
                title: "Camera Access Issues",
                description: "If the app can't access your camera, go to your device Settings > Privacy > Camera and ensure Food Scanner Pro has permission.",
                icon: "camera.metering.unknown"
            )
            
            helpItem(
                title: "Photo Library Access",
                description: "To import photos, the app needs access to your photo library. Check Settings > Privacy > Photos to grant permission.",
                icon: "photo.fill"
            )
            
            helpItem(
                title: "Recognition Problems",
                description: "If food recognition is inaccurate, try taking photos with better lighting, clearer focus, and positioning food items more prominently in the frame.",
                icon: "questionmark.circle.fill"
            )
            
            helpItem(
                title: "Data Not Saving",
                description: "If your meals aren't saving to history, ensure you have sufficient storage space on your device and that you're tapping the 'Save to History' button after scanning.",
                icon: "externaldrive.fill.badge.exclamationmark"
            )
            
            helpItem(
                title: "Contact Support",
                description: "If you're experiencing issues not covered here, please contact our support team through the Profile tab.",
                icon: "envelope.fill"
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func helpItem(title: String, description: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.green)
                    .frame(width: 30)
                
                Text(title)
                    .font(.headline)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 40)
        }
        .padding(.vertical, 5)
    }
}

struct HelpGuideView_Previews: PreviewProvider {
    static var previews: some View {
        HelpGuideView()
    }
} 