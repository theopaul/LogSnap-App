import Foundation
import CoreData
import UIKit

// This file ensures UIKit is available to Core Data generated files
// No implementation needed - just having this file with imports is sufficient

@objc(CoreDataUIImage)
@available(*, deprecated, message: "Use UIImage directly instead")
public class CoreDataUIImage: UIImage, @unchecked Sendable {} 