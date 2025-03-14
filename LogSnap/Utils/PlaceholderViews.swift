import SwiftUI
import CoreData

// Shared placeholder views that can be used across the app
// This helps avoid duplicate view declarations

struct ProductDetailPlaceholder: View {
    let product: Product
    
    var body: some View {
        VStack {
            // This is a placeholder that would be replaced with your actual ProductDetailView
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(product.name ?? "Unnamed Product")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    if let sku = product.sku, !sku.isEmpty {
                        Text("SKU: \(sku)")
                            .font(.headline)
                    }
                    
                    if let category = product.category, !category.isEmpty {
                        Text("Category: \(category)")
                    }
                    
                    if let price = product.value(forKey: "price") as? NSNumber {
                        let priceValue = price.doubleValue
                        if priceValue > 0 {
                            Text("Price: \(priceValue, specifier: "%.2f") \(product.currency ?? "")")
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(product.name ?? "Product Details")
    }
}

struct SupplierDetailPlaceholder: View {
    let supplier: Supplier
    
    var body: some View {
        VStack {
            // This is a placeholder that would be replaced with your actual SupplierDetailView
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(supplier.name ?? "Unnamed Supplier")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    if let email = supplier.email, !email.isEmpty {
                        Text("Email: \(email)")
                    }
                    
                    if let phone = supplier.phone, !phone.isEmpty {
                        Text("Phone: \(phone)")
                    }
                    
                    if let address = supplier.address, !address.isEmpty {
                        Text("Address: \(address)")
                    }
                    
                    // Using KVC to get contacts since it may not be directly accessible
                    if let contacts = supplier.value(forKey: "contacts") as? NSSet, contacts.count > 0 {
                        Text("Contacts: \(contacts.count)")
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationTitle(supplier.name ?? "Supplier Details")
    }
} 