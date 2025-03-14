import Foundation
import CoreData
import UIKit

extension LogSnap.BusinessCard {
    // Initialize default values
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        // Explicit cast to fix contextual type issue
        self.frontImage = nil as UIImage?
    }
} 