import SwiftUI
import PhotosUI
import UIKit

public struct ModernImagePicker: UIViewControllerRepresentable {
    @Binding public var selectedImage: UIImage?
    public var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    public init(selectedImage: Binding<UIImage?>, sourceType: UIImagePickerController.SourceType) {
        self._selectedImage = selectedImage
        self.sourceType = sourceType
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        // Use PHPicker for photo library access (iOS 14+)
        if sourceType == .photoLibrary {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            // This ensures the picker works even with limited photo access
            config.preferredAssetRepresentationMode = .current
            
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker
        } else {
            // Use UIImagePickerController for camera
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = sourceType
            picker.allowsEditing = false
            return picker
        }
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ModernImagePicker
        
        init(_ parent: ModernImagePicker) {
            self.parent = parent
        }
        
        // PHPickerViewControllerDelegate
        public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
        
        // UIImagePickerControllerDelegate
        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
} 