import SwiftUI
import AVFoundation

struct CameraView: View {
    @Binding var tabSelection: Int
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraManager = CameraManager()
    @State private var showingSettings = false
    @State private var recognitionMode: RecognitionMode = .standard
    @State private var capturedImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Camera preview
                    CameraPreviewView(session: cameraManager.session)
                        .edgesIgnoringSafeArea(.all)
                    
                    // Camera controls
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
                                    // Process the captured image
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
                    .padding(.bottom)
                }
            }
            .sheet(isPresented: $showingSettings) {
                RecognitionSettingsView(selectedMode: $recognitionMode)
            }
            .onAppear {
                // The CameraManager initializes and sets up the camera in its init method
                // No need to call additional setup methods
            }
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