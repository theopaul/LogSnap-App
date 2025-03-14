import Foundation
import CoreData
import SwiftUI

class DashboardViewModel: ObservableObject {
    @Published var productCount: Int = 0
    @Published var supplierCount: Int = 0
    @Published var contactCount: Int = 0
    @Published var recentItems: [String] = []
    @Published var isLoading: Bool = false
    
    private var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func refreshData(context: NSManagedObjectContext? = nil) {
        // Use provided context or fall back to the stored one
        let contextToUse = context ?? self.context
        
        // If a new context was provided, update our stored context
        if let newContext = context {
            self.context = newContext
        }
        
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let productCount = self.fetchCount(entityName: "Product", context: contextToUse)
            let supplierCount = self.fetchCount(entityName: "Supplier", context: contextToUse)
            let contactCount = self.fetchCount(entityName: "ContactPerson", context: contextToUse)
            
            DispatchQueue.main.async {
                self.productCount = productCount
                self.supplierCount = supplierCount
                self.contactCount = contactCount
                self.isLoading = false
            }
        }
    }
    
    private func fetchCount(entityName: String, context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        do {
            return try context.count(for: request)
        } catch {
            print("Error fetching count for \(entityName): \(error)")
            return 0
        }
    }
    
    func fetchRecentItems(limit: Int = 5) {
        // This would fetch the most recently updated/created items
        // For now, we'll leave it as a placeholder
    }
} 