import SwiftUI
import Vision
import CoreML

public struct FoodAnalysisTestView: View {
    @StateObject private var viewModel = FoodAnalysisViewModel(modelNames: ["FoodClassifier"])
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Label("Select Food Image", systemImage: "photo.fill")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                if viewModel.isAnalyzing {
                    ProgressView("Analyzing...")
                } else if !viewModel.analysisResults.isEmpty {
                    ResultsView(results: viewModel.analysisResults)
                }
                
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Food Analysis Test")
            .sheet(isPresented: $showingImagePicker) {
                ModernImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            .onChange(of: selectedImage) { oldImage, newImage in
                if let image = newImage {
                    analyzeImage(image)
                }
            }
            .task {
                await viewModel.initialize()
            }
        }
    }
    
    private func analyzeImage(_ image: UIImage) {
        Task {
            await viewModel.analyzeFood(image: image)
        }
    }
}

private struct ResultsView: View {
    let results: [FoodClassificationResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Analysis Results:")
                .font(.headline)
            
            ForEach(results.prefix(5)) { result in
                HStack {
                    Text(result.label)
                        .fontWeight(result.isReliable ? .bold : .regular)
                    Spacer()
                    Text(result.confidencePercentage)
                        .foregroundColor(result.isReliable ? .green : .gray)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    FoodAnalysisTestView()
} 