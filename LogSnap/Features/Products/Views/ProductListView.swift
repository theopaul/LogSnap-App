import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    @State private var showAddProduct = false
    @State private var showSettingsView = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            productContentView
            
            FullScreenLoadingView(isLoading: viewModel.isLoading)
        }
        .navigationTitle(LocalizedStringKey("Products"))
        .sheet(isPresented: $showAddProduct) {
            NavigationStack {
                AddProductView(viewModel: viewModel, isPresented: $showAddProduct)
            }
            .onDisappear {
                // Ensure we refresh data after add/edit operation
                viewModel.refreshProducts()
            }
        }
        .sheet(isPresented: $showSettingsView) {
            NavigationView {
                SettingsView(useOwnNavigation: false)
                    .onDisappear {
                        // Allow a moment for the view to fully dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Reset any state or reload data if needed after settings close
                            viewModel.fetchProducts()
                        }
                    }
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            viewModel.fetchProducts()
            setupNotifications()
        }
        .onDisappear {
            cleanupNotifications()
        }
        // Keep the onReceive for SwiftUI's reactive updates
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAddProduct"))) { _ in
            showAddProduct = true
        }
    }
    
    // MARK: - Subviews
    
    private var productContentView: some View {
        VStack {
            searchBar
            
            if viewModel.isLoading {
                EnhancedLoadingView()
                    .padding()
            } else if viewModel.filteredProducts.isEmpty {
                emptyStateView
            } else {
                productsList
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(LocalizedStringKey("Search products..."), text: $viewModel.searchText)
                .disableAutocorrection(true)
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        Group {
            if viewModel.products.isEmpty {
                EnhancedEmptyStateView(
                    title: "No products found",
                    message: "Add your first product to get started!",
                    systemImage: "cube.box",
                    actionTitle: "Add Product",
                    action: { showAddProduct = true }
                )
            } else {
                EnhancedEmptyStateView(
                    title: "No products found",
                    message: "We couldn't find any products matching your search.",
                    systemImage: "magnifyingglass"
                )
            }
        }
    }
    
    private var productsList: some View {
        List {
            ForEach(viewModel.filteredProducts, id: \.self) { product in
                ProductRowItem(product: product, viewModel: viewModel)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Helper Methods
    
    private func setupNotifications() {
        // Set up notification observer when view appears
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowAddProduct"),
            object: nil,
            queue: .main
        ) { _ in
            self.showAddProduct = true
        }
    }
    
    private func cleanupNotifications() {
        // Clean up notification observer when view disappears
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ShowAddProduct"),
            object: nil
        )
    }
}

// MARK: - Product Row Item
struct ProductRowItem: View {
    let product: Product
    let viewModel: ProductViewModel
    
    var body: some View {
        NavigationLink {
            ProductDetailView(product: product)
        } label: {
            EnhancedProductRowView(
                productName: product.name ?? "",
                productSKU: product.sku ?? "",
                productCategory: product.category,
                productPrice: product.price,
                productCurrency: product.currency ?? "USD",
                productImage: product.getImages().first,
                showChevron: false,
                insideNavigationLink: true
            )
            .padding(.trailing, 10)
        }
        .id(product.objectID.uriRepresentation().absoluteString) // Ensure stable ID for navigation
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteProduct(product)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProductListView()
                .environment(\.managedObjectContext, CoreDataManager.previewContext)
                .environment(\.locale, .init(identifier: "en"))
        }
        
        NavigationView {
            ProductListView()
                .environment(\.managedObjectContext, CoreDataManager.previewContext)
                .environment(\.locale, .init(identifier: "pt"))
        }
        .previewDisplayName("Portuguese")
    }
}
