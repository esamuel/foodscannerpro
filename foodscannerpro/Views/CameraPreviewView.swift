//
//  CameraPreviewView.swift
//  foodscannerpro
//
//  Created by Samuel Eskenasy on 3/13/25.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    class PreviewView: UIView {
        private var orientationObserver: NSObjectProtocol?
        
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupView()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupView()
        }
        
        private func setupView() {
            backgroundColor = .black
            
            // Force the view to portrait orientation
            transform = CGAffineTransform.identity
            
            // Add orientation change observer
            orientationObserver = NotificationCenter.default.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updateVideoOrientation()
            }
            
            // Initial orientation setup
            updateVideoOrientation()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
            
            // Ensure the layer is in portrait orientation
            videoPreviewLayer.connection?.videoOrientation = .portrait
            
            // Force portrait orientation through transform
            let angle = CGFloat.pi/2
            transform = CGAffineTransform(rotationAngle: -angle)
            
            updateVideoOrientation()
        }
        
        private func updateVideoOrientation() {
            guard let connection = videoPreviewLayer.connection else { return }
            
            // Set to portrait upright
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            // Apply transform to fix orientation
            let interfaceOrientation = UIDevice.current.orientation
            var rotationAngle: CGFloat = 0
            
            switch interfaceOrientation {
            case .portrait:
                rotationAngle = 0
            case .portraitUpsideDown:
                rotationAngle = .pi
            case .landscapeLeft:
                rotationAngle = -.pi/2
            case .landscapeRight:
                rotationAngle = .pi/2
            default:
                rotationAngle = 0
            }
            
            // Apply rotation transform
            DispatchQueue.main.async {
                self.transform = CGAffineTransform(rotationAngle: rotationAngle)
            }
        }
        
        deinit {
            if let observer = orientationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView(frame: .zero)
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // Set initial orientation
        if let connection = view.videoPreviewLayer.connection {
            connection.videoOrientation = .portrait
        }
        
        // Ensure the preview layer is properly configured
        view.videoPreviewLayer.frame = view.bounds
        view.videoPreviewLayer.connection?.automaticallyAdjustsVideoMirroring = false
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // View handles its own updates through orientation observer
    }
} 