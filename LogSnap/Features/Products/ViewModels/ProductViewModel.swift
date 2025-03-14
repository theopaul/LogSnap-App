import Foundation
import SwiftUI
import CoreData
import Combine

class ProductViewModel: ObservableObject {
    // MARK: - Properties
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    
    // Form fields
    @Published var name: String = ""
    @Published var sku: String = ""
    @Published var category: String = ""
    @Published var price: String = ""
    @Published var currency: String = "USD"
    @Published var moq: String = ""
    @Published var dimensions: String = ""
    @Published var width: String = ""
    @Published var height: String = ""
    @Published var depth: String = ""
    @Published var weight: String = ""
    @Published var materials: String = ""
    @Published var notes: String = ""
    @Published var productImages: [UIImage] = []
    
    // New fields for China exhibition - these are stored in UserDefaults, not Core Data
    @Published var selectedSupplierID: String = ""
    @Published var incotermValue: String = "FOB"
    @Published var packingTypeValue: String = ""
    @Published var quantityPerBoxValue: String = ""
    @Published var productionTimeValue: String = ""
    @Published var portOfDepartureValue: String = ""
    @Published var certificationsValues: [String] = []
    @Published var otherCertification: String = ""
    
    // Form validation
    @Published var nameError: String? = nil
    @Published var skuError: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let coreDataManager: CoreDataManager = {
        let instance = CoreDataManager.shared
        return instance
    }()
    private var context: NSManagedObjectContext { coreDataManager.container.viewContext }
    
    // Constants
    let availableCurrencies = ["USD", "EUR", "RMB", "GBP", "JPY"]
    let availableIncoterms = ["FOB", "CIF", "EXW", "FCA", "CFR", "CPT", "CIP", "DAP", "DDP"]
    let availableCertifications = ["ISO 9001", "ISO 14004", "CE", "FDA", "RoHS", "REACH"]
    
    // MARK: - Initialization
    init() {
        setupSearchSubscription()
    }
    
    // MARK: - Methods
    func setupSearchSubscription() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.filterProducts(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    func filterProducts(searchText: String) {
        if searchText.isEmpty {
            filteredProducts = products
        } else {
            filteredProducts = products.filter { product in
                let nameMatch = product.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let skuMatch = product.sku?.localizedCaseInsensitiveContains(searchText) ?? false
                let categoryMatch = product.category?.localizedCaseInsensitiveContains(searchText) ?? false
                
                return nameMatch || skuMatch || categoryMatch
            }
        }
    }
    
    func fetchProducts() {
        isLoading = true
        
        DispatchQueue.main.async { [weak self] in
            guard let context = self?.coreDataManager.container.viewContext else {
                self?.isLoading = false
                return
            }
            
            let fetchRequest: NSFetchRequest<Product> = Product.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            do {
                self?.products = try context.fetch(fetchRequest)
                self?.filterProducts(searchText: self?.searchText ?? "")
                self?.isLoading = false
            } catch {
                print("Error fetching products: \(error)")
                self?.isLoading = false
            }
        }
    }
    
    // Add a refresh method to reload data when returning from add/edit screens
    func refreshProducts() {
        fetchProducts()
    }
    
    func validateForm() -> Bool {
        var isValid = true
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            nameError = NSLocalizedString("Name is required", comment: "")
            isValid = false
        } else {
            nameError = nil
        }
        
        skuError = nil
        
        return isValid
    }
    
    func saveProduct() -> Bool {
        guard validateForm() else { return false }
        
        let product = Product(context: context)
        updateProductProperties(product)
        
        do {
            try context.save()
            
            // Save images using the consistent ID format
            let productId = product.objectID.uriRepresentation().absoluteString
            let savedPaths = saveProductImages(images: productImages, for: productId)
            
            // Update the product's imagePaths attribute with the saved paths
            if !savedPaths.isEmpty {
                product.imagePaths = savedPaths as NSArray
                try context.save()
            }
            
            resetForm()
            fetchProducts()
            return true
        } catch {
            showAlert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
            return false
        }
    }
    
    func updateProduct(_ product: Product) -> Bool {
        guard validateForm() else { return false }
        
        updateProductProperties(product)
        
        do {
            try context.save()
            
            // Update images using the consistent ID format
            let productId = product.objectID.uriRepresentation().absoluteString
            let savedPaths = saveProductImages(images: productImages, for: productId)
            
            // Update the product's imagePaths attribute with the saved paths
            if !savedPaths.isEmpty {
                product.imagePaths = savedPaths as NSArray
                try context.save()
            }
            
            resetForm()
            fetchProducts()
            return true
        } catch {
            showAlert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
            return false
        }
    }
    
    func deleteProduct(_ product: Product) {
        // Delete images before deleting the product
        let productId = product.objectID.uriRepresentation().absoluteString
        
        // Get the actual image paths from the product
        var imagePaths: [String] = []
        if let paths = product.imagePaths as? [String] {
            imagePaths = paths
        } else if let paths = product.imagePaths as NSArray? {
            imagePaths = paths.compactMap { $0 as? String }
        }
        
        // Delete the images
        if !imagePaths.isEmpty {
            deleteProductImages(paths: imagePaths)
        } else {
            print("DEBUG: No image paths found for product \(productId)")
        }
        
        context.delete(product)
        
        do {
            try context.save()
            fetchProducts()
        } catch {
            showAlert(title: NSLocalizedString("Error", comment: ""), message: error.localizedDescription)
        }
    }
    
    func loadProductForEditing(_ product: Product) {
        // Load basic info
        name = product.name ?? ""
        sku = product.sku ?? ""
        category = product.category ?? ""
        
        // Load pricing
        price = product.price > 0 ? String(format: "%.2f", product.price) : ""
        currency = product.currency ?? "USD"
        moq = product.moq > 0 ? String(product.moq) : ""
        
        // Load dimensions
        let dimensionsComponents = product.getDimensionsComponents()
        width = dimensionsComponents.width
        height = dimensionsComponents.height
        depth = dimensionsComponents.depth
        
        // Load other specs
        weight = product.weight > 0 ? String(format: "%.2f", product.weight) : ""
        materials = product.materials ?? ""
        
        // Load supplier
        if let supplier = product.supplier {
            selectedSupplierID = supplier.objectID.uriRepresentation().absoluteString
        }
        
        // Load additional properties using UserDefaults
        let productId = product.objectID.uriRepresentation().absoluteString
        packingTypeValue = getPackingType(forProduct: productId)
        quantityPerBoxValue = getQuantityPerBox(forProduct: productId) > 0 ? String(getQuantityPerBox(forProduct: productId)) : ""
        productionTimeValue = getProductionTime(forProduct: productId) > 0 ? String(getProductionTime(forProduct: productId)) : ""
        portOfDepartureValue = getPortOfDeparture(forProduct: productId)
        incotermValue = getIncoterm(forProduct: productId)
        
        // Load notes
        notes = product.notes ?? ""
        
        // Load images using the product's imagePaths
        var imagePaths: [String] = []
        if let paths = product.imagePaths as? [String] {
            imagePaths = paths
        } else if let paths = product.imagePaths as NSArray? {
            imagePaths = paths.compactMap { $0 as? String }
        }
        
        if !imagePaths.isEmpty {
            productImages = loadProductImages(paths: imagePaths)
        } else {
            print("DEBUG: No image paths found for product \(productId)")
            productImages = []
        }
    }
    
    func resetForm() {
        name = ""
        sku = ""
        category = ""
        price = ""
        currency = "USD"
        moq = ""
        dimensions = ""
        width = ""
        height = ""
        depth = ""
        weight = ""
        materials = ""
        notes = ""
        productImages = []
        
        nameError = nil
        skuError = nil
        
        // Reset additional fields
        selectedSupplierID = ""
        incotermValue = "FOB"
        packingTypeValue = ""
        quantityPerBoxValue = ""
        productionTimeValue = ""
        portOfDepartureValue = ""
        certificationsValues = []
        otherCertification = ""
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Certification Management
    func toggleCertification(_ certification: String) {
        if certificationsValues.contains(certification) {
            certificationsValues.removeAll(where: { $0 == certification })
        } else {
            certificationsValues.append(certification)
        }
    }
    
    // MARK: - Additional Product Details
    private func saveProductAdditionalDetails(for productIDString: String) {
        let defaults = UserDefaults.standard
        
        // Create a dictionary to store additional details
        let additionalDetails: [String: Any] = [
            "incoterm": incotermValue,
            "packingType": packingTypeValue,
            "quantityPerBox": quantityPerBoxValue,
            "productionTime": productionTimeValue,
            "portOfDeparture": portOfDepartureValue,
            "certifications": certificationsValues,
            "otherCertification": otherCertification
        ]
        
        // Retrieve existing products dictionary or create a new one
        if var productsDict = defaults.dictionary(forKey: "ProductsAdditionalDetails") as? [String: [String: Any]] {
            productsDict[productIDString] = additionalDetails
            defaults.set(productsDict, forKey: "ProductsAdditionalDetails")
        } else {
            let newDict = [productIDString: additionalDetails]
            defaults.set(newDict, forKey: "ProductsAdditionalDetails")
        }
        
        defaults.synchronize()
    }
    
    func loadProductAdditionalDetails(for productIDString: String) {
        let defaults = UserDefaults.standard
        
        if let productsDict = defaults.dictionary(forKey: "ProductsAdditionalDetails") as? [String: [String: Any]],
           let details = productsDict[productIDString] {
            
            incotermValue = details["incoterm"] as? String ?? "FOB"
            packingTypeValue = details["packingType"] as? String ?? ""
            quantityPerBoxValue = details["quantityPerBox"] as? String ?? ""
            productionTimeValue = details["productionTime"] as? String ?? ""
            portOfDepartureValue = details["portOfDeparture"] as? String ?? ""
            certificationsValues = details["certifications"] as? [String] ?? []
            otherCertification = details["otherCertification"] as? String ?? ""
        }
    }
    
    // MARK: - Image Handling

    func saveProductImages(images: [UIImage], for productID: String) -> [String] {
        print("DEBUG: Saving \(images.count) product images for product ID \(productID)")
        
        // Early validation
        if images.isEmpty {
            print("DEBUG: No images to save")
            return []
        }
        
        var savedPaths: [String] = []
        
        for (index, image) in images.enumerated() {
            // Validate image dimensions
            guard image.size.width > 0, image.size.height > 0,
                  !image.size.width.isNaN, !image.size.height.isNaN else {
                print("ERROR: Invalid image dimensions for image \(index)")
                continue
            }
            
            // Use the ImageFileManager to save the image
            if let relativePath = ImageFileManager.shared.saveImage(
                image: image,
                withID: productID,
                category: .product
            ) {
                print("DEBUG: Successfully saved product image \(index) at \(relativePath)")
                savedPaths.append(relativePath)
            } else {
                print("ERROR: Failed to save product image \(index)")
                
                // Attempt fallback to UserDefaults storage
                if let imageData = image.jpegData(compressionQuality: 0.6) {
                    let fallbackKey = "product_image_\(productID)_\(index)"
                    UserDefaults.standard.set(imageData, forKey: fallbackKey)
                    print("DEBUG: Saved image data to UserDefaults as fallback")
                    savedPaths.append("userdefaults:\(fallbackKey)")
                }
            }
        }
        
        return savedPaths
    }
    
    func loadProductImages(paths: [String]) -> [UIImage] {
        print("DEBUG: Loading \(paths.count) product images")
        
        var loadedImages: [UIImage] = []
        
        for (index, path) in paths.enumerated() {
            // Check if this is a UserDefaults fallback path
            if path.starts(with: "userdefaults:") {
                let key = String(path.dropFirst("userdefaults:".count))
                if let imageData = UserDefaults.standard.data(forKey: key),
                   let image = UIImage(data: imageData) {
                    print("DEBUG: Loaded image \(index) from UserDefaults fallback")
                    loadedImages.append(image)
                } else {
                    print("ERROR: Failed to load image \(index) from UserDefaults fallback")
                }
                continue
            }
            
            // Use the ImageFileManager to load the image
            if let image = ImageFileManager.shared.loadImage(from: path) {
                print("DEBUG: Successfully loaded product image \(index) from \(path)")
                loadedImages.append(image)
            } else {
                print("ERROR: Failed to load product image \(index) from \(path)")
                
                // Add a placeholder image
                loadedImages.append(createPlaceholderImage())
            }
        }
        
        return loadedImages
    }
    
    func deleteProductImages(paths: [String]) {
        print("DEBUG: Deleting \(paths.count) product images")
        
        for (index, path) in paths.enumerated() {
            // Check if this is a UserDefaults fallback path
            if path.starts(with: "userdefaults:") {
                let key = String(path.dropFirst("userdefaults:".count))
                UserDefaults.standard.removeObject(forKey: key)
                print("DEBUG: Removed image \(index) from UserDefaults")
                continue
            }
            
            // Use the ImageFileManager to delete the image
            if ImageFileManager.shared.deleteImage(at: path) {
                print("DEBUG: Successfully deleted product image \(index) at \(path)")
            } else {
                print("ERROR: Failed to delete product image \(index) at \(path)")
            }
        }
    }
    
    // Helper method to create a placeholder image with enhanced error handling
    private func createPlaceholderImage() -> UIImage {
        // UIGraphicsImageRenderer doesn't throw errors directly, so we need to handle potential failures differently
        let size = CGSize(width: 100, height: 100)
        
        // Validate the size is valid for a CoreGraphics context
        guard size.width > 0, size.height > 0,
              size.width.isFinite, size.height.isFinite,
              !size.width.isNaN, !size.height.isNaN else {
            print("ERROR: Invalid size for placeholder image")
            // Return a 1x1 pixel image as an absolute fallback
            UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
            UIColor.gray.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image ?? UIImage()
        }
        
        // Create the image using renderer
        let renderer = UIGraphicsImageRenderer(size: size)
        let placeholderImage = renderer.image { ctx in
            // Draw background
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            
            // Draw text safely
            UIColor.systemGray.setFill()
            let text = "No Image" as NSString
            let font = UIFont.systemFont(ofSize: 12)
            
            // Create a safe text rect with validation
            let textRect = CGRect(x: 10, y: 40, width: 80, height: 20)
            guard textRect.origin.x >= 0, textRect.origin.y >= 0,
                  textRect.size.width > 0, textRect.size.height > 0,
                  textRect.origin.x.isFinite, textRect.origin.y.isFinite,
                  textRect.size.width.isFinite, textRect.size.height.isFinite else {
                // Skip text drawing if rect is invalid
                return
            }
            
            text.draw(in: textRect, withAttributes: [.font: font])
        }
        
        // Verify the result is valid
        if placeholderImage.size.width <= 0 || placeholderImage.size.height <= 0 {
            print("ERROR: Failed to create placeholder image properly")
            // Create an absolute fallback image using old-style API
            UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
            UIColor.gray.setFill()
            UIRectFill(CGRect(x: 0, y: 0, width: 1, height: 1))
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return image ?? UIImage()
        }
        
        return placeholderImage
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
    
    private func cleanupOldImages(for productId: String, in directory: URL, currentFilename: String) {
        do {
            let fileManager = FileManager.default
            let safeProductId = productId.replacingOccurrences(of: "/", with: "_")
                                          .replacingOccurrences(of: ":", with: "_")
            
            // Find all files for this product
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let oldFiles = contents.filter { 
                $0.lastPathComponent.starts(with: safeProductId) && 
                $0.lastPathComponent != currentFilename 
            }
            
            // Delete old files
            for file in oldFiles {
                try fileManager.removeItem(at: file)
                print("DEBUG: Cleaned up old image file: \(file.lastPathComponent)")
            }
        } catch {
            print("ERROR: Failed to clean up old product images: \(error.localizedDescription)")
        }
    }
    
    private func updateProductProperties(_ product: Product) {
        // Set basic properties
        product.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        product.sku = sku.trimmingCharacters(in: .whitespacesAndNewlines)
        product.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        product.price = Double(price) ?? 0.0
        product.currency = currency
        product.moq = Int32(moq) ?? 0
        product.dimensions = "\(width.trimmingCharacters(in: .whitespacesAndNewlines))×\(height.trimmingCharacters(in: .whitespacesAndNewlines))×\(depth.trimmingCharacters(in: .whitespacesAndNewlines))"
        product.weight = Double(weight) ?? 0.0
        product.materials = materials.trimmingCharacters(in: .whitespacesAndNewlines)
        product.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Set timestamps
        let productId = product.objectID.uriRepresentation().absoluteString
        
        // Set creation time if new
        if product.createdAt == nil {
            product.createdAt = Date()
        }
        
        // Always update the modification time
        product.updatedAt = Date()
        
        // Save supplier reference
        if !selectedSupplierID.isEmpty {
            // Try to get supplier object from Core Data
            let url = URL(string: selectedSupplierID)!
            let supplierObjectId = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url)
            
            if let supplierId = supplierObjectId,
               let supplier = try? context.existingObject(with: supplierId) as? Supplier {
                product.supplier = supplier
            }
            
            // Também guardar no UserDefaults como backup
            UserDefaults.standard.set(selectedSupplierID, forKey: "product_supplier_\(productId)")
        } else {
            product.supplier = nil
            UserDefaults.standard.removeObject(forKey: "product_supplier_\(productId)")
        }
        
        // Salvar detalhes adicionais no UserDefaults
        savePackingType(packingTypeValue, forProduct: productId)
        saveQuantityPerBox(Int(quantityPerBoxValue) ?? 0, forProduct: productId)
        saveProductionTime(Int(productionTimeValue) ?? 0, forProduct: productId)
        savePortOfDeparture(portOfDepartureValue, forProduct: productId)
        saveIncoterm(incotermValue, forProduct: productId)
    }
    
    // MARK: - UserDefaults Methods for Additional Product Properties
    
    // Packing Type
    private func getPackingType(forProduct productId: String?) -> String {
        guard let id = productId else { return "" }
        return UserDefaults.standard.string(forKey: "packingType_\(id)") ?? ""
    }
    
    private func savePackingType(_ packingType: String?, forProduct productId: String?) {
        guard let id = productId,
              let type = packingType else { return }
        UserDefaults.standard.set(type, forKey: "packingType_\(id)")
    }
    
    // Quantity Per Box
    private func getQuantityPerBox(forProduct productId: String) -> Int {
        return UserDefaults.standard.integer(forKey: "quantityPerBox_\(productId)")
    }
    
    private func saveQuantityPerBox(_ quantity: Int, forProduct productId: String) {
        UserDefaults.standard.set(quantity, forKey: "quantityPerBox_\(productId)")
    }
    
    // Production Time
    private func getProductionTime(forProduct productId: String) -> Int {
        return UserDefaults.standard.integer(forKey: "productionTime_\(productId)")
    }
    
    private func saveProductionTime(_ time: Int, forProduct productId: String) {
        UserDefaults.standard.set(time, forKey: "productionTime_\(productId)")
    }
    
    // Port of Departure
    private func getPortOfDeparture(forProduct productId: String?) -> String {
        return UserDefaults.standard.string(forKey: "portOfDeparture_\(productId ?? "")") ?? ""
    }
    
    private func savePortOfDeparture(_ port: String?, forProduct productId: String?) {
        if let id = productId {
            UserDefaults.standard.set(port, forKey: "portOfDeparture_\(id)")
        }
    }

    // Incoterm
    private func getIncoterm(forProduct productId: String?) -> String {
        return UserDefaults.standard.string(forKey: "incoterm_\(productId ?? "")") ?? "FOB"
    }
    
    private func saveIncoterm(_ incoterm: String?, forProduct productId: String?) {
        if let id = productId {
            UserDefaults.standard.set(incoterm, forKey: "incoterm_\(id)")
        }
    }
}

// MARK: - String Extension

// MARK: - Product Extension for Supplier Relationship
extension Product {
    // Custom method to access supplier through relationship
    func getSupplierSafely() -> Supplier? {
        // Try to find the supplier using the ID stored in UserDefaults
        let productId = self.objectID.uriRepresentation().absoluteString
        
        // Get the CoreDataManager instance directly
        let cdManager = CoreDataManager.shared
        
        guard let supplierIdString = UserDefaults.standard.string(forKey: "supplier_\(productId)"),
              let url = URL(string: supplierIdString),
              let objectId = cdManager.container.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else {
            return nil
        }
        
        // Return the supplier if found
        do {
            return try cdManager.container.viewContext.existingObject(with: objectId) as? Supplier
        } catch {
            print("Error fetching supplier: \(error)")
            return nil
        }
    }
}
