import Foundation
import CoreData
import UIKit

extension BusinessCard {
    // Initialize default values
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        // Set a UUID when a new card is created
        self.id = UUID()
        // No need to set cardImage to nil as it's already nil by default
    }
    
    // Safely get an image
    var image: UIImage? {
        return cardImage
    }
} 