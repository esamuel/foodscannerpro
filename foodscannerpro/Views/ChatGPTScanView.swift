import SwiftUI

struct ChatGPTScanView: View {
    @ObservedObject var scanService: ChatGPTScanService
    @State private var image: UIImage
    @Binding var rootIsPresented: Bool
    @Binding var tabSelection: Int
    @State private var showingSaveSuccess = false
    @Environment(\.managedObjectContext) private var viewContext
    
    init(image: UIImage, scanService: ChatGPTScanService, rootIsPresented: Binding<Bool>, tabSelection: Binding<Int>) {
        self.image = image
        self.scanService = scanService
        self._rootIsPresented = rootIsPresented
        self._tabSelection = tabSelection
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Image preview with correct orientation
                    RotationCorrectedImage(image: image)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    
                    // AI badge
                    HStack {
                        Image(systemName: "brain")
                            .foregroundColor(.purple)
                        Text("ChatGPT Scan")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(20)
                    
                    // Loading indicator
                    if scanService.isScanning {
                        VStack(spacing: 15) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analyzing with AI...")
                                .font(.headline)
                            Text("Identifying foods and calculating nutrition")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else if let errorMessage = scanService.errorMessage {
                        // Error message
                        VStack(spacing: 15) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            Text("Scan Error")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button {
                                dismissToHome()
                            } label: {
                                Text("Go Back")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                        .padding()
                    } else if scanService.scanResults.isEmpty {
                        // No results
                        VStack(spacing: 15) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No foods detected")
                                .font(.headline)
                            Text("Try taking a clearer photo or from a different angle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button {
                                dismissToHome()
                            } label: {
                                Text("Go Back")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                        .padding()
                    } else {
                        // Action buttons
                        HStack(spacing: 20) {
                            Button {
                                saveToHistory()
                            } label: {
                                VStack {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 24))
                                    Text("Save")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                            }
                            
                            Button {
                                dismissToHome()
                            } label: {
                                VStack {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 24))
                                    Text("Discard")
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Results list
                        VStack(spacing: 15) {
                            ForEach(scanService.scanResults) { result in
                                ChatGPTFoodResultCard(result: result)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("AI Food Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismissToHome()
                    }
                }
            }
            .alert("Saved to History", isPresented: $showingSaveSuccess) {
                Button("OK", role: .cancel) {
                    dismissToHome()
                }
            } message: {
                Text("The food items have been saved to your history.")
            }
            .onAppear {
                // Start scanning when the view appears
                print("ChatGPTScanView appeared with image: \(image.size.width)x\(image.size.height)")
                print("scanInProgress: \(scanService.scanInProgress), scanResults: \(scanService.scanResults.count)")
                
                if !scanService.scanInProgress && scanService.scanResults.isEmpty {
                    print("Starting ChatGPT scan...")
                    // Try using the test method first to ensure it works
                    scanService.testScan()
                    // Comment out the regular scan method for now
                    // scanService.scanFoodImage(image)
                } else {
                    print("Not starting scan - already in progress or has results")
                }
            }
        }
        .interactiveDismissDisabled() // Prevent swipe to dismiss
    }
    
    private func dismissToHome() {
        // First dismiss this view
        rootIsPresented = false
        // Then set the tab selection to home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tabSelection = 0
        }
    }
    
    private func saveToHistory() {
        let meal = Meal(context: viewContext)
        meal.id = UUID()
        meal.date = Date()
        meal.name = "AI Scan \(Date().formatted(date: .abbreviated, time: .shortened))"
        
        // Save each recognized food item
        for result in scanService.scanResults {
            let food = FoodItem(context: viewContext)
            food.id = UUID()
            food.name = result.foodName
            food.calories = result.calories
            food.protein = result.protein
            food.carbs = result.carbs
            food.fats = result.fats
            
            // Save the image
            food.image = image.jpegData(compressionQuality: 0.8)
            
            meal.addToFoodItems(food)
        }
        
        do {
            try viewContext.save()
            showingSaveSuccess = true
        } catch {
            print("Error saving meal: \(error)")
        }
    }
}

struct ChatGPTFoodResultCard: View {
    let result: ChatGPTScanResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title and confidence
            HStack {
                Text(result.foodName)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.purple)
                    Text("\(Int(result.confidenceScore * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let servingSize = result.servingSize {
                Text(servingSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Nutrition data
            VStack(spacing: 15) {
                HStack(spacing: 0) {
                    NutritionInfoItem(
                        value: String(format: "%.0f", result.calories),
                        unit: "kcal",
                        label: "Calories",
                        color: .red
                    )
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    NutritionInfoItem(
                        value: String(format: "%.1fg", result.protein),
                        unit: "",
                        label: "Protein",
                        color: .blue
                    )
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    NutritionInfoItem(
                        value: String(format: "%.1fg", result.carbs),
                        unit: "",
                        label: "Carbs",
                        color: .green
                    )
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    NutritionInfoItem(
                        value: String(format: "%.1fg", result.fats),
                        unit: "",
                        label: "Fats",
                        color: .yellow
                    )
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Notes
            if let notes = result.notes {
                Text(notes)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct NutritionInfoItem: View {
    let value: String
    let unit: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RotationCorrectedImage: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: normalizedImage)
            .resizable()
    }
    
    // Process the image to correct its orientation
    private var normalizedImage: UIImage {
        // If orientation is already up, return the original
        if image.imageOrientation == .up {
            return image
        }
        
        // Calculate the new size based on orientation
        let size: CGSize
        if image.imageOrientation == .left || image.imageOrientation == .right ||
           image.imageOrientation == .leftMirrored || image.imageOrientation == .rightMirrored {
            size = CGSize(width: image.size.height, height: image.size.width)
        } else {
            size = image.size
        }
        
        // Create a new context with the correct size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        guard let context = UIGraphicsGetCurrentContext() else {
            return image
        }
        
        // Set up the transform based on orientation
        context.translateBy(x: size.width/2, y: size.height/2)
        
        switch image.imageOrientation {
        case .down, .downMirrored:
            context.rotate(by: .pi)
        case .left, .leftMirrored:
            context.rotate(by: .pi/2)
        case .right, .rightMirrored:
            context.rotate(by: -.pi/2)
        default:
            break
        }
        
        // Handle mirroring
        if image.imageOrientation.rawValue > 4 {
            context.scaleBy(x: -1, y: 1)
        }
        
        // Move back to draw from top-left
        context.translateBy(x: -image.size.width/2, y: -image.size.height/2)
        
        // Draw the image
        image.draw(at: .zero)
        
        // Get the normalized image
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? image
    }
} 