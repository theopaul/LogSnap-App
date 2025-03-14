import UIKit

// MARK: - UIImage Extensions for Core Data
public extension UIImage {
    /// Image format options for storage
    @objc enum ImageFormat: Int {
        case jpeg, png
    }
    
    /// Optimizes an image for storage while preserving original aspect ratio
    /// - Parameters:
    ///   - maxDimension: Maximum width or height in points (default: 1024)
    ///   - compressionQuality: JPEG compression quality from 0.0 to 1.0 (default: 0.7)
    ///   - format: Image format to use (.jpeg or .png)
    /// - Returns: Optimized UIImage with original aspect ratio preserved
    @objc func optimizedForStorage(
        maxDimension: CGFloat = 1024,
        compressionQuality: CGFloat = 0.7,
        format: ImageFormat = .jpeg
    ) -> UIImage {
        // Validate input dimensions first
        guard size.width > 0, size.height > 0, !size.width.isNaN, !size.height.isNaN else {
            NSLog("Warning: Invalid image dimensions: \(size.width) x \(size.height)")
            return self
        }
        
        // Ensure compression quality is in valid range
        let validQuality = max(0.1, min(compressionQuality, 1.0))
        
        // Get the largest dimension
        let maxDimensionActual = max(size.width, size.height)
        
        // If image is already smaller than maxDimension, just compress without resizing
        if maxDimensionActual <= maxDimension {
            return compressImage(self, quality: validQuality, format: format) ?? self
        }
        
        // Calculate scale factor to maintain aspect ratio
        let scale = maxDimension / maxDimensionActual
        
        // Calculate new dimensions while preserving aspect ratio
        let newWidth = floor(size.width * scale)
        let newHeight = floor(size.height * scale)
        
        NSLog("Resizing from \(size.width)x\(size.height) to \(newWidth)x\(newHeight)")
        
        // Create new size that preserves aspect ratio
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // Resize image with aspect ratio preserved
        let resizedImage = autoreleasepool { () -> UIImage? in
            let renderer = UIGraphicsImageRenderer(size: newSize)
            
            let newImage = renderer.image { context in
                // Use high quality interpolation
                context.cgContext.interpolationQuality = .high
                // Draw image in the center to maintain aspect ratio
                draw(in: CGRect(origin: .zero, size: newSize))
            }
            return newImage
        } ?? self
        
        // Compress the resized image
        return compressImage(resizedImage, quality: validQuality, format: format) ?? resizedImage
    }
    
    // MARK: - Private Helper Methods
    
    /// Compress image to the specified format and quality
    private func compressImage(_ image: UIImage, quality: CGFloat, format: ImageFormat) -> UIImage? {
        return autoreleasepool { () -> UIImage? in
            let data: Data?
            
            switch format {
            case .jpeg:
                data = image.jpegData(compressionQuality: quality)
            case .png:
                data = image.pngData()
            }
            
            guard let imageData = data else {
                return nil
            }
            
            return UIImage(data: imageData)
        }
    }
}
