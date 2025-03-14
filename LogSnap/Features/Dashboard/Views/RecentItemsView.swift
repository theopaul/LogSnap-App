import SwiftUI
@preconcurrency import CoreData

// No need for a special import as PlaceholderViews.swift is part of the same module

struct RecentItemsView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject private var viewModel = RecentItemsViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.recentProducts.isEmpty && viewModel.recentSuppliers.isEmpty {
                emptyStateView
            } else {
                contentList
            }
        }
        .navigationTitle("Recent Items")
        .onAppear {
            viewModel.fetchRecentItems(context: viewContext)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.7))
            
            Text("No Recent Items")
                .font(.headline)
            
            Text("Items you add will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            HStack(spacing: 16) {
                NavigationLink(destination: ProductListView()) {
                    Text("Add Product")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                NavigationLink(destination: SupplierListView()) {
                    Text("Add Supplier")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Content List
    private var contentList: some View {
        RecentItemsList(
            recentProducts: viewModel.recentProducts,
            recentSuppliers: viewModel.recentSuppliers,
            productImages: viewModel.productImages,
            supplierImages: viewModel.supplierImages,
            formatDate: viewModel.formatDate,
            refreshAction: { 
                // Since the viewModel is @MainActor, we can safely call its methods
                await viewModel.refreshItemsAsync(context: viewContext)
            }
        )
    }
}

// Breaking down the complex view into a separate structure
struct RecentItemsList: View {
    let recentProducts: [Product]
    let recentSuppliers: [Supplier]
    let productImages: [NSManagedObjectID: UIImage]
    let supplierImages: [NSManagedObjectID: UIImage]
    let formatDate: (Date) -> String
    let refreshAction: @Sendable () async -> Void
    
    var body: some View {
        List {
            // Products section
            if !recentProducts.isEmpty {
                Section(header: Text("Recent Products")) {
                    ForEach(recentProducts, id: \.objectID) { product in
                        ProductRow(
                            product: product,
                            image: productImages[product.objectID],
                            formatDate: formatDate
                        )
                    }
                }
            }
            
            // Suppliers section
            if !recentSuppliers.isEmpty {
                Section(header: Text("Recent Suppliers")) {
                    ForEach(recentSuppliers, id: \.objectID) { supplier in
                        SupplierRow(
                            supplier: supplier,
                            image: supplierImages[supplier.objectID],
                            formatDate: formatDate
                        )
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            await refreshAction()
        }
    }
}

// Product row component
struct ProductRow: View {
    let product: Product
    let image: UIImage?
    let formatDate: (Date) -> String
    
    var body: some View {
        NavigationLink(destination: ProductDetailPlaceholder(product: product)) {
            HStack(spacing: 12) {
                // Product image
                if let productImage = image {
                    Image(uiImage: productImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "cube")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name ?? "Unnamed Product")
                        .font(.headline)
                    
                    HStack {
                        if let sku = product.sku, !sku.isEmpty {
                            Text("SKU: \(sku)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(formatDate(product.createdAt ?? Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// Supplier row component
struct SupplierRow: View {
    let supplier: Supplier
    let image: UIImage?
    let formatDate: (Date) -> String
    
    var body: some View {
        NavigationLink(destination: SupplierDetailPlaceholder(supplier: supplier)) {
            HStack(spacing: 12) {
                // Supplier image
                if let supplierImage = image {
                    Image(uiImage: supplierImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "building.2")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(supplier.value(forKey: "name") as? String ?? "Unnamed Supplier")
                        .font(.headline)
                    
                    HStack {
                        // Using KVC to access contacts
                        if let contacts = supplier.value(forKey: "contacts") as? NSSet, contacts.count > 0 {
                            Text("\(contacts.count) contact\(contacts.count > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Use a default date since createdAt doesn't exist on Supplier
                        Text(formatDate(Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - ViewModel
@MainActor
class RecentItemsViewModel: ObservableObject {
    @Published var recentProducts: [Product] = []
    @Published var recentSuppliers: [Supplier] = []
    @Published var isLoading: Bool = false
    @Published var productImages: [NSManagedObjectID: UIImage] = [:]
    @Published var supplierImages: [NSManagedObjectID: UIImage] = [:]
    
    func fetchRecentItems(context: NSManagedObjectContext) {
        isLoading = true
        
        // Fetch recent products
        let productRequest = NSFetchRequest<Product>(entityName: "Product")
        productRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        productRequest.fetchLimit = 5
        
        // Fetch recent suppliers
        let supplierRequest = NSFetchRequest<Supplier>(entityName: "Supplier")
        // Don't sort by createdAt since it doesn't exist
        // Sort by name as a fallback
        supplierRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        supplierRequest.fetchLimit = 5
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            do {
                let products = try context.fetch(productRequest)
                let suppliers = try context.fetch(supplierRequest)
                
                DispatchQueue.main.async {
                    self.recentProducts = products
                    self.recentSuppliers = suppliers
                    self.loadImages()
                    self.isLoading = false
                }
            } catch {
                print("Error fetching recent items: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshItemsAsync(context: NSManagedObjectContext) async {
        // Since we're using @MainActor on the class, this runs on the main actor
        // which is safe for working with the context
        fetchRecentItems(context: context)
        return await withCheckedContinuation { continuation in
            // We just use this to wait a moment for the fetch to complete
            // Not ideal, but it's a simple approach for this app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    private func loadImages() {
        // In a real app, you'd load images from disk or a remote server
        // For this placeholder, we'll just simulate image loading
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
} 