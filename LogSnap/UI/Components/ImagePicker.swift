import SwiftUI
import UIKit
import AVFoundation

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var selectedImage: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Check availability of source type
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            // Fallback to photo library if camera is not available
            picker.sourceType = .photoLibrary
        }
        
        // Camera-specific settings
        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .photo
            
            // Don't set a specific camera device - let the system choose the best available one
            // This avoids the "unsupported device" errors
            
            // Set flash mode only if camera is available
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                picker.cameraFlashMode = .auto
            }
        }
        
        picker.delegate = context.coordinator
        picker.allowsEditing = true 
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Try to use edited image first, then original
            var selectedImage: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            }
            
            // Process the image in the background to prevent UI lockups
            if let image = selectedImage {
                DispatchQueue.global(qos: .userInitiated).async {
                    let processedImage = self.processImage(image)
                    
                    DispatchQueue.main.async {
                        // First dismiss the picker to prevent gesture timeout errors
                        picker.dismiss(animated: true) {
                            // Call the completion handler after dismissal is complete
                            self.parent.selectedImage(processedImage)
                        }
                    }
                }
            } else {
                // No valid image, return nil
                picker.dismiss(animated: true) {
                    self.parent.selectedImage(nil)
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                self.parent.selectedImage(nil)
            }
        }
        
        // Process image to fix orientation issues
        private func processImage(_ image: UIImage) -> UIImage? {
            // Guard against invalid images
            guard image.size.width > 0, image.size.height > 0,
                  !image.size.width.isNaN, !image.size.height.isNaN,
                  image.size.width.isFinite, image.size.height.isFinite else {
                return nil
            }
            
            // Fix orientation
            var correctedImage = image
            if correctedImage.imageOrientation != .up {
                UIGraphicsBeginImageContextWithOptions(correctedImage.size, false, correctedImage.scale)
                correctedImage.draw(in: CGRect(origin: .zero, size: correctedImage.size))
                if let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    UIGraphicsEndImageContext()
                    correctedImage = normalizedImage
                } else {
                    UIGraphicsEndImageContext()
                    return nil
                }
            }
            
            // Resize large images to avoid memory issues
            let maxDimension: CGFloat = 1200 // Reduced from 1500 to improve performance
            if correctedImage.size.width > maxDimension || correctedImage.size.height > maxDimension {
                let aspectRatio = correctedImage.size.width / correctedImage.size.height
                
                var newSize: CGSize
                if correctedImage.size.width > correctedImage.size.height {
                    newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                } else {
                    newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                correctedImage.draw(in: CGRect(origin: .zero, size: newSize))
                if let resizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    UIGraphicsEndImageContext()
                    return resizedImage
                }
                UIGraphicsEndImageContext()
            }
            
            return correctedImage
        }
    }
} 