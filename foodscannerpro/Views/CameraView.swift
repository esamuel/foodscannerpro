import SwiftUI
import AVFoundation

struct CameraView: View {
    @Binding var tabSelection: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var chatGPTScanService = ChatGPTScanService()
    @State private var showingSettings = false
    @State private var recognitionMode: RecognitionMode = .standard
    @State private var capturedImage: UIImage?
    @State private var showingRecognition = false
    @State private var showingChatGPTScan = false
    @State private var isGalleryPickerPresented = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Camera preview
                    CameraPreviewView(session: cameraManager.session)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Camera controls
                    VStack(spacing: 20) {
                        // Mode selector buttons
                        HStack(spacing: 20) {
                            // Gallery button
                            Button(action: {
                                isGalleryPickerPresented = true
                            }) {
                                VStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 20))
                                    Text("Gallery")
                                        .font(.caption2)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(10)
                            }
                            
                            // ChatGPT Scan button
                            Button(action: {
                                // Capture image and show ChatGPT scan
                                cameraManager.capturePhoto { image in
                                    if let image = image {
                                        capturedImage = image
                                        showingChatGPTScan = true
                                    }
                                }
                            }) {
                                VStack {
                                    Image(systemName: "brain")
                                        .font(.system(size: 20))
                                    Text("AI Scan")
                                        .font(.caption2)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.purple.opacity(0.7))
                                .cornerRadius(10)
                            }
                        }
                        
                        // Main camera controls
                        HStack {
                            Button(action: dismiss.callAsFunction) {
                                Image(systemName: "xmark")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                cameraManager.capturePhoto { image in
                                    if let image = image {
                                        capturedImage = image
                                        // Show the recognition view with the captured image
                                        showingRecognition = true
                                    }
                                }
                            }) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                            .frame(width: 80, height: 80)
                                    )
                            }
                            
                            Spacer()
                            
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
            .sheet(isPresented: $showingSettings) {
                RecognitionSettingsView(selectedMode: $recognitionMode)
            }
            .fullScreenCover(isPresented: $showingRecognition) {
                if let image = capturedImage {
                    FoodRecognitionView(image: image, classifier: FoodClassifier(), rootIsPresented: $showingRecognition, tabSelection: $tabSelection)
                }
            }
            .fullScreenCover(isPresented: $showingChatGPTScan) {
                if let image = capturedImage {
                    ChatGPTScanView(image: image, scanService: chatGPTScanService, rootIsPresented: $showingChatGPTScan, tabSelection: $tabSelection)
                }
            }
            .sheet(isPresented: $isGalleryPickerPresented) {
                ImagePicker(selectedImage: $capturedImage, isPresented: $isGalleryPickerPresented) { success in
                    if success, capturedImage != nil {
                        // Default to regular recognition for gallery images
                        showingRecognition = true
                    }
                }
            }
            .onAppear {
                // Start the camera when the view appears
                cameraManager.start()
            }
            .onDisappear {
                // Stop the camera when the view disappears
                cameraManager.stop()
            }
        }
    }
}

// Add ImagePicker for gallery selection
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    var onDismiss: (Bool) -> Void
    
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
                parent.selectedImage = image
                parent.isPresented = false
                parent.onDismiss(true)
            } else {
                parent.onDismiss(false)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
            parent.onDismiss(false)
        }
    }
}

// Add RecognitionSettingsView
struct RecognitionSettingsView: View {
    @Binding var selectedMode: RecognitionMode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Recognition Mode")) {
                    Picker("Mode", selection: $selectedMode) {
                        ForEach(RecognitionMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Description")) {
                    switch selectedMode {
                    case .standard:
                        Text("Standard mode uses basic image recognition for common food items.")
                    case .enhanced:
                        Text("Enhanced mode uses advanced algorithms for more accurate recognition.")
                    case .api:
                        Text("API mode connects to online services for the most comprehensive recognition.")
                    case .combined:
                        Text("Combined mode uses all available methods for the best possible results.")
                    }
                }
                
                Button("Apply") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding()
            }
            .navigationTitle("Recognition Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 