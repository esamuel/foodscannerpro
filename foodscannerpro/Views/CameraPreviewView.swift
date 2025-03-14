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
        
        // Force the orientation to portrait
        if view.videoPreviewLayer.connection?.isVideoOrientationSupported ?? false {
            view.videoPreviewLayer.connection?.videoOrientation = .portrait
        }
        
        print("Camera preview view created with bounds: \(view.bounds)")
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Force the orientation to portrait
        if uiView.videoPreviewLayer.connection?.isVideoOrientationSupported ?? false {
            uiView.videoPreviewLayer.connection?.videoOrientation = .portrait
        }
        
        print("Camera preview layer updated with frame: \(uiView.frame)")
    }
} 