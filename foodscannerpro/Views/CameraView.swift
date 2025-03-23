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
                RecognitionSettingsView(selectedMode: $recognitionMode, isPresented: $showingSettings)
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
                ImagePicker(selectedImage: $capturedImage, sourceType: .photoLibrary)
            }
            .onChange(of: capturedImage) { newValue in
                if newValue != nil && isGalleryPickerPresented {
                    // Default to regular recognition for gallery images
                    isGalleryPickerPresented = false
                    showingRecognition = true
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