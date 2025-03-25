import SwiftUI
import UIKit
import Components

struct VisionTestView: View {
    @StateObject private var visionService = ChatGPTVisionService()
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var analysisResult: ChatGPTVisionService.VisionAnalysisResult?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        Text(selectedImage == nil ? "Select Food Image" : "Change Image")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if isAnalyzing {
                        ProgressView("Analyzing image...")
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    if let result = analysisResult {
                        ResultView(result: result)
                    }
                }
                .padding()
            }
            .navigationTitle("Vision API Test")
            .sheet(isPresented: $isImagePickerPresented) {
                ModernImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    analyzeImage(image)
                }
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await visionService.analyzeImage(image)
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                }
            }
        }
    }
}

struct ResultView: View {
    let result: ChatGPTVisionService.VisionAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Group {
                TitleRow(title: "Food Name", value: result.foodName)
                
                NutritionSection(nutrition: result.nutritionInfo)
                
                if !result.healthConsiderations.isEmpty {
                    TitleRow(title: "Health Considerations", value: result.healthConsiderations.joined(separator: ", "))
                }
                
                if !result.allergyWarnings.isEmpty {
                    TitleRow(title: "⚠️ Allergy Warnings", value: result.allergyWarnings.joined(separator: ", "))
                }
                
                if let gi = result.glycemicIndex {
                    TitleRow(title: "Glycemic Index", value: "\(gi)")
                }
                
                TitleRow(title: "Diabetes Friendly", value: result.diabetesFriendly ? "Yes" : "No")
                
                if let prep = result.preparationMethod {
                    TitleRow(title: "Preparation", value: prep)
                }
                
                if let fresh = result.freshness {
                    TitleRow(title: "Freshness", value: fresh)
                }
                
                if let portion = result.portionSize {
                    TitleRow(title: "Portion Size", value: portion)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct NutritionSection: View {
    let nutrition: ChatGPTVisionService.VisionAnalysisResult.NutritionInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nutrition Information")
                .font(.headline)
            
            Group {
                NutritionRow(title: "Calories", value: "\(nutrition.calories) kcal")
                NutritionRow(title: "Protein", value: String(format: "%.1fg", nutrition.protein))
                NutritionRow(title: "Carbs", value: String(format: "%.1fg", nutrition.carbs))
                NutritionRow(title: "Fats", value: String(format: "%.1fg", nutrition.fats))
                
                if let fiber = nutrition.fiber {
                    NutritionRow(title: "Fiber", value: String(format: "%.1fg", fiber))
                }
                
                if let sugar = nutrition.sugar {
                    NutritionRow(title: "Sugar", value: String(format: "%.1fg", sugar))
                }
            }
            
            if !nutrition.vitamins.isEmpty {
                Text("Vitamins")
                    .font(.subheadline)
                    .padding(.top, 5)
                
                ForEach(Array(nutrition.vitamins.keys.sorted()), id: \.self) { vitamin in
                    if let value = nutrition.vitamins[vitamin] {
                        NutritionRow(title: vitamin, value: String(format: "%.1f", value))
                    }
                }
            }
            
            if !nutrition.minerals.isEmpty {
                Text("Minerals")
                    .font(.subheadline)
                    .padding(.top, 5)
                
                ForEach(Array(nutrition.minerals.keys.sorted()), id: \.self) { mineral in
                    if let value = nutrition.minerals[mineral] {
                        NutritionRow(title: mineral, value: String(format: "%.1f", value))
                    }
                }
            }
        }
    }
}

struct TitleRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
} 