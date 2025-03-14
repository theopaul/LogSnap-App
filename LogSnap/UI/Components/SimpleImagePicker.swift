import SwiftUI
import UIKit
import AVFoundation

struct SimpleImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // Verify source type availability
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            // Fallback to photo library if requested source is not available
            picker.sourceType = .photoLibrary
        }
        
        // Apply camera-specific settings if needed
        if picker.sourceType == .camera {
            // Use our specialized camera configuration helper
            CameraConfigHelper.shared.configureImagePicker(picker)
            
            // Log the device information for debugging
            print("DEBUG: Camera configured for device: \(CameraConfigHelper.shared.userFriendlyDeviceName)")
            
            // Check for potential orientation issues
            if CameraConfigHelper.shared.checkForOrientationIssues() {
                print("DEBUG: Detected potential orientation issues, applied mitigation")
            }
        }
        
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        
        // Set camera overlay for visual feedback (optional)
        if picker.sourceType == .camera {
            picker.cameraOverlayView = createCameraOverlay()
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Create a simple camera overlay for better visual feedback
    private func createCameraOverlay() -> UIView? {
        let overlayView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        overlayView.backgroundColor = .clear
        return overlayView
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: SimpleImagePicker
        
        init(_ parent: SimpleImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var selectedImage: UIImage?
            
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            }
            
            // Store the image locally to avoid potential memory issues or reference problems
            if let image = selectedImage {
                // Process the image in the background to prevent UI lockups
                DispatchQueue.global(qos: .userInitiated).async {
                    let processedImage = self.processImage(image) ?? image
                    
                    // Use the main thread for UI updates
                    DispatchQueue.main.async {
                        // First dismiss the picker to prevent gesture timeout errors
                        picker.dismiss(animated: true) {
                            // Call the completion handler after dismissal is complete
                            // This order helps prevent gesture timeout issues
                            self.parent.onImageSelected(processedImage)
                        }
                    }
                }
            } else {
                // No image selected, just dismiss
                picker.dismiss(animated: true)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Dismiss immediately on cancel
            picker.dismiss(animated: true)
        }
        
        // Process image to fix orientation issues
        private func processImage(_ image: UIImage) -> UIImage? {
            // Guard against invalid images
            guard image.size.width > 0, image.size.height > 0,
                  !image.size.width.isNaN, !image.size.height.isNaN,
                  image.size.width.isFinite, image.size.height.isFinite else {
                print("ERROR: Invalid image dimensions detected")
                return nil
            }
            
            // Fix orientation - critical for camera images which can come in any orientation
            var correctedImage = image
            if correctedImage.imageOrientation != .up {
                // Create autoreleasepool to manage memory during image processing
                autoreleasepool {
                    UIGraphicsBeginImageContextWithOptions(correctedImage.size, false, correctedImage.scale)
                    correctedImage.draw(in: CGRect(origin: .zero, size: correctedImage.size))
                    if let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                        UIGraphicsEndImageContext()
                        correctedImage = normalizedImage
                    } else {
                        UIGraphicsEndImageContext()
                    }
                }
            }
            
            // Resize large images to avoid memory issues
            let maxDimension: CGFloat = 1200 // Reduced from 1500 to improve performance
            if correctedImage.size.width > maxDimension || correctedImage.size.height > maxDimension {
                // Create autoreleasepool to manage memory during resizing
                autoreleasepool {
                    let aspectRatio = correctedImage.size.width / correctedImage.size.height
                    
                    // Verify aspect ratio is valid
                    guard aspectRatio.isFinite, !aspectRatio.isNaN, aspectRatio > 0 else {
                        print("ERROR: Invalid aspect ratio detected")
                        return
                    }
                    
                    var newSize: CGSize
                    if correctedImage.size.width > correctedImage.size.height {
                        newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                    } else {
                        newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                    }
                    
                    // Verify new size dimensions are valid
                    guard newSize.width > 0, newSize.height > 0,
                          newSize.width.isFinite, newSize.height.isFinite else {
                        print("ERROR: Invalid resize dimensions calculated")
                        return
                    }
                    
                    // Use UIGraphicsImageRenderer for better performance and memory management
                    let renderer = UIGraphicsImageRenderer(size: newSize)
                    let resizedImage = renderer.image { ctx in
                        ctx.cgContext.interpolationQuality = .high
                        correctedImage.draw(in: CGRect(origin: .zero, size: newSize))
                    }
                    
                    correctedImage = resizedImage
                }
            }
            
            return correctedImage
        }
    }
} 