import Foundation
import CoreData
import UIKit

// Extensions for the ContactPerson entity
extension ContactPerson {
    // Initialize default values when a new entity is created
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        name = ""
        jobTitle = ""
        phone = ""
        whatsapp = ""
        wechatId = ""
        email = ""
        isPrimary = false
    }
    
    // Check if the contact is empty
    func isEmpty() -> Bool {
        return name?.isEmpty ?? true && 
               jobTitle?.isEmpty ?? true && 
               phone?.isEmpty ?? true && 
               whatsapp?.isEmpty ?? true && 
               wechatId?.isEmpty ?? true && 
               email?.isEmpty ?? true
    }
    
    // Get business card image
    var businessCardImage: UIImage? {
        return businessCard?.cardImage as? UIImage
    }
    
    // Set the business card for this contact
    func setBusinessCard(_ card: BusinessCard) {
        self.businessCard = card
    }
    
    // Remove the business card from this contact
    func removeBusinessCard() {
        self.businessCard = nil
    }
} 