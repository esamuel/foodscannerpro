import SwiftUI
import Vision
import CoreML

struct VisionTestView: View {
    @StateObject private var classifier = FoodClassifier()
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingRecognition = false
    
    var body: some View {
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
                
                if classifier.isProcessing {
                    ProgressView("Analyzing...")
                } else if !classifier.recognizedObjects.isEmpty {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(classifier.recognizedObjects) { food in
                                FoodItemCard(food: food)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Vision Test")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { oldValue, newImage in
                if let image = newImage {
                    classifier.analyzeImage(image)
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    VisionTestView()
} 