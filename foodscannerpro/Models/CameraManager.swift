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
                    } else {
                        self?.error = .permissionDenied
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
            self.error = .permissionDenied
            self.cameraPermissionGranted = false
        }
    }
    
    func setupCamera() {
        do {
            // Stop the session if it's running
            if session.isRunning {
                session.stopRunning()
            }
            
            // Remove all inputs and outputs
            session.inputs.forEach { session.removeInput($0) }
            session.outputs.forEach { session.removeOutput($0) }
            
            print("Setting up camera session...")
            session.beginConfiguration()
            
            // Setup initial camera input
            guard let cameraInput = try createCameraInput(position: currentCamera) else {
                throw CameraError.cannotAddInput
            }
            
            guard session.canAddInput(cameraInput) else {
                throw CameraError.cannotAddInput
            }
            
            session.addInput(cameraInput)
            currentCameraInput = cameraInput
            currentDevice = cameraInput.device
            print("Added camera input: \(cameraInput.device.localizedName)")
            
            // Update max zoom factor based on device capabilities
            if let device = currentDevice {
                maxZoomFactor = min(device.activeFormat.videoMaxZoomFactor, 5.0)
                isFlashAvailable = device.hasFlash
            }
            
            // Configure photo output
            guard session.canAddOutput(output) else {
                throw CameraError.cannotAddOutput
            }
            
            session.addOutput(output)
            print("Added photo output")
            
            // Configure output connection
            if let connection = output.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(0) {
                        connection.videoRotationAngle = 0
                    }
                } else {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
                
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = currentCamera == .front
                }
            }
            
            // Set session preset for high quality photo capture
            if session.canSetSessionPreset(.photo) {
                session.sessionPreset = .photo
            }
            
            session.commitConfiguration()
            print("Camera session configuration committed")
            
            // Start the session on the main thread
            DispatchQueue.main.async { [weak self] in
                self?.session.startRunning()
                print("Camera session started running")
            }
            
        } catch let error as CameraError {
            print("Camera setup error: \(error.localizedDescription)")
            self.error = error
        } catch {
            print("Unexpected camera setup error: \(error.localizedDescription)")
            self.error = .cameraUnavailable
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
        guard let currentCameraInput = self.currentCameraInput else {
            self.error = .switchCameraError
            return
        }
        
        session.beginConfiguration()
        session.removeInput(currentCameraInput)
        
        currentCamera = currentCamera == .back ? .front : .back
        
        do {
            guard let newInput = try createCameraInput(position: currentCamera) else {
                throw CameraError.cannotAddInput
            }
            
            guard session.canAddInput(newInput) else {
                throw CameraError.cannotAddInput
            }
            
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
            
            session.commitConfiguration()
        } catch {
            self.error = .switchCameraError
            // Restore previous camera input
            if session.canAddInput(currentCameraInput) {
                session.addInput(currentCameraInput)
                self.currentDevice = currentCameraInput.device
            }
            session.commitConfiguration()
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
        if currentDevice == nil || currentCameraInput == nil {
            setupCamera()
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func stop() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.stopRunning()
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
            completion(nil)
            return
        }
        
        self.photoCompletion = completion
        self.isProcessingPhoto = true
        
        let settings = setupPhotoSettings()
        
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
        
        return settings
    }
    
    private func configureDevice(_ device: AVCaptureDevice) throws {
        try device.lockForConfiguration()
        device.videoZoomFactor = zoomFactor
        
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        
        device.unlockForConfiguration()
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let captureError = error {
            print("Photo capture error: \(captureError.localizedDescription)")
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
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if self.isBurstCapturing {
                self.burstImages.append(image)
                
                if self.burstCount >= self.maxBurstCount {
                    self.finishBurstCapture()
                }
            } else {
                self.capturedImage = image
                self.isProcessingPhoto = false
                self.photoCompletion?(image)
                self.photoCompletion = nil
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesPlaySystemSound(1108)
    }
} 