import SwiftUI
import CoreData

class SettingsViewModel: ObservableObject {
    // MARK: - Properties
    private let csvExporter = CSVExporter()
    private let excelExporter = ExcelExporter()
    private let coreDataManager = CoreDataManager.shared
    
    @Published var isExporting = false
    @Published var exportResult: ExportResult?
    
    // MARK: - Public Methods
    
    /// Export all products to CSV format
    @MainActor
    func exportProductsToCSV() {
        isExporting = true
        
        Task {
            let products = self.fetchAllProducts()
            if let fileURL = self.csvExporter.exportProducts(products) {
                exportResult = ExportResult(success: true, fileURL: fileURL)
            } else {
                exportResult = ExportResult(success: false, errorMessage: "Failed to export products to CSV.")
            }
            isExporting = false
        }
    }
    
    /// Export all products to Excel format
    @MainActor
    func exportProductsToExcel() {
        isExporting = true
        
        Task {
            let products = self.fetchAllProducts()
            if let fileURL = self.excelExporter.exportProducts(products) {
                exportResult = ExportResult(success: true, fileURL: fileURL)
            } else {
                exportResult = ExportResult(success: false, errorMessage: "Failed to export products to Excel.")
            }
            isExporting = false
        }
    }
    
    /// Export all suppliers to CSV format
    @MainActor
    func exportSuppliersToCSV() {
        isExporting = true
        
        Task {
            let suppliers = self.fetchAllSuppliers()
            if let fileURL = self.csvExporter.exportSuppliers(suppliers) {
                exportResult = ExportResult(success: true, fileURL: fileURL)
            } else {
                exportResult = ExportResult(success: false, errorMessage: "Failed to export suppliers to CSV.")
            }
            isExporting = false
        }
    }
    
    /// Export all suppliers to Excel format
    @MainActor
    func exportSuppliersToExcel() {
        isExporting = true
        
        Task {
            let suppliers = self.fetchAllSuppliers()
            if let fileURL = self.excelExporter.exportSuppliers(suppliers) {
                exportResult = ExportResult(success: true, fileURL: fileURL)
            } else {
                exportResult = ExportResult(success: false, errorMessage: "Failed to export suppliers to Excel.")
            }
            isExporting = false
        }
    }
    
    /// Delete all data from the app
    @MainActor
    func deleteAllData() {
        let context = coreDataManager.container.viewContext
        
        // Delete in batches to prevent memory issues
        do {
            // Delete products
            let productRequest: NSFetchRequest<NSFetchRequestResult> = Product.fetchRequest()
            let productDelete = NSBatchDeleteRequest(fetchRequest: productRequest)
            try context.execute(productDelete)
            
            // Delete suppliers
            let supplierRequest: NSFetchRequest<NSFetchRequestResult> = Supplier.fetchRequest()
            let supplierDelete = NSBatchDeleteRequest(fetchRequest: supplierRequest)
            try context.execute(supplierDelete)
            
            // Save changes
            try context.save()
            
            // Reset the context
            context.reset()
        } catch {
            print("Error deleting all data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetch all products from CoreData
    private func fetchAllProducts() -> [Product] {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        
        do {
            let context = coreDataManager.container.viewContext
            return try context.fetch(request)
        } catch {
            print("Error fetching products: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch all suppliers from CoreData
    private func fetchAllSuppliers() -> [Supplier] {
        let request: NSFetchRequest<Supplier> = Supplier.fetchRequest()
        
        do {
            let context = coreDataManager.container.viewContext
            return try context.fetch(request)
        } catch {
            print("Error fetching suppliers: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - Export Result
struct ExportResult: Equatable {
    let success: Bool
    let fileURL: URL?
    let errorMessage: String?
    
    init(success: Bool, fileURL: URL? = nil, errorMessage: String? = nil) {
        self.success = success
        self.fileURL = fileURL
        self.errorMessage = errorMessage
    }
    
    static func == (lhs: ExportResult, rhs: ExportResult) -> Bool {
        return lhs.success == rhs.success &&
               lhs.fileURL == rhs.fileURL &&
               lhs.errorMessage == rhs.errorMessage
    }
}
