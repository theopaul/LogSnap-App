import SwiftUI
import PhotosUI

/// A modern image picker using PHPickerViewController for better privacy and user experience
/// Can be used as a drop-in replacement for SimpleImagePicker in most cases
///
/// Key improvements over UIImagePickerController:
/// - Better privacy: Doesn't request blanket photo library access
/// - Modern UI: Uses the native iOS photo picker UI
/// - Stability: More reliable on newer iOS devices
/// - Performance: Better memory management
struct ModernImagePicker: UIViewControllerRepresentable {
    // Callback for when an image is selected
    let onImageSelected: (UIImage) -> Void
    
    // Whether to allow editing of the selected image
    var allowsEditing: Bool = true
    
    // The maximum number of selections (default: 1)
    var selectionLimit: Int = 1
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        
        // Use the newer initializer for iOS 15+
        if #available(iOS 15.0, *) {
            configuration = PHPickerConfiguration(photoLibrary: .shared())
            // Enable selection order tracking in iOS 15+
            configuration.selection = .ordered
            // Use current representation mode for highest quality
            configuration.preferredAssetRepresentationMode = .current
        }
        
        // Set selection limit and filter to images only
        configuration.selectionLimit = selectionLimit
        configuration.filter = .images
        
        // Create and configure the picker
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// The Coordinator class implements PHPickerViewControllerDelegate to handle the selection of images.
    /// It properly handles the loading of images from PHPickerResults and ensures proper memory management.
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: ModernImagePicker
        
        init(_ parent: ModernImagePicker) {
            self.parent = parent
        }
        
        /// This method is called when the user finishes picking or cancels
        /// PHPicker automatically handles permissions, so we don't need to request photo library access
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Always dismiss the picker first for better UX
            picker.dismiss(animated: true)
            
            // Handle case where user cancels
            guard let result = results.first else { return }
            
            // Check if we can load a UIImage
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                // Load the image
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                    if let error = error {
                        print("ERROR: Failed to load image: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let image = reading as? UIImage else {
                        print("ERROR: Object loaded is not a UIImage")
                        return
                    }
                    
                    // Process the image in the background
                    DispatchQueue.global(qos: .userInitiated).async {
                        let processedImage = self?.processImage(image) ?? image
                        
                        // Deliver the image on the main thread
                        DispatchQueue.main.async {
                            self?.parent.onImageSelected(processedImage)
                        }
                    }
                }
            }
        }
        
        // Process the image to fix orientation and resize if needed
        private func processImage(_ image: UIImage) -> UIImage {
            // Guard against invalid images
            guard image.size.width > 0, image.size.height > 0,
                  !image.size.width.isNaN, !image.size.height.isNaN,
                  image.size.width.isFinite, image.size.height.isFinite else {
                print("ERROR: Invalid image dimensions detected")
                return createPlaceholderImage()
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
            let maxDimension: CGFloat = 1200
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
        
        // Create a simple placeholder image in case of errors
        private func createPlaceholderImage() -> UIImage {
            let size = CGSize(width: 100, height: 100)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                UIColor.systemGray5.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                
                // Draw text
                let text = "Error" as NSString
                let textRect = CGRect(x: 30, y: 40, width: 40, height: 20)
                text.draw(in: textRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.systemGray
                ])
            }
        }
    }
}

// MARK: - Extensions and Helper Methods

// Extension to allow checking iOS version in previews
extension EnvironmentValues {
    var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}

// MARK: - Preview
struct ModernImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        Text("ModernImagePicker would show here")
            .sheet(isPresented: .constant(true)) {
                if #available(iOS 14.0, *) {
                    ModernImagePicker { _ in
                        // Handle image selection
                    }
                } else {
                    Text("Requires iOS 14 or later")
                }
            }
            .previewDisplayName("ModernImagePicker Preview")
    }
} 