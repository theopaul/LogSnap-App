import Foundation
import CoreData
import UIKit

// This class ensures UIKit is imported properly for Core Data transformable attributes

// Register a value transformer for UIImage
@objc(UIImageValueTransformer)
final class UIImageValueTransformer: NSSecureUnarchiveFromDataTransformer {
    
    static let name = NSValueTransformerName(rawValue: "UIImageValueTransformer")
    
    public static func register() {
        let transformer = UIImageValueTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
    
    override static var allowedTopLevelClasses: [AnyClass] {
        return [UIImage.self]
    }
}

// Add this to the top of AppDelegate.swift to register the transformer
// UIImageValueTransformer.register() 