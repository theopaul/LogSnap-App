import Foundation
import CoreData
import UIKit

// Force UIKit inclusion in compilation for generated Core Data files
// To fix 'UIImage' not found in scope error in generated files

#if SWIFT_PACKAGE
import UIKit

extension NSManagedObject {
    // Dummy method to ensure UIKit is linked
    @objc public class func _ensureUIKitLinked() {
        _ = UIImage(systemName: "star")
    }
}
#endif

// Explicitly define transformable attribute types for Core Data
@objc(UIImageValueTransformerWrapper)
public class UIImageValueTransformerWrapper: NSObject {
    @objc public static func registerTransformer() {
        UIImageValueTransformer.register()
    }
} 