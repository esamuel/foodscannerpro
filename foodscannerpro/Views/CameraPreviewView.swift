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
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black
        
        // Configure the preview layer
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        
        // Set video orientation based on iOS version
        if #available(iOS 17.0, *) {
            if view.videoPreviewLayer.connection?.isVideoRotationAngleSupported(0) ?? false {
                view.videoPreviewLayer.connection?.videoRotationAngle = 0
            }
        } else {
            if view.videoPreviewLayer.connection?.isVideoOrientationSupported ?? false {
                view.videoPreviewLayer.connection?.videoOrientation = .portrait
            }
        }
        
        print("Camera preview view created with bounds: \(view.bounds)")
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update video orientation based on iOS version
        if #available(iOS 17.0, *) {
            if uiView.videoPreviewLayer.connection?.isVideoRotationAngleSupported(0) ?? false {
                uiView.videoPreviewLayer.connection?.videoRotationAngle = 0
            }
        } else {
            if uiView.videoPreviewLayer.connection?.isVideoOrientationSupported ?? false {
                uiView.videoPreviewLayer.connection?.videoOrientation = .portrait
            }
        }
        
        print("Camera preview layer updated with frame: \(uiView.frame)")
    }
} 