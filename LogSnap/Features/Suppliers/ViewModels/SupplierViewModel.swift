import Foundation
import SwiftUI
import CoreData
import Combine

class SupplierViewModel: ObservableObject {
    // MARK: - Properties
    @Published var suppliers: [Supplier] = []
    @Published var filteredSuppliers: [Supplier] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    // Form fields
    @Published var name: String = ""
    @Published var category: String = ""
    @Published var website: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var address: String = ""
    @Published var notes: String = ""
    
    // Form validation
    @Published var nameError: String? = nil
    @Published var emailError: String? = nil
    
    // Images
    @Published var supplierImages: [UIImage] = []
    
    // Contacts
    @Published var contactPersons: [ContactPersonViewModel] = []
    @Published var editingContactPerson: ContactPersonViewModel?
    @Published var isEditingExistingContact: Bool = false
    private var editingContactIndex: Int?
    
    private var cancellables = Set<AnyCancellable>()
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    // Explicit initializer for when context is provided
    init(context: NSManagedObjectContext) {
        self.context = context
        setupBindings()
    }
    
    // Default initializer that uses the shared CoreDataManager
    init() {
        // Access CoreDataManager.shared directly to avoid initialization issues
        self.context = CoreDataManager.shared.container.viewContext
        setupBindings()
    }
    
    private func setupBindings() {
        // Call existing method to maintain compatibility
        setupSearchSubscription()
    }
    
    // MARK: - Methods
    private func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.filterSuppliers(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    func filterSuppliers(searchText: String) {
        if searchText.isEmpty {
            filteredSuppliers = suppliers
        } else {
            filteredSuppliers = suppliers.filter { supplier in
                let nameMatch = supplier.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let emailMatch = supplier.email?.localizedCaseInsensitiveContains(searchText) ?? false
                let phoneMatch = supplier.phone?.localizedCaseInsensitiveContains(searchText) ?? false
                
                return nameMatch || emailMatch || phoneMatch
            }
        }
    }
    
    func fetchSuppliers() {
        isLoading = true
        
        let fetchRequest: NSFetchRequest<Supplier> = Supplier.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            suppliers = try context.fetch(fetchRequest)
            filterSuppliers(searchText: searchText)
            isLoading = false
        } catch {
            print("Error fetching suppliers: \(error)")
            isLoading = false
        }
    }
    
    func refreshSuppliers() {
        fetchSuppliers()
    }
    
    func validateForm() -> Bool {
        var isValid = true
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            nameError = NSLocalizedString("Name is required", comment: "")
            isValid = false
        } else {
            nameError = nil
        }
        
        if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                emailError = NSLocalizedString("Invalid email format", comment: "")
                isValid = false
            } else {
                emailError = nil
            }
        }
        
        return isValid
    }
    
    func saveSupplier() -> Bool {
        guard validateForm() else { return false }
        
        let supplier = Supplier(context: context)
        updateSupplierProperties(supplier)
        
        do {
            try context.save()
            
            // Salvar imagens usando o novo método
            let supplierId = supplier.objectID.uriRepresentation().absoluteString
            saveSupplierImages(supplierImages, forSupplier: supplierId)
            
            resetForm()
            fetchSuppliers()
            return true
        } catch {
            showAlert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
            return false
        }
    }
    
    func updateSupplier(_ supplier: Supplier) -> Bool {
        guard validateForm() else { return false }
        
        updateSupplierProperties(supplier)
        
        do {
            try context.save()
            
            // Atualizar imagens usando o novo método
            let supplierId = supplier.objectID.uriRepresentation().absoluteString
            saveSupplierImages(supplierImages, forSupplier: supplierId)
            
            resetForm()
            fetchSuppliers()
            return true
        } catch {
            showAlert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
            return false
        }
    }
    
    private func updateSupplierProperties(_ supplier: Supplier) {
        let context = supplier.managedObjectContext!
        
        // Basic info
        supplier.name = name
        // Category is stored in UserDefaults
        saveSupplierCategory(category, forSupplier: supplier.objectID.uriRepresentation().absoluteString)
        supplier.website = website
        supplier.email = email
        supplier.phone = phone
        supplier.address = address
        supplier.notes = notes
        
        // Images - store in UserDefaults
        saveSupplierImages(supplierImages, forSupplier: supplier.objectID.uriRepresentation().absoluteString)
        
        // Update timestamps - store in UserDefaults
        let now = Date()
        let supplierId = supplier.objectID.uriRepresentation().absoluteString
        if getSupplierCreatedAt(forSupplier: supplierId).timeIntervalSince1970 <= 0 {
            saveSupplierCreatedAt(now, forSupplier: supplierId)
        }
        saveSupplierUpdatedAt(now, forSupplier: supplierId)
        
        // Save contact persons
        // First remove all existing contact persons
        if let existingContacts = supplier.contacts as? Set<ContactPerson> {
            for contact in existingContacts {
                context.delete(contact)
            }
        }
        
        // Then add all the current ones
        let contacts = NSMutableSet()
        for contactViewModel in contactPersons {
            let contactPerson = ContactPerson(context: context)
            contactPerson.name = contactViewModel.name
            contactPerson.jobTitle = contactViewModel.position
            contactPerson.email = contactViewModel.email
            contactPerson.phone = contactViewModel.phone
            
            // Apply notes and image through the view model
            contactViewModel.apply(to: contactPerson)
            
            contacts.add(contactPerson)
        }
        
        supplier.contacts = contacts
    }
    
    func deleteSupplier(_ supplier: Supplier) {
        // Excluir imagens antes de excluir o fornecedor
        let supplierId = supplier.objectID.uriRepresentation().absoluteString
        deleteSupplierImages(forSupplier: supplierId)
        
        context.delete(supplier)
        
        do {
            try context.save()
            fetchSuppliers()
        } catch {
            showAlert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
        }
    }
    
    func loadSupplierForEditing(_ supplier: Supplier) {
        // Load basic info
        name = supplier.name ?? ""
        category = getSupplierCategory(forSupplier: supplier.objectID.uriRepresentation().absoluteString)
        website = supplier.website ?? ""
        email = supplier.email ?? ""
        phone = supplier.phone ?? ""
        address = supplier.address ?? ""
        notes = supplier.notes ?? ""
        
        // Load images from the file system
        supplierImages = getSupplierImages(forSupplier: supplier.objectID.uriRepresentation().absoluteString)
        
        // Load contact persons
        if let contacts = supplier.contacts {
            contactPersons = contacts.compactMap { contact in
                guard let person = contact as? ContactPerson else { return nil }
                
                return ContactPersonViewModel.from(contactPerson: person)
            }
        }
    }
    
    func resetForm() {
        name = ""
        category = ""
        website = ""
        email = ""
        phone = ""
        address = ""
        notes = ""
        contactPersons = []
        editingContactPerson = nil
        isEditingExistingContact = false
        editingContactIndex = nil
        supplierImages = []
        nameError = nil
        emailError = nil
    }
    
    // MARK: - Contact Person Methods
    
    func prepareToAddNewContactPerson() {
        editingContactPerson = ContactPersonViewModel()
        isEditingExistingContact = false
        editingContactIndex = nil
    }
    
    func prepareToEditContactPerson(_ index: Int) {
        guard index < contactPersons.count else { return }
        
        editingContactPerson = contactPersons[index]
        isEditingExistingContact = true
        editingContactIndex = index
    }
    
    func addContactPerson(_ contactPerson: ContactPersonViewModel) {
        contactPersons.append(contactPerson)
    }
    
    func updateContactPersonInList(_ updatedContactPerson: ContactPersonViewModel) {
        guard let index = editingContactIndex, index < contactPersons.count else { return }
        
        contactPersons[index] = updatedContactPerson
    }
    
    func removeContactPerson(at index: Int) {
        guard index < contactPersons.count else { return }
        
        contactPersons.remove(at: index)
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - UserDefaults Helpers
    
    // Add these UserDefaults helper methods
    private func saveSupplierCategory(_ category: String, forSupplier supplierId: String) {
        UserDefaults.standard.set(category, forKey: "supplier_category_\(supplierId)")
    }
    
    private func getSupplierCategory(forSupplier supplierId: String) -> String {
        return UserDefaults.standard.string(forKey: "supplier_category_\(supplierId)") ?? ""
    }
    
    // MARK: - Image Handling
    
    func saveSupplierImages(_ supplierImages: [UIImage], forSupplier supplierId: String) {
        guard !supplierImages.isEmpty else {
            print("DEBUG: No supplier images to save for \(supplierId)")
            // If no images, remove any existing saved images to avoid stale data
            deleteSupplierImages(forSupplier: supplierId)
            return
        }
        
        print("DEBUG: Saving \(supplierImages.count) supplier images for ID: \(supplierId)")
        
        // Optimize images before saving
        let optimizedImages = supplierImages.compactMap { image -> Data? in
            // Skip invalid images
            guard image.size.width > 0, image.size.height > 0,
                  !image.size.width.isNaN, !image.size.height.isNaN,
                  image.size.width.isFinite, image.size.height.isFinite else {
                print("DEBUG: Skipping invalid image in saveSupplierImages")
                return nil
            }
            
            // Resize if image is too large
            let maxDimension: CGFloat = 1200
            var finalImage = image
            
            if image.size.width > maxDimension || image.size.height > maxDimension {
                let scale = maxDimension / max(image.size.width, image.size.height)
                let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                
                // Use UIGraphicsImageRenderer for better quality/performance
                let renderer = UIGraphicsImageRenderer(size: newSize)
                finalImage = renderer.image { ctx in
                    ctx.cgContext.interpolationQuality = .high
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
            }
            
            // Compress with moderate quality
            return finalImage.jpegData(compressionQuality: 0.6)
        }
        
        guard !optimizedImages.isEmpty else {
            print("DEBUG: Failed to optimize any images for supplier \(supplierId)")
            return
        }
        
        // Use a more robust approach for file storage
        do {
            // Create a unique file name based on supplier ID and timestamp
            let safeId = supplierId.replacingOccurrences(of: "/", with: "_")
                                  .replacingOccurrences(of: ":", with: "_")
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "\(safeId)_\(timestamp).images"
            
            // Get application support directory path
            guard let appSupportDirectory = try getAppSupportDirectory() else {
                throw NSError(domain: "LogSnap", code: 1001, 
                             userInfo: [NSLocalizedDescriptionKey: "Cannot access application support directory"])
            }
            
            // Create suppliers directory
            let suppliersDirectory = appSupportDirectory.appendingPathComponent("SupplierImages", isDirectory: true)
            try createDirectoryIfNeeded(at: suppliersDirectory)
            
            // Full path to save the image file
            let imagePath = suppliersDirectory.appendingPathComponent(filename)
            print("DEBUG: Saving supplier images to path: \(imagePath.path)")
            
            // Use NSKeyedArchiver with proper security coding
            let imageData = try NSKeyedArchiver.archivedData(withRootObject: optimizedImages, requiringSecureCoding: true)
            
            // Write file with options
            try imageData.write(to: imagePath, options: [.atomicWrite, .completeFileProtection])
            
            // Store information in UserDefaults
            let relativePath = "SupplierImages/\(filename)"
            UserDefaults.standard.set(relativePath, forKey: "supplier_images_path_\(supplierId)")
            
            // Clean up any old images for this supplier
            cleanupOldImages(for: supplierId, in: suppliersDirectory, currentFilename: filename)
            
            print("DEBUG: Successfully saved supplier images to \(imagePath.path)")
        } catch {
            print("ERROR: Failed to save supplier images: \(error.localizedDescription)")
            
            // Fallback to UserDefaults only if absolutely necessary
            UserDefaults.standard.set(optimizedImages, forKey: "supplier_images_fallback_\(supplierId)")
        }
    }
    
    func getSupplierImages(forSupplier supplierId: String) -> [UIImage] {
        print("DEBUG: Loading supplier images for ID: \(supplierId)")
        
        // First try loading from file system
        if let relativePath = UserDefaults.standard.string(forKey: "supplier_images_path_\(supplierId)") {
            do {
                guard let appSupportDirectory = try getAppSupportDirectory() else {
                    throw NSError(domain: "LogSnap", code: 1002, 
                                 userInfo: [NSLocalizedDescriptionKey: "Cannot access application support directory"])
                }
                
                let imagePath = appSupportDirectory.appendingPathComponent(relativePath)
                print("DEBUG: Attempting to load from path: \(imagePath.path)")
                
                if FileManager.default.fileExists(atPath: imagePath.path) {
                    guard let imageData = try? Data(contentsOf: imagePath) else {
                        throw NSError(domain: "LogSnap", code: 1003, 
                                     userInfo: [NSLocalizedDescriptionKey: "Cannot read image data from file"])
                    }
                    
                    guard let imagesData = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSData.self], 
                                                                                 from: imageData) as? [Data] else {
                        throw NSError(domain: "LogSnap", code: 1004, 
                                     userInfo: [NSLocalizedDescriptionKey: "Cannot unarchive image data"])
                    }
                    
                    let loadedImages = imagesData.compactMap { UIImage(data: $0) }
                    if !loadedImages.isEmpty {
                        print("DEBUG: Successfully loaded \(loadedImages.count) supplier images from file")
                        return loadedImages
                    } else {
                        print("DEBUG: No valid images found in the loaded data")
                    }
                } else {
                    print("DEBUG: Image file does not exist at path: \(imagePath.path)")
                }
            } catch {
                print("ERROR: Error loading supplier images from file: \(error.localizedDescription)")
            }
        } else {
            print("DEBUG: No saved path found for supplier images with ID: \(supplierId)")
        }
        
        // Fallback to UserDefaults if file system failed
        if let imagesData = UserDefaults.standard.array(forKey: "supplier_images_fallback_\(supplierId)") as? [Data] {
            let loadedImages = imagesData.compactMap { UIImage(data: $0) }
            print("DEBUG: Loaded \(loadedImages.count) supplier images from UserDefaults fallback")
            return loadedImages
        } else {
            print("DEBUG: No fallback images found in UserDefaults for supplier: \(supplierId)")
        }
        
        return []
    }
    
    private func deleteSupplierImages(forSupplier supplierId: String) {
        print("DEBUG: Deleting supplier images for ID: \(supplierId)")
        
        // Clear from file system
        if let relativePath = UserDefaults.standard.string(forKey: "supplier_images_path_\(supplierId)") {
            do {
                guard let appSupportDirectory = try getAppSupportDirectory() else {
                    throw NSError(domain: "LogSnap", code: 1005, 
                                 userInfo: [NSLocalizedDescriptionKey: "Cannot access application support directory"])
                }
                
                let imagePath = appSupportDirectory.appendingPathComponent(relativePath)
                print("DEBUG: Attempting to delete file at path: \(imagePath.path)")
                
                if FileManager.default.fileExists(atPath: imagePath.path) {
                    try FileManager.default.removeItem(at: imagePath)
                    print("DEBUG: Successfully deleted supplier image file")
                } else {
                    print("DEBUG: File doesn't exist, nothing to delete at: \(imagePath.path)")
                }
            } catch {
                print("ERROR: Failed to delete supplier image file: \(error.localizedDescription)")
            }
        }
        
        // Clear from UserDefaults
        UserDefaults.standard.removeObject(forKey: "supplier_images_path_\(supplierId)")
        UserDefaults.standard.removeObject(forKey: "supplier_images_fallback_\(supplierId)")
        print("DEBUG: Cleared supplier image references from UserDefaults")
    }
    
    // MARK: - Directory and File Utilities
    
    private func getAppSupportDirectory() throws -> URL? {
        return try FileManager.default.url(for: .applicationSupportDirectory, 
                                          in: .userDomainMask, 
                                          appropriateFor: nil, 
                                          create: true)
    }
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, 
                                          withIntermediateDirectories: true,
                                          attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            print("DEBUG: Created directory at \(url.path)")
        }
    }
    
    private func cleanupOldImages(for supplierId: String, in directory: URL, currentFilename: String) {
        do {
            let fileManager = FileManager.default
            let safeId = supplierId.replacingOccurrences(of: "/", with: "_")
                                    .replacingOccurrences(of: ":", with: "_")
            
            // Find all files for this supplier
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let oldFiles = contents.filter { 
                $0.lastPathComponent.starts(with: safeId) && 
                $0.lastPathComponent != currentFilename 
            }
            
            // Delete old files
            for file in oldFiles {
                try fileManager.removeItem(at: file)
                print("DEBUG: Cleaned up old image file: \(file.lastPathComponent)")
            }
        } catch {
            print("ERROR: Failed to clean up old supplier images: \(error.localizedDescription)")
        }
    }
    
    private func saveSupplierCreatedAt(_ date: Date, forSupplier supplierId: String) {
        UserDefaults.standard.set(date, forKey: "supplier_createdAt_\(supplierId)")
    }
    
    private func getSupplierCreatedAt(forSupplier supplierId: String) -> Date {
        return UserDefaults.standard.object(forKey: "supplier_createdAt_\(supplierId)") as? Date ?? Date(timeIntervalSince1970: 0)
    }
    
    private func saveSupplierUpdatedAt(_ date: Date, forSupplier supplierId: String) {
        UserDefaults.standard.set(date, forKey: "supplier_updatedAt_\(supplierId)")
    }
}
