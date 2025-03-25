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
    
    private let sessionQueue = DispatchQueue(label: "com.foodscannerpro.sessionQueue", qos: .userInitiated)
    private var isConfigured = false
    
    // Helper method to update published properties on main thread
    private func updateOnMain(_ update: @escaping () -> Void) {
        if Thread.isMainThread {
            update()
        } else {
            DispatchQueue.main.async {
                update()
            }
        }
    }
    
    enum CameraError: Error, LocalizedError {
        case cameraUnavailable
        case cannotAddInput
        case cannotAddOutput
        case permissionDenied
        case switchCameraError
        case zoomError
        case captureError
        case burstModeError
        
        var errorDescription: String? {
            switch self {
            case .cameraUnavailable:
                return "Camera is not available on this device"
            case .cannotAddInput:
                return "Cannot add camera input"
            case .cannotAddOutput:
                return "Cannot add camera output"
            case .permissionDenied:
                return "Camera permission denied"
            case .switchCameraError:
                return "Failed to switch camera"
            case .zoomError:
                return "Failed to set zoom level"
            case .captureError:
                return "Failed to capture photo"
            case .burstModeError:
                return "Failed to capture burst photos"
            }
        }
    }
    
    override init() {
        super.init()
        // Configure session
        session.automaticallyConfiguresApplicationAudioSession = false
        sessionQueue.async { [weak self] in
            self?.checkPermissions()
        }
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.updateOnMain {
                        self?.cameraPermissionGranted = true
                    }
                    self?.setupCamera()
                } else {
                    self?.updateOnMain {
                        self?.cameraPermissionGranted = false
                        self?.error = .permissionDenied
                    }
                }
            }
        case .restricted, .denied:
            updateOnMain {
                self.cameraPermissionGranted = false
                self.error = .permissionDenied
            }
        case .authorized:
            updateOnMain {
                self.cameraPermissionGranted = true
            }
            setupCamera()
        @unknown default:
            updateOnMain {
                self.cameraPermissionGranted = false
                self.error = .permissionDenied
            }
        }
    }
    
    func setupCamera() {
        guard !isConfigured else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop the session if it's running
            if self.session.isRunning {
                self.session.stopRunning()
            }
            
            do {
                // Begin configuration
                self.session.beginConfiguration()
                
                // Clear existing inputs and outputs
                self.session.inputs.forEach { self.session.removeInput($0) }
                self.session.outputs.forEach { self.session.removeOutput($0) }
                
                // Setup camera input
                guard let cameraInput = try self.createCameraInput(position: self.currentCamera) else {
                    throw CameraError.cannotAddInput
                }
                
                if self.session.canAddInput(cameraInput) {
                    self.session.addInput(cameraInput)
                    self.currentCameraInput = cameraInput
                    self.currentDevice = cameraInput.device
                    
                    // Configure preview layer orientation
                    self.previewLayer.connection?.videoOrientation = .portrait
                    
                    // Update device-specific properties on main thread
                    self.updateOnMain {
                        if let device = self.currentDevice {
                            self.maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 5.0)
                            self.isFlashAvailable = device.hasFlash
                        }
                    }
                } else {
                    throw CameraError.cannotAddInput
                }
                
                // Setup photo output with proper orientation
                if self.session.canAddOutput(self.output) {
                    self.output.isHighResolutionCaptureEnabled = true
                    self.session.addOutput(self.output)
                    
                    // Configure the output connection for portrait orientation
                    if let connection = self.output.connection(with: .video) {
                        self.configureVideoConnection(connection)
                    }
                } else {
                    throw CameraError.cannotAddOutput
                }
                
                // Set high quality photo preset
                if self.session.canSetSessionPreset(.photo) {
                    self.session.sessionPreset = .photo
                }
                
                // Commit configuration
                self.session.commitConfiguration()
                self.isConfigured = true
                
                // Start the session
                self.start()
                
            } catch let error as CameraError {
                self.updateOnMain {
                    self.error = error
                }
            } catch {
                self.updateOnMain {
                    self.error = .cameraUnavailable
                }
            }
        }
    }
    
    private func createCameraInput(position: AVCaptureDevice.Position) throws -> AVCaptureDeviceInput? {
        let deviceTypes: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera]
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: deviceTypes, mediaType: .video, position: position)
        
        guard let device = discoverySession.devices.first else {
            throw CameraError.cameraUnavailable
        }
        
        do {
            return try AVCaptureDeviceInput(device: device)
        } catch {
            throw CameraError.cannotAddInput
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self, let currentCameraInput = self.currentCameraInput else {
                self?.updateOnMain {
                    self?.error = .switchCameraError
                }
                return
            }
            
            self.session.beginConfiguration()
            self.session.removeInput(currentCameraInput)
            
            let newPosition = self.currentCamera == .back ? AVCaptureDevice.Position.front : .back
            
            do {
                guard let newInput = try self.createCameraInput(position: newPosition) else {
                    throw CameraError.cannotAddInput
                }
                
                if self.session.canAddInput(newInput) {
                    self.session.addInput(newInput)
                    self.updateOnMain {
                        self.currentCamera = newPosition
                    }
                    self.currentCameraInput = newInput
                    self.currentDevice = newInput.device
                    
                    // Update device-specific properties
                    self.updateOnMain {
                        self.maxZoomFactor = min(newInput.device.activeFormat.videoMaxZoomFactor, 5.0)
                        self.zoomFactor = 1.0
                        self.isFlashAvailable = newInput.device.hasFlash
                    }
                    
                    // Configure the new device
                    try self.configureDevice(newInput.device)
                } else {
                    throw CameraError.cannotAddInput
                }
                
                self.session.commitConfiguration()
                
            } catch {
                // Restore previous camera input
                if self.session.canAddInput(currentCameraInput) {
                    self.session.addInput(currentCameraInput)
                    self.currentDevice = currentCameraInput.device
                }
                self.session.commitConfiguration()
                
                self.updateOnMain {
                    self.error = .switchCameraError
                }
            }
        }
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
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.isConfigured {
                self.setupCamera()
                return
            }
            
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stop() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = currentDevice else {
            self.error = .zoomError
            return
        }
        
        do {
            try device.lockForConfiguration()
            let normalizedZoom = min(max(factor, minZoomFactor), maxZoomFactor)
            device.videoZoomFactor = normalizedZoom
            zoomFactor = normalizedZoom
            device.unlockForConfiguration()
        } catch {
            self.error = .zoomError
        }
    }
    
    func zoom(by factor: CGFloat) {
        let newZoom = zoomFactor * factor
        setZoom(factor: newZoom)
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        guard session.isRunning else {
            updateOnMain {
                completion(nil)
            }
            return
        }
        
        // Ensure we're on the session queue for capture
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.updateOnMain {
                self.isProcessingPhoto = true
                self.photoCompletion = completion
            }
            
            let settings = self.setupPhotoSettings()
            
            // Ensure the output is ready for capture
            guard self.output.connections.first?.isEnabled == true,
                  self.output.connections.first?.isActive == true else {
                self.updateOnMain {
                    self.isProcessingPhoto = false
                    self.photoCompletion?(nil)
                    self.photoCompletion = nil
                    self.error = .captureError
                }
                return
            }
            
            // Capture with error handling
            do {
                if let connection = self.output.connection(with: .video) {
                    self.configureVideoConnection(connection)
                }
                self.output.capturePhoto(with: settings, delegate: self)
            } catch {
                self.updateOnMain {
                    self.isProcessingPhoto = false
                    self.photoCompletion?(nil)
                    self.photoCompletion = nil
                    self.error = .captureError
                }
            }
        }
    }
    
    func resetCaptureState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.capturedImage = nil
            self.isProcessingPhoto = false
            self.photoCompletion = nil
        }
    }
    
    func toggleFoodMode() {
        isFoodModeEnabled.toggle()
        
        guard let device = currentDevice else {
            return
        }
        
        do {
            try device.lockForConfiguration()
            
            if isFoodModeEnabled {
                // Optimize settings for food photography
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
                    if device.activeFormat.isVideoHDRSupported {
                        device.isVideoHDREnabled = true
                    }
                }
                
                // Set optimal zoom for food (slightly zoomed in)
                let foodOptimalZoom: CGFloat = 1.5
                if device.videoZoomFactor < foodOptimalZoom && foodOptimalZoom <= device.activeFormat.videoMaxZoomFactor {
                    device.videoZoomFactor = foodOptimalZoom
                    zoomFactor = foodOptimalZoom
                }
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
                    if device.activeFormat.isVideoHDRSupported {
                        device.isVideoHDREnabled = false
                    }
                }
                
                device.videoZoomFactor = 1.0
                zoomFactor = 1.0
            }
            
            device.unlockForConfiguration()
        } catch {
            // If food mode configuration fails, just continue with default settings
            self.error = .zoomError
        }
    }
    
    func startBurstCapture(completion: @escaping ([UIImage]) -> Void) {
        guard !isBurstCapturing else {
            return
        }
        
        guard session.isRunning else {
            completion([])
            return
        }
        
        self.burstCompletion = completion
        self.isBurstCapturing = true
        self.burstImages = []
        self.burstCount = 0
        
        takeBurstPhoto()
        
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
        let settings = setupPhotoSettings()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            self.output.capturePhoto(with: settings, delegate: self)
            self.burstCount += 1
        }
    }
    
    private func finishBurstCapture() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.isBurstCapturing = false
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
    }
    
    func setupPhotoSettings() -> AVCapturePhotoSettings {
        let settings = AVCapturePhotoSettings()
        
        if #available(iOS 16.0, *) {
            settings.maxPhotoDimensions = output.maxPhotoDimensions
        }
        
        if isFlashAvailable {
            settings.flashMode = flashMode
        }
        
        settings.previewPhotoFormat = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        return settings
    }
    
    private func configureVideoConnection(_ connection: AVCaptureConnection) {
        // Force portrait orientation for all connections
        if connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        // Handle mirroring for front camera
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored = currentCamera == .front
        }
        
        // Force the connection to be active
        connection.isEnabled = true
    }
    
    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        
        // Reset zoom to default
        device.videoZoomFactor = zoomFactor
        
        // Set focus mode
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        
        // Set exposure mode
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        
        // Configure video connection for proper orientation
        if let connection = output.connection(with: .video) {
            configureVideoConnection(connection)
        }
        
        device.unlockForConfiguration()
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // Handle any capture errors
        if let error = error {
            print("Photo capture error: \(error.localizedDescription)")
            updateOnMain {
                self.error = .captureError
                self.isProcessingPhoto = false
                self.photoCompletion?(nil)
                self.photoCompletion = nil
            }
            return
        }
        
        // Process the captured photo
        guard let imageData = photo.fileDataRepresentation() else {
            updateOnMain {
                self.error = .captureError
                self.isProcessingPhoto = false
                self.photoCompletion?(nil)
                self.photoCompletion = nil
            }
            return
        }
        
        // Create image and fix orientation
        guard let originalImage = UIImage(data: imageData),
              let fixedImage = originalImage.fixOrientation() else {
            updateOnMain {
                self.error = .captureError
                self.isProcessingPhoto = false
                self.photoCompletion?(nil)
                self.photoCompletion = nil
            }
            return
        }
        
        // Update UI with captured image
        updateOnMain {
            if self.isBurstCapturing {
                self.burstImages.append(fixedImage)
                if self.burstCount >= self.maxBurstCount {
                    self.finishBurstCapture()
                }
            } else {
                self.capturedImage = fixedImage
                self.isProcessingPhoto = false
                self.photoCompletion?(fixedImage)
                self.photoCompletion = nil
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesPlaySystemSound(1108)
    }
}

// Add UIImage extension for orientation fixing
private extension UIImage {
    func fixOrientation() -> UIImage? {
        guard let cgImage = self.cgImage else { return nil }
        
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi/2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi/2)
        case .up, .upMirrored:
            break
        @unknown default:
            break
        }
        
        // Handle mirroring
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        let contextWidth: CGFloat
        let contextHeight: CGFloat
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            contextWidth = size.height
            contextHeight = size.width
        default:
            contextWidth = size.width
            contextHeight = size.height
        }
        
        // Create context for the transform
        guard let context = CGContext(
            data: nil,
            width: Int(contextWidth),
            height: Int(contextHeight),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        // Apply the transform
        context.concatenate(transform)
        
        // Draw the image
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        // Get the resized image from the context
        guard let newCGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: newCGImage, scale: scale, orientation: .up)
    }
} 