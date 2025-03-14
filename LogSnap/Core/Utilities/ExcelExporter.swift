import Foundation

// Note: A full Excel exporter would require a third-party library like XLSXWriter
// For this implementation, we'll create an Excel-compatible CSV file with .xlsx extension
class ExcelExporter {
    // MARK: - Properties
    private let csvExporter = CSVExporter()
    private let fileManager = FileManager.default
    
    // MARK: - Public Methods
    /// Export products to Excel (xlsx) file and return the file URL
    func exportProducts(_ products: [Product]) -> URL? {
        // First export as CSV
        guard let csvURL = csvExporter.exportProducts(products) else {
            return nil
        }
        
        // Create an Excel-compatible version by copying and renaming
        return createExcelFile(from: csvURL, withName: "LogSnap_Products.xlsx")
    }
    
    /// Export suppliers to Excel (xlsx) file and return the file URL
    func exportSuppliers(_ suppliers: [Supplier]) -> URL? {
        // First export as CSV
        guard let csvURL = csvExporter.exportSuppliers(suppliers) else {
            return nil
        }
        
        // Create an Excel-compatible version by copying and renaming
        return createExcelFile(from: csvURL, withName: "LogSnap_Suppliers.xlsx")
    }
    
    // MARK: - Private Methods
    /// Create an Excel file from a CSV file
    private func createExcelFile(from csvURL: URL, withName filename: String) -> URL? {
        do {
            // Get the document directory URL
            let directory = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            // Create Excel file URL
            let excelURL = directory.appendingPathComponent(filename)
            
            // If file exists, remove it
            if fileManager.fileExists(atPath: excelURL.path) {
                try fileManager.removeItem(at: excelURL)
            }
            
            // Copy CSV to Excel file
            try fileManager.copyItem(at: csvURL, to: excelURL)
            
            return excelURL
        } catch {
            print("Error creating Excel file: \(error.localizedDescription)")
            return nil
        }
    }
} 