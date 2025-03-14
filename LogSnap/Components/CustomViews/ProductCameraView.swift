import SwiftUI
import UIKit
import AVFoundation
import PhotosUI

public struct ProductCameraView: View {
    // MARK: - Properties
    @Binding var isPresented: Bool
    let onImageCaptured: (UIImage) -> Void
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary // Default to photo library to avoid camera errors
    @State private var showImagePicker: Bool = false
    @State private var showModernPicker: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = "Camera Access"
    
    // Detect if running on simulator
    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    // Check if camera is available on this device
    private var isCameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera) && !isSimulator
    }
    
    // Check if we can use the modern picker (iOS 14+)
    private var canUseModernPicker: Bool {
        if #available(iOS 14.0, *) {
            return true
        }
        return false
    }
    
    // MARK: - Initializers
    public init(
        isPresented: Binding<Bool>,
        onImageCaptured: @escaping (UIImage) -> Void
    ) {
        self._isPresented = isPresented
        self.onImageCaptured = onImageCaptured
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
                .padding(.top, 40)
            
            Text("Add Product Image")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Select a source to add a product image")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            // Camera button - only show if camera is available
            if isCameraAvailable {
                Button(action: {
                    checkCameraPermission()
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                        Text("Take Photo")
                            .font(.headline)
                    }
                    .frame(minWidth: 200, minHeight: 50)
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(10)
                }
            }
            
            // Photo library button
            Button(action: {
                if canUseModernPicker {
                    showModernPicker = true
                } else {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 20))
                    Text("Choose from Library")
                        .font(.headline)
                }
                .frame(minWidth: 200, minHeight: 50)
                .foregroundColor(.accentColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
            }
            
            // Cancel button
            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 200, minHeight: 50)
            }
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showImagePicker) {
            // Use legacy picker for older iOS versions
            SimpleImagePicker(sourceType: sourceType, onImageSelected: { image in
                handleSelectedImage(image)
            })
        }
        .sheet(isPresented: $showModernPicker) {
            // Use our modern PHPicker-based implementation for iOS 14+
            if #available(iOS 14.0, *) {
                ModernImagePicker(onImageSelected: { image in
                    handleSelectedImage(image)
                })
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                primaryButton: .default(Text("Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Helper Methods
    private func handleSelectedImage(_ image: UIImage) {
        // Process image before returning it
        if let processedImage = processImage(image) {
            onImageCaptured(processedImage)
        } else {
            onImageCaptured(image)
        }
        
        // Dismiss both sheets with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    private func checkCameraPermission() {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthStatus {
        case .authorized:
            if canUseModernPicker {
                // For modern devices, we should use the camera UI directly
                // But PHPicker doesn't support direct camera access, so fall back
                sourceType = .camera
                showImagePicker = true
            } else {
                sourceType = .camera
                showImagePicker = true
            }
        case .denied, .restricted:
            alertTitle = "Camera Access Denied"
            alertMessage = "Please allow camera access in Settings to take photos."
            showAlert = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        if self.canUseModernPicker {
                            self.sourceType = .camera
                            self.showImagePicker = true
                        } else {
                            self.sourceType = .camera
                            self.showImagePicker = true
                        }
                    } else {
                        self.alertTitle = "Camera Access Denied"
                        self.alertMessage = "Camera access is required to take photos."
                        self.showAlert = true
                    }
                }
            }
        @unknown default:
            DispatchQueue.main.async {
                self.alertTitle = "Camera Error"
                self.alertMessage = "An unknown error occurred with the camera."
                self.showAlert = true
            }
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage? {
        // Guard against invalid images
        guard image.size.width > 0, image.size.height > 0,
              !image.size.width.isNaN, !image.size.height.isNaN,
              image.size.width.isFinite, image.size.height.isFinite else {
            print("ERROR: Invalid image dimensions in ProductCameraView")
            return nil
        }
        
        // Fix orientation using autoreleasepool for better memory management
        var correctedImage = image
        autoreleasepool {
            if correctedImage.imageOrientation != .up {
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
        let maxDimension: CGFloat = 1200 // Reduced to improve performance
        if correctedImage.size.width > maxDimension || correctedImage.size.height > maxDimension {
            // Use autoreleasepool for resizing operation
            autoreleasepool {
                let aspectRatio = correctedImage.size.width / correctedImage.size.height
                
                // Validate aspect ratio
                guard aspectRatio.isFinite, !aspectRatio.isNaN, aspectRatio > 0 else {
                    print("ERROR: Invalid aspect ratio in ProductCameraView")
                    return
                }
                
                var newSize: CGSize
                if correctedImage.size.width > correctedImage.size.height {
                    newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
                } else {
                    newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
                }
                
                // Use UIGraphicsImageRenderer for better performance
                let renderer = UIGraphicsImageRenderer(size: newSize)
                let resizedImage = renderer.image { ctx in
                    // Use high quality interpolation for better results
                    ctx.cgContext.interpolationQuality = .high
                    correctedImage.draw(in: CGRect(origin: .zero, size: newSize))
                }
                
                correctedImage = resizedImage
            }
        }
        
        return correctedImage
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}

// MARK: - Previews
struct ProductCameraView_Previews: PreviewProvider {
    static var previews: some View {
        ProductCameraView(
            isPresented: .constant(true),
            onImageCaptured: { _ in }
        )
        .environment(\.locale, .init(identifier: "en"))
        
        ProductCameraView(
            isPresented: .constant(true),
            onImageCaptured: { _ in }
        )
        .environment(\.locale, .init(identifier: "pt"))
        .previewDisplayName("Portuguese")
    }
} 