import Foundation
import CoreData
import UIKit

// IMPORTANT: This file ensures UIKit is properly linked with Core Data
// It is compiled early in the build process and contains necessary
// declarations to make UIImage available to Core Data generated files

// Explicitly import UIKit at compile time
@_exported import UIKit

// Force UIKit inclusion by using UIImage in class methods
extension NSManagedObject {
    // This method is never called, but forces UIKit linkage at compile time
    @objc public class func _ensureUIKitIsLinked() {
        _ = UIImage()
        _ = UIColor.red
    }
}

// Register the UIImage transformer
@objc public class CoreDataUIKitSupport: NSObject {
    @objc public static func registerUIImageTransformer() {
        UIImageTransformer.register()
    }
    
    // Initialize on load
    @objc public static let shared = CoreDataUIKitSupport()
    
    private override init() {
        super.init()
        Self.registerUIImageTransformer()
    }
}

// Ensure CoreDataUIKitSupport is initialized
private let ensureCoreDataUIKitSupport = CoreDataUIKitSupport.shared 