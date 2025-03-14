//
//  CameraManager.swift
//  foodscannerpro
//
//  Created by Samuel Eskenasy on 3/13/25.
//

import AVFoundation
import SwiftUI
import CoreImage
import AudioToolbox

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var cameraPermissionGranted = false
    @Published var capturedImage: UIImage?
    @Published var error: CameraError?
    @Published var isFlashAvailable = false
    @Published var flashMode: AVCaptureDevice.FlashMode = .off
    @Published var currentCamera: AVCaptureDevice.Position = .back
    @Published var zoomFactor: CGFloat = 1.0
    @Published var isProcessingPhoto = false
    @Published var isFoodModeEnabled = false
    @Published var burstImages: [UIImage] = []
    @Published var isBurstModeEnabled = false
    @Published var isBurstCapturing = false
    
    let output = AVCapturePhotoOutput()
    var previewLayer = AVCaptureVideoPreviewLayer()
    private var currentCameraInput: AVCaptureDeviceInput?
    private var photoCompletion: ((UIImage?) -> Void)?
    private var burstCompletion: (([UIImage]) -> Void)?
    private var burstCount = 0
    private var maxBurstCount = 5
    private var burstTimer: Timer?
    
    // Add minimum and maximum zoom factors
    private let minZoomFactor: CGFloat = 1.0
    private var maxZoomFactor: CGFloat = 5.0
    private var currentDevice: AVCaptureDevice?
    
    enum CameraError: Error {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case permissionDenied
        case switchCameraError
        case zoomError
        case captureError
        case burstModeError
    }
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .restricted, .denied:
            self.error = .permissionDenied
            self.cameraPermissionGranted = false
        case .authorized:
            self.cameraPermissionGranted = true
            setupCamera()
        @unknown default:
            break
        }
    }
    
    func setupCamera() {
        do {
            // Stop the session if it's running
            if session.isRunning {
                session.stopRunning()
            }
            
            // Remove all inputs and outputs
            for input in session.inputs {
                session.removeInput(input)
            }
            
            for output in session.outputs {
                session.removeOutput(output)
            }
            
            print("Setting up camera session...")
            self.session.beginConfiguration()
            
            // Setup initial camera input
            if let cameraInput = try? createCameraInput(position: currentCamera) {
                if self.session.canAddInput(cameraInput) {
                    self.session.addInput(cameraInput)
                    self.currentCameraInput = cameraInput
                    self.currentDevice = cameraInput.device
                    print("Added camera input: \(cameraInput.device.localizedName)")
                    
                    // Update max zoom factor based on device capabilities
                    if let device = currentDevice {
                        self.maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 5.0)
                        self.isFlashAvailable = device.hasFlash
                    }
                } else {
                    print("Cannot add camera input")
                }
            } else {
                print("Failed to create camera input")
            }
            
            // Configure photo output
            output.isHighResolutionCaptureEnabled = true
            if #available(iOS 13.0, *) {
                output.maxPhotoQualityPrioritization = .quality
            }
            
            if self.session.canAddOutput(output) {
                self.session.addOutput(output)
                print("Added photo output")
                
                // Configure output connection
                if let connection = output.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                        print("Set video orientation to portrait")
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = currentCamera == .front
                        print("Set video mirroring: \(currentCamera == .front)")
                    }
                }
            } else {
                print("Cannot add photo output")
            }
            
            // Set session preset for high quality photo capture
            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
                print("Set session preset to photo")
            }
            
            self.session.commitConfiguration()
            print("Camera session configuration committed")
            
            // Print debug info
            print("Camera setup completed:")
            print("- Current device: \(currentDevice?.localizedName ?? "None")")
            print("- Flash available: \(isFlashAvailable)")
            print("- Max zoom factor: \(maxZoomFactor)")
            
            // Start the session
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                if !self.session.isRunning {
                    print("Starting camera session after setup...")
                    self.session.startRunning()
                    print("Camera session started after setup")
                }
            }
            
        } catch {
            print("Camera setup error: \(error.localizedDescription)")
            self.error = .cameraUnavailable
            return
        }
    }
    
    private func createCameraInput(position: AVCaptureDevice.Position) throws -> AVCaptureDeviceInput? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: position)
        
        print("Available devices: \(discoverySession.devices.map { $0.localizedName }.joined(separator: ", "))")
        
        guard let device = discoverySession.devices.first else {
            print("No camera device found")
            throw CameraError.cameraUnavailable
        }
        
        print("Selected device: \(device.localizedName)")
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            return input
        } catch {
            print("Error creating camera input: \(error.localizedDescription)")
            throw error
        }
    }
    
    func switchCamera() {
        guard let currentCameraInput = self.currentCameraInput else { return }
        
        session.beginConfiguration()
        session.removeInput(currentCameraInput)
        
        currentCamera = currentCamera == .back ? .front : .back
        
        do {
            if let newInput = try createCameraInput(position: currentCamera) {
                if session.canAddInput(newInput) {
                    session.addInput(newInput)
                    self.currentCameraInput = newInput
                    self.currentDevice = newInput.device
                    
                    // Update max zoom factor for new device
                    self.maxZoomFactor = min(newInput.device.activeFormat.videoMaxZoomFactor, 5.0)
                    // Reset zoom when switching cameras
                    self.zoomFactor = 1.0
                    setZoom(factor: 1.0)
                    
                    // Update flash availability
                    self.isFlashAvailable = newInput.device.hasFlash
                } else {
                    throw CameraError.cannotAddInput
                }
            }
        } catch {
            self.error = .switchCameraError
            // Restore previous camera input
            if session.canAddInput(currentCameraInput) {
                session.addInput(currentCameraInput)
                self.currentDevice = currentCameraInput.device
            }
        }
        
        session.commitConfiguration()
    }
    
    func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .on
        case .on:
            flashMode = .auto
        case .auto:
            flashMode = .off
        @unknown default:
            flashMode = .off
        }
    }
    
    func start() {
        // First check if we need to set up the camera
        if currentDevice == nil || currentCameraInput == nil {
            print("No valid camera device or input, setting up camera first")
            setupCamera()
            return
        }
        
        // Start the session on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                print("Starting camera session...")
                self.session.startRunning()
                
                // Verify that the session is actually running
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if self.session.isRunning {
                        print("Camera session is confirmed running")
                    } else {
                        print("WARNING: Camera session failed to start, trying again...")
                        self.setupCamera() // Try to set up the camera again
                    }
                }
            } else {
                print("Camera session is already running")
            }
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.session.isRunning {
                print("Stopping camera session...")
                self.session.stopRunning()
                print("Camera session stopped")
            }
        }
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Ensure zoom factor is within valid range
            let normalizedZoom = min(max(factor, minZoomFactor), maxZoomFactor)
            device.videoZoomFactor = normalizedZoom
            zoomFactor = normalizedZoom
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error.localizedDescription)")
            self.error = .zoomError
        }
    }
    
    func zoom(by factor: CGFloat) {
        let newZoom = zoomFactor * factor
        setZoom(factor: newZoom)
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard session.isRunning else {
            print("Session is not running")
            completion(nil)
            return
        }
        
        self.photoCompletion = completion
        self.isProcessingPhoto = true
        
        // Configure photo settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        settings.isHighResolutionPhotoEnabled = true
        
        // Set photo quality prioritization
        if #available(iOS 14.0, *) {
            settings.photoQualityPrioritization = .quality
        }
        
        // Configure preview
        if let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first {
            settings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType]
        }
        
        print("Capturing photo with settings: \(settings)")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }
    
    func resetCaptureState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.capturedImage = nil
            self.isProcessingPhoto = false
            self.photoCompletion = nil
            print("Camera state reset")
        }
    }
    
    func toggleFoodMode() {
        isFoodModeEnabled.toggle()
        
        guard let device = currentDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            if isFoodModeEnabled {
                // Optimize settings for food photography
                
                // 1. Set white balance to auto for accurate food colors
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                
                // 2. Enable auto focus with focus mode
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                // 3. Set exposure mode to continuous auto exposure
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                // 4. Increase saturation slightly for more vibrant food colors
                if #available(iOS 13.0, *) {
                    if let videoDevice = device as? AVCaptureDevice {
                        if videoDevice.activeFormat.isVideoHDRSupported {
                            videoDevice.isVideoHDREnabled = true
                        }
                    }
                }
                
                // 5. Set optimal zoom for food (slightly zoomed in)
                let foodOptimalZoom: CGFloat = 1.5
                if device.videoZoomFactor < foodOptimalZoom && foodOptimalZoom <= device.activeFormat.videoMaxZoomFactor {
                    device.videoZoomFactor = foodOptimalZoom
                    zoomFactor = foodOptimalZoom
                }
                
                print("Food mode enabled with optimized camera settings")
            } else {
                // Reset to default settings
                if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                    device.whiteBalanceMode = .continuousAutoWhiteBalance
                }
                
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                
                if #available(iOS 13.0, *) {
                    if let videoDevice = device as? AVCaptureDevice {
                        if videoDevice.activeFormat.isVideoHDRSupported {
                            videoDevice.isVideoHDREnabled = false
                        }
                    }
                }
                
                // Reset zoom to default
                device.videoZoomFactor = 1.0
                zoomFactor = 1.0
                
                print("Food mode disabled, camera settings reset to default")
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring device for food mode: \(error.localizedDescription)")
        }
    }
    
    func startBurstCapture(completion: @escaping ([UIImage]) -> Void) {
        guard !isBurstCapturing else {
            print("Burst capture already in progress")
            return
        }
        
        guard session.isRunning else {
            print("Session is not running")
            completion([])
            return
        }
        
        self.burstCompletion = completion
        self.isBurstCapturing = true
        self.burstImages = []
        self.burstCount = 0
        
        print("Starting burst capture, will take \(maxBurstCount) photos")
        
        // Take first photo immediately
        takeBurstPhoto()
        
        // Schedule timer for remaining photos
        burstTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.takeBurstPhoto()
            
            if self.burstCount >= self.maxBurstCount {
                self.finishBurstCapture()
                timer.invalidate()
            }
        }
    }
    
    private func takeBurstPhoto() {
        // Configure photo settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        settings.isHighResolutionPhotoEnabled = true
        
        // Set photo quality prioritization
        if #available(iOS 14.0, *) {
            settings.photoQualityPrioritization = .balanced
        }
        
        print("Taking burst photo \(burstCount + 1) of \(maxBurstCount)")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.output.capturePhoto(with: settings, delegate: self)
            self.burstCount += 1
        }
    }
    
    private func finishBurstCapture() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            print("Burst capture completed with \(self.burstImages.count) images")
            self.isBurstCapturing = false
            
            // Call completion with captured images
            self.burstCompletion?(self.burstImages)
            self.burstCompletion = nil
        }
    }
    
    func cancelBurstCapture() {
        burstTimer?.invalidate()
        burstTimer = nil
        isBurstCapturing = false
        burstImages = []
        burstCount = 0
        burstCompletion?([])
        burstCompletion = nil
        
        print("Burst capture canceled")
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            self.error = .captureError
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if self.isBurstCapturing {
                    self.finishBurstCapture()
                } else {
                    self.isProcessingPhoto = false
                    self.photoCompletion?(nil)
                    self.photoCompletion = nil
                }
            }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from photo data")
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if self.isBurstCapturing {
                    self.finishBurstCapture()
                } else {
                    self.isProcessingPhoto = false
                    self.photoCompletion?(nil)
                    self.photoCompletion = nil
                }
            }
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.isBurstCapturing {
                // Add to burst images array
                self.burstImages.append(image)
                print("Added image \(self.burstImages.count) to burst collection")
                
                // If this is the last image or we've reached max, finish burst
                if self.burstCount >= self.maxBurstCount {
                    self.finishBurstCapture()
                }
            } else {
                // Normal photo capture
                print("Photo captured successfully")
                self.capturedImage = image
                self.isProcessingPhoto = false
                self.photoCompletion?(image)
                self.photoCompletion = nil
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("Will capture photo")
        // Add shutter sound
        AudioServicesPlaySystemSound(1108)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("Did capture photo")
    }
} 