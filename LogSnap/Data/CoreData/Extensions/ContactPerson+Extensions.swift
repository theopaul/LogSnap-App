import Foundation
import CoreData
import UIKit

// Specify the full module name to avoid ambiguity
extension LogSnap.ContactPerson {
    var businessCardsArray: [LogSnap.BusinessCard] {
        let cards = businessCards?.allObjects as? [LogSnap.BusinessCard] ?? []
        return cards
    }
    
    func addCard(_ card: LogSnap.BusinessCard) {
        addToBusinessCards(card)
    }
    
    func removeCard(_ card: LogSnap.BusinessCard) {
        removeFromBusinessCards(card)
    }
    
    func isEmpty() -> Bool {
        return name?.isEmpty ?? true && 
               jobTitle?.isEmpty ?? true && 
               phone?.isEmpty ?? true && 
               whatsapp?.isEmpty ?? true && 
               wechatId?.isEmpty ?? true && 
               email?.isEmpty ?? true
    }
    
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
} 