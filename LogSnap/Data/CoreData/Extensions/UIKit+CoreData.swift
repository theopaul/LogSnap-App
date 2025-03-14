import Foundation
import CoreData
import UIKit

// This file ensures UIKit is available to Core Data generated files
// To enable UIImage to be used as a Transformable attribute in Core Data models

// Extension to make UIImage compatible with Core Data's transformable type
extension UIImage {
    // Optimize image for Core Data storage
    func optimizedForCoreDataStorage() -> UIImage {
        // Validate input dimensions
        guard size.width > 0, size.height > 0,
              !size.width.isNaN, !size.height.isNaN,
              size.width.isFinite, size.height.isFinite,
              self.cgImage != nil || self.ciImage != nil else {
            print("ERROR: Invalid image dimensions in optimizedForCoreDataStorage")
            return self // Return original as fallback
        }
        
        // Check if image needs to be resized
        let maxDimension: CGFloat = 1024
        let currentMaxDimension = max(size.width, size.height)
        
        if currentMaxDimension > maxDimension {
            // Calculate scale with safety check
            guard currentMaxDimension > 0 else {
                print("ERROR: Invalid max dimension in optimizedForCoreDataStorage")
                return self
            }
            
            let scale = maxDimension / currentMaxDimension
            
            // Validate scale is reasonable
            guard scale > 0, scale < 1.0, scale.isFinite, !scale.isNaN else {
                print("ERROR: Invalid scale \(scale) calculated in optimizedForCoreDataStorage")
                return self
            }
            
            // Calculate new dimensions with validation
            let newWidth = size.width * scale
            let newHeight = size.height * scale
            
            guard newWidth > 0, newHeight > 0,
                  newWidth.isFinite, newHeight.isFinite,
                  !newWidth.isNaN, !newHeight.isNaN else {
                print("ERROR: Invalid new dimensions calculated: \(newWidth) x \(newHeight)")
                return self
            }
            
            let newSize = CGSize(width: newWidth, height: newHeight)
            
            // Use autoreleasepool for better memory management
            return autoreleasepool {
                // UIGraphicsImageRenderer doesn't throw errors directly
                let renderer = UIGraphicsImageRenderer(size: newSize)
                let resizedImage = renderer.image { _ in
                    self.draw(in: CGRect(origin: .zero, size: newSize))
                }
                
                // Verify the result is valid
                if resizedImage.size.width <= 0 || resizedImage.size.height <= 0 {
                    print("ERROR: Image rendering failed to produce valid dimensions")
                    return self
                }
                
                return resizedImage
            }
        }
        
        return self
    }
}

// DO NOT use typealias CoreDataUIImage = UIImage as it conflicts with the class in ManagedObjectModels.swift 