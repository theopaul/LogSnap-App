import Foundation
import CoreData
import UIKit

// This file ensures UIKit is available to Core Data generated files
// It is compiled early in the build process to make UIImage available

// Core Data UIImage transformer
@objc(UIImageTransformer)
public class UIImageTransformer: NSSecureUnarchiveFromDataTransformer {
    
    public static let transformerName = NSValueTransformerName(rawValue: "UIImageTransformer")
    
    public static func register() {
        let transformer = UIImageTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: transformerName)
    }
    
    public override class func transformedValueClass() -> AnyClass {
        return UIImage.self
    }
    
    public override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    public override func transformedValue(_ value: Any?) -> Any? {
        guard let image = value as? UIImage else { return nil }
        
        // Compress and optimize the image for storage
        return try? NSKeyedArchiver.archivedData(withRootObject: image, requiringSecureCoding: true)
    }
    
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIImage.self, from: data)
    }
} 