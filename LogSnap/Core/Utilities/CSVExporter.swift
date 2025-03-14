import Foundation

class CSVExporter {
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let encoding: String.Encoding = .utf8
    
    // MARK: - Public Methods
    /// Export products to CSV file and return the file URL
    func exportProducts(_ products: [Product]) -> URL? {
        // Create CSV string with headers
        var csvString = "Name,SKU,Category,Price,Currency,MOQ,Dimensions,Weight,Materials,Notes,Created,Updated\n"
        
        // Add each product as a row
        for product in products {
            let row = [
                csvEscape(product.name ?? ""),
                csvEscape(product.sku ?? ""),
                csvEscape(product.category ?? ""),
                String(product.price),
                csvEscape(product.currency ?? ""),
                String(product.moq),
                csvEscape(product.dimensions ?? ""),
                String(product.weight),
                csvEscape(product.materials ?? ""),
                csvEscape(product.notes ?? ""),
                formatDate(product.createdAt),
                formatDate(product.updatedAt)
            ].joined(separator: ",")
            
            csvString.append(row + "\n")
        }
        
        // Save to file
        return saveCSVToFile(csvString, filename: "LogSnap_Products.csv")
    }
    
    /// Export suppliers to CSV file and return the file URL
    func exportSuppliers(_ suppliers: [Supplier]) -> URL? {
        // Create CSV string with headers
        var csvString = "Name,Contact Person,Email,Phone,Address,Website,Notes\n"
        
        // Add each supplier as a row
        for supplier in suppliers {
            let row = [
                csvEscape(supplier.name ?? ""),
                csvEscape(supplier.contactPerson ?? ""),
                csvEscape(supplier.email ?? ""),
                csvEscape(supplier.phone ?? ""),
                csvEscape(supplier.address ?? ""),
                csvEscape(supplier.website ?? ""),
                csvEscape(supplier.notes ?? "")
            ].joined(separator: ",")
            
            csvString.append(row + "\n")
        }
        
        // Save to file
        return saveCSVToFile(csvString, filename: "LogSnap_Suppliers.csv")
    }
    
    // MARK: - Private Methods
    /// Save CSV string to a file and return the file URL
    private func saveCSVToFile(_ csvString: String, filename: String) -> URL? {
        guard let data = csvString.data(using: encoding) else { return nil }
        
        do {
            // Get the document directory URL
            let directory = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            
            // Create file URL
            let fileURL = directory.appendingPathComponent(filename)
            
            // Write to file
            try data.write(to: fileURL)
            
            return fileURL
        } catch {
            print("Error saving CSV file: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Format a date for CSV output
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// Escape a string for CSV format
    private func csvEscape(_ string: String) -> String {
        let escapedString = string.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedString)\""
    }
} 