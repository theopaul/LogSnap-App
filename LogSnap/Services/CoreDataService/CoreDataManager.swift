import CoreData
import SwiftUI
import UIKit
import CloudKit

class CoreDataManager {
    // Simplified shared instance
    static let shared = CoreDataManager()
    
    static var previewContext: NSManagedObjectContext = {
        let manager = CoreDataManager(inMemory: true)
        let context = manager.container.viewContext
        
        // Add sample data for previews
        let product = Product(context: context)
        product.name = "Sample Product"
        product.sku = "SKU123"
        product.category = "Electronics"
        product.price = 99.99
        product.currency = "USD"
        product.moq = 10
        product.dimensions = "10x20x30"
        product.weight = 2.5
        product.materials = "Plastic, Metal"
        product.notes = "Sample product notes"
        product.imagePaths = ["sample_image_path"] as NSArray
        product.createdAt = Date()
        product.updatedAt = Date()
        
        let supplier = Supplier(context: context)
        supplier.name = "Sample Supplier"
        supplier.contactPerson = "John Doe"
        supplier.email = "john@example.com"
        supplier.phone = "+1 123-456-7890"
        supplier.address = "123 Main St, City, Country"
        supplier.website = "https://example.com"
        supplier.notes = "Sample supplier notes"
        supplier.notableClients = "Client A, Client B"
        supplier.brandsRepresented = "Brand X, Brand Y"
        
        // Create sample contact for the supplier
        let contact = ContactPerson(context: context)
        contact.id = UUID()
        contact.name = "John Doe"
        contact.jobTitle = "Sales Manager"
        contact.phone = "+1 123-456-7890"
        contact.email = "john@example.com"
        contact.whatsapp = "+1 123-456-7890"
        contact.wechatId = "johndoe123"
        contact.isPrimary = true
        contact.supplier = supplier
        
        try? context.save()
        return context
    }()
    
    let container: NSPersistentContainer
    private let userSettings: UserSettings?
    
    // Remove the old shared instance implementation
    // private static var sharedInstance: CoreDataManager?
    
    // Keep the factory method for backward compatibility
    static func shared(with userSettings: UserSettings) -> CoreDataManager {
        return shared
    }
    
    init(inMemory: Bool = false, userSettings: UserSettings? = nil) {
        self.userSettings = userSettings
        
        // Check if iCloud sync is enabled
        let isCloudKitEnabled = userSettings?.iCloudSyncEnabled ?? false
        
        // Create either a regular container or a CloudKit container
        if isCloudKitEnabled {
            // Use NSPersistentCloudKitContainer for iCloud sync
            container = NSPersistentCloudKitContainer(name: "LogSnap")
            print("DEBUG: Using CloudKit container for Core Data")
        } else {
            // Use regular persistent container
            container = NSPersistentContainer(name: "LogSnap")
            print("DEBUG: Using standard container for Core Data")
        }
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable automatic lightweight migration
        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        
        // Configure CloudKit integration if enabled
        if isCloudKitEnabled, let description = container.persistentStoreDescriptions.first {
            let containerIdentifier = description.cloudKitContainerOptions?.containerIdentifier ??
                                      "iCloud.com.yourdeveloper.logsnap"
            
            // Set up CloudKit container options
            let options = NSPersistentCloudKitContainerOptions(containerIdentifier: containerIdentifier)
            description.cloudKitContainerOptions = options
            
            // Set sync policy
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Se houver erro, tente resetar o store
                print("Erro ao carregar o store: \(error.localizedDescription)")
                print("Tentando resetar o Core Data...")
                
                self.resetCoreDataStore()
                
                // Tente carregar novamente após o reset
                self.container.loadPersistentStores { description, secondError in
                    if let secondError = secondError {
                        fatalError("Unresolved error after reset \(secondError)")
                    }
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Setup remote change notification handling for CloudKit
        if isCloudKitEnabled {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(processRemoteStoreChange),
                name: .NSPersistentStoreRemoteChange,
                object: container.persistentStoreCoordinator
            )
        }
        
        // Register the transformer for UIImage
        ValueTransformer.setValueTransformer(
            UIImageTransformer(),
            forName: NSValueTransformerName("UIImageTransformer")
        )
        
        // Create and configure the container
        let modelName = "LogSnap"
        
        // First try to find the model URL
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") ??
                             Bundle.main.url(forResource: "\(modelName)", withExtension: "xcdatamodeld") else {
            fatalError("Failed to find Core Data model: \(modelName)")
        }
        
        // Check if model exists and can be created
        guard NSManagedObjectModel(contentsOf: modelURL) != nil else {
            fatalError("Failed to load Core Data model: \(modelName)")
        }
        
        // No longer trying to set managedObjectModel, which doesn't exist
    }
    
    @objc func processRemoteStoreChange(_ notification: Notification) {
        print("DEBUG: Remote store changes detected - merging changes")
        container.viewContext.perform {
            self.container.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    // Toggle CloudKit sync
    func toggleCloudKitSync(enabled: Bool) {
        // This requires app restart, so we just update the setting
        print("DEBUG: CloudKit sync \(enabled ? "enabled" : "disabled") - will take effect after app restart")
    }
    
    // Reset Core Data store se necessário
    private func resetCoreDataStore() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("Não foi possível encontrar o URL do Core Data store")
            return
        }
        
        do {
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            print("Core Data store resetado com sucesso")
        } catch {
            print("Falha ao resetar o Core Data store: \(error)")
        }
    }
    
    // MARK: - Stability Improvements
    
    /// Verifica se há erros de validação no contexto e tenta resolver antes de salvar
    func validateAndFixContext() {
        let context = container.viewContext
        
        // Verifica entidades com problemas
        do {
            try context.obtainPermanentIDs(for: Array(context.insertedObjects))
            
            if !context.insertedObjects.isEmpty {
                print("Verificando \(context.insertedObjects.count) objetos inseridos")
            }
            
            // Verifica cada objeto modificado ou inserido para garantir validade
            for object in context.insertedObjects.union(context.updatedObjects) {
                try object.validateForUpdate()
            }
        } catch {
            print("Erro de validação detectado: \(error.localizedDescription)")
            
            // Desfazer alterações problemáticas se necessário
            context.rollback()
        }
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            // Tenta validar e corrigir problemas antes de salvar
            validateAndFixContext()
            
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Erro ao salvar Core Data: \(nsError), \(nsError.userInfo)")
                
                // Tenta resolver conflitos de constraints
                if nsError.domain == NSCocoaErrorDomain &&
                   nsError.code == NSValidationMultipleErrorsError {
                    print("Detectados múltiplos erros de validação, tentando resolver individualmente...")
                }
                
                // Registra erros específicos para Debug
                if let errors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                    for detailedError in errors {
                        print("Erro detalhado: \(detailedError.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Create a new ContactPerson entity with defaults initialized
    func createContactPerson() -> ContactPerson {
        let contact = ContactPerson(context: container.viewContext)
        contact.id = UUID()
        contact.name = ""
        contact.jobTitle = ""
        contact.phone = ""
        contact.whatsapp = ""
        contact.wechatId = ""
        contact.email = ""
        contact.isPrimary = false
        return contact
    }
    
    // Create a new BusinessCard entity
    func createBusinessCard(for image: UIImage) -> BusinessCard {
        let card = BusinessCard(context: container.viewContext)
        // Always optimize images before storing in Core Data
        card.cardImage = image.optimizedForStorage()
        card.id = UUID()
        return card
    }
}

// MARK: - UIImage Safety Extensions
extension UIImage {
    /// Verifica se a imagem tem dimensões válidas
    var hasValidDimensions: Bool {
        return size.width > 0 && size.height > 0 &&
              !size.width.isNaN && !size.height.isNaN &&
               size.width.isFinite && size.height.isFinite
    }
    
    /// Corrige problemas comuns de imagem que causam erros no CoreGraphics
    func fixImageIssues() -> UIImage? {
        guard hasValidDimensions else {
            print("Imagem com dimensões inválidas detectada e rejeitada")
            return nil
        }
        
        // Corrige a orientação
        if imageOrientation != .up {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            draw(in: CGRect(origin: .zero, size: size))
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return normalizedImage
        }
        
        return self
    }
    
    /// Versão melhorada do optimizedForStorage
    func optimizedForStorage() -> UIImage {
        // Primeiro corrige problemas
        if let fixedImage = fixImageIssues() {
            // Então otimiza para armazenamento
            let maxDimension: CGFloat = 1200
            let width = fixedImage.size.width
            let height = fixedImage.size.height
            
            if width > maxDimension || height > maxDimension {
                let aspectRatio = width / height
                
                // Proteção contra aspect ratio inválido
                guard aspectRatio.isFinite, !aspectRatio.isNaN, aspectRatio > 0 else {
                    return fixedImage
                }
                
                var newSize: CGSize
                if width > height {
                    let newWidth = min(width, maxDimension)
                    newSize = CGSize(width: newWidth, height: newWidth / aspectRatio)
                } else {
                    let newHeight = min(height, maxDimension)
                    newSize = CGSize(width: newHeight * aspectRatio, height: newHeight)
                }
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                fixedImage.draw(in: CGRect(origin: .zero, size: newSize))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? fixedImage
                UIGraphicsEndImageContext()
                
                return resizedImage
            }
            
            return fixedImage
        }
        
        return self
    }
}
