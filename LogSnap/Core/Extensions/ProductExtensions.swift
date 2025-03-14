import Foundation
import CoreData

// This extension provides temporary support for Product-Supplier relationships
// until the Core Data model can be properly updated
extension Product {
    private static let supplierKeyPrefix = "product_supplier_"
    
    // Get supplier ID for this product
    func getSupplierID() -> String? {
        let key = Self.supplierKeyPrefix + self.objectID.uriRepresentation().absoluteString
        return UserDefaults.standard.string(forKey: key)
    }
    
    // Set supplier ID for this product
    func setSupplierID(_ supplierID: String?) {
        let key = Self.supplierKeyPrefix + self.objectID.uriRepresentation().absoluteString
        if let supplierID = supplierID {
            UserDefaults.standard.set(supplierID, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // Get supplier for this product
    func getSupplier(in context: NSManagedObjectContext) -> Supplier? {
        guard let supplierIDString = getSupplierID(),
              let supplierURI = URL(string: supplierIDString),
              let supplierObjectID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: supplierURI) else {
            return nil
        }
        
        do {
            return try context.existingObject(with: supplierObjectID) as? Supplier
        } catch {
            print("Error fetching supplier: \(error)")
            return nil
        }
    }
    
    // Set supplier for this product
    func setSupplier(_ supplier: Supplier?) {
        if let supplier = supplier {
            let supplierIDString = supplier.objectID.uriRepresentation().absoluteString
            setSupplierID(supplierIDString)
        } else {
            setSupplierID(nil)
        }
    }
} 