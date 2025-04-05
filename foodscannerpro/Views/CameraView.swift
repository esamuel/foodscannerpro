import SwiftUI
import AVFoundation
import Components

struct CameraView: View {
    @Binding var tabSelection: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @State private var showingSettings = false
    @State private var recognitionMode: RecognitionMode = RecognitionMode.getLastSelected()
    @State private var capturedImage: UIImage?
    @State private var showingRecognition = false
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
                RecognitionSettingsView(selectedMode: $recognitionMode, isPresented: $showingSettings)
            }
            .fullScreenCover(isPresented: $showingRecognition) {
                if let image = capturedImage {
                    FoodRecognitionView(image: image, classifier: FoodClassifier(), rootIsPresented: $showingRecognition, tabSelection: $tabSelection)
                }
            }
            .sheet(isPresented: $isGalleryPickerPresented) {
                ModernImagePicker(selectedImage: $capturedImage, sourceType: .photoLibrary)
                    .onDisappear {
                        if capturedImage != nil {
                            showingRecognition = true
                        }
                    }
            }
            .onChange(of: capturedImage) { oldValue, newValue in
                if newValue != nil && isGalleryPickerPresented {
                    isGalleryPickerPresented = false
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

// Add RecognitionSettingsView
struct RecognitionSettingsView: View {
    @Binding var selectedMode: RecognitionMode
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            List {
                ForEach(RecognitionMode.allCases, id: \.self) { mode in
                    HStack {
                        Text(mode.rawValue)
                        Spacer()
                        if mode == selectedMode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedMode = mode
                        RecognitionMode.saveLastSelected(mode)
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Recognition Mode")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
} 