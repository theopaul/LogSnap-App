import SwiftUI

struct SupplierListView: View {
    @StateObject private var viewModel = SupplierViewModel()
    @State private var showAddSupplier = false
    @State private var showSettingsView = false
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        ZStack {
            supplierContentView
            
            FullScreenLoadingView(isLoading: viewModel.isLoading)
        }
        .navigationTitle(LocalizedStringKey("Suppliers"))
        .sheet(isPresented: $showAddSupplier) {
            NavigationStack {
                AddSupplierView(viewModel: viewModel)
            }
            .onDisappear {
                // Ensure we refresh data after add/edit operation
                viewModel.refreshSuppliers()
            }
        }
        .sheet(isPresented: $showSettingsView) {
            NavigationView {
                SettingsView(useOwnNavigation: false)
                    .onDisappear {
                        // Allow a moment for the view to fully dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            // Reset any state or reload data if needed after settings close
                            viewModel.fetchSuppliers()
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
            viewModel.fetchSuppliers()
            setupNotifications()
        }
        .onDisappear {
            cleanupNotifications()
        }
        // Keep the onReceive for SwiftUI's reactive updates
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowAddSupplier"))) { _ in
            showAddSupplier = true
        }
    }
    
    // MARK: - Subviews
    
    private var supplierContentView: some View {
        VStack {
            searchBar
            
            if viewModel.isLoading {
                EnhancedLoadingView()
                    .padding()
            } else if viewModel.filteredSuppliers.isEmpty {
                emptyStateView
            } else {
                suppliersList
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(LocalizedStringKey("Search suppliers..."), text: $viewModel.searchText)
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
            if viewModel.suppliers.isEmpty {
                EnhancedEmptyStateView(
                    title: "No suppliers found",
                    message: "Add your first supplier to get started!",
                    systemImage: "building.2",
                    actionTitle: "Add Supplier",
                    action: { showAddSupplier = true }
                )
            } else {
                EnhancedEmptyStateView(
                    title: "No suppliers found",
                    message: "We couldn't find any suppliers matching your search.",
                    systemImage: "magnifyingglass"
                )
            }
        }
    }
    
    private var suppliersList: some View {
        List {
            ForEach(viewModel.filteredSuppliers, id: \.self) { supplier in
                SupplierRowItem(supplier: supplier, viewModel: viewModel)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Helper Methods
    
    private func setupNotifications() {
        // Set up notification observer when view appears
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("ShowAddSupplier"),
            object: nil,
            queue: .main
        ) { _ in
            self.showAddSupplier = true
        }
    }
    
    private func cleanupNotifications() {
        // Clean up notification observer when view disappears
        NotificationCenter.default.removeObserver(
            self,
            name: NSNotification.Name("ShowAddSupplier"),
            object: nil
        )
    }
}

// MARK: - Supplier Row Item
struct SupplierRowItem: View {
    let supplier: Supplier
    let viewModel: SupplierViewModel
    
    var body: some View {
        NavigationLink {
            SupplierDetailView(supplier: supplier)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(supplier.name ?? "")
                        .font(.headline)
                    
                    if let contactPerson = supplier.contactPerson, !contactPerson.isEmpty {
                        Text(contactPerson)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let email = supplier.email, !email.isEmpty {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Remove explicit chevron (NavigationLink adds its own)
            }
            .contentShape(Rectangle())  // Makes the entire row tappable
            .padding(.vertical, 8)      // Add some padding for better tap area
        }
        .id(supplier.objectID.uriRepresentation().absoluteString) // Ensure stable ID for navigation
        .buttonStyle(PlainButtonStyle())  // Ensures consistent tap behavior
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteSupplier(supplier)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct SupplierListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SupplierListView()
                .environment(\.managedObjectContext, CoreDataManager.previewContext)
                .environment(\.locale, .init(identifier: "en"))
        }
        
        NavigationView {
            SupplierListView()
                .environment(\.managedObjectContext, CoreDataManager.previewContext)
                .environment(\.locale, .init(identifier: "pt"))
        }
        .previewDisplayName("Portuguese")
    }
}
