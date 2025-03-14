import SwiftUI
import CoreData
import UIKit

struct AddProductView: View {
    @ObservedObject var viewModel: ProductViewModel
    @Binding var isPresented: Bool
    @State private var showUnsavedChangesAlert = false
    @State private var showDeleteImageConfirmation = false
    @State private var showSupplierSelector = false
    @State private var showNewSupplier = false
    @State private var imageToDeleteIndex: Int?
    @State private var suppliers: [Supplier] = []
    @State private var notes: String = ""
    
    var editingProduct: Product?
    
    private var isEditing: Bool {
        return editingProduct != nil
    }
    
    var selectedSupplier: Supplier? {
        if !viewModel.selectedSupplierID.isEmpty {
            return suppliers.first(where: { supplier in
                let supplierIDString = supplier.objectID.uriRepresentation().absoluteString
                return supplierIDString == viewModel.selectedSupplierID
            })
        }
        return nil
    }
    
    var supplierName: String {
        selectedSupplier?.name ?? NSLocalizedString("Select Supplier", comment: "")
    }
    
    var body: some View {
        KeyboardAwareScrollView {
            VStack(spacing: 20) {
                // Product Images - Using the new MultiImagePicker
                MultiImagePicker(selectedImages: $viewModel.productImages)
                    .padding(.horizontal)
                
                // First: Supplier Section
                supplierSection
                
                // Updated order: Product name first
                basicInfoSection
                
                // Then pricing section
                pricingSection
                
                // Dimensions & Materials
                specificationsSection
                
                // Packing and Logistics
                packingLogisticsSection
                
                // Notes Section
                notesSection
                
                // Add button at the bottom
                addProductButton
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .dismissKeyboardOnDrag()
        .onTapToDismissKeyboard()
        .navigationTitle(isEditing ? LocalizedStringKey("Edit Product") : LocalizedStringKey("New Product"))
        .navigationBarItems(
            leading: cancelButton,
            trailing: saveButton
        )
        .alert(isPresented: $showUnsavedChangesAlert) {
            unsavedChangesAlert
        }
        .sheet(isPresented: $showSupplierSelector) {
            // Refresh data when supplier selector is dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                fetchSuppliers()
            }
        } content: {
            NavigationView {
                SupplierSelectorView(suppliers: suppliers, selectedSupplier: $viewModel.selectedSupplierID, isPresented: $showSupplierSelector)
            }
        }
        .sheet(isPresented: $showNewSupplier) {
            // Refresh suppliers when add supplier view is dismissed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                fetchSuppliers()
            }
        } content: {
            NavigationView {
                AddSupplierView(
                    viewModel: SupplierViewModel()
                )
                .environment(\.managedObjectContext, getContext())
            }
        }
        .onAppear {
            fetchSuppliers()
            
            // Set notes from product if in edit mode
            if let product = editingProduct {
                notes = product.notes ?? ""
                
                // Make sure the viewModel loads all additional details
                viewModel.loadProductForEditing(product)
            }
        }
    }
    
    // MARK: - UI Components
    
    private var supplierSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Supplier"))
                    .font(.headline)
            }
            
            VStack(spacing: 10) {
                Button(action: {
                    showSupplierSelector = true
                }) {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.accentColor)
                            .frame(width: 24)
                        
                        if let supplier = selectedSupplier {
                            VStack(alignment: .leading) {
                                Text(supplier.name ?? "")
                                    .foregroundColor(.primary)
                                
                                if let contact = supplier.contactPerson, !contact.isEmpty {
                                    Text(contact)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("Select a Supplier")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    showNewSupplier = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                        Text("Create New Supplier")
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Basic Information"))
                    .font(.headline)
            }
            
            FormField(
                text: $viewModel.name,
                placeholder: "Product Name",
                icon: "shippingbox",
                validation: { text in
                    return (!text.trimmed().isEmpty, text.trimmed().isEmpty ? "Name is required" : nil)
                }
            )
            
            FormField(
                text: $viewModel.sku,
                placeholder: "SKU",
                icon: "tag",
                capitalization: .words,
                validation: { text in
                    return (true, nil)
                }
            )
            
            FormField(
                text: $viewModel.category,
                placeholder: "Category",
                icon: "folder"
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Pricing"))
                    .font(.headline)
            }
            
            // Price field with currency next to it
            HStack(spacing: 8) {
                // Price field
                FormField(
                    text: $viewModel.price,
                    placeholder: "Price",
                    icon: "dollarsign.circle",
                    keyboardType: .decimalPad
                )
                .frame(maxWidth: .infinity)
                
                // Currency dropdown - fixed width and improved styling
                Menu {
                    ForEach(viewModel.availableCurrencies, id: \.self) { currency in
                        Button(action: {
                            viewModel.currency = currency
                        }) {
                            HStack {
                                Text(currency)
                                if viewModel.currency == currency {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.currency)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                    }
                    .frame(width: 70)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))
                    .foregroundColor(.accentColor)
                    .cornerRadius(10)
                }
            }
            
            // MOQ and Incoterm in same row
            HStack(spacing: 8) {
                // MOQ field
                FormField(
                    text: $viewModel.moq,
                    placeholder: "MOQ",
                    icon: "number",
                    keyboardType: .numberPad
                )
                .frame(maxWidth: .infinity)
                
                // Incoterm dropdown
                Menu {
                    ForEach(viewModel.availableIncoterms, id: \.self) { incoterm in
                        Button(action: {
                            viewModel.incotermValue = incoterm
                        }) {
                            HStack {
                                Text(incoterm)
                                if viewModel.incotermValue == incoterm {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.incotermValue)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14))
                    }
                    .frame(width: 70)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))
                    .foregroundColor(.accentColor)
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "ruler.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Specifications"))
                    .font(.headline)
            }
            
            // Separate dimensions fields
            HStack {
                // Width
                VStack(alignment: .leading) {
                    Text("Width")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("W", text: $viewModel.width)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
                
                Text("×")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Height
                VStack(alignment: .leading) {
                    Text("Height")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("H", text: $viewModel.height)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
                
                Text("×")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Depth
                VStack(alignment: .leading) {
                    Text("Depth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("D", text: $viewModel.depth)
                        .keyboardType(.decimalPad)
                        .padding(10)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
            }
            
            FormField(
                text: $viewModel.weight,
                placeholder: "Weight (kg)",
                icon: "scalemass",
                keyboardType: .decimalPad
            )
            
            FormField(
                text: $viewModel.materials,
                placeholder: "Materials",
                icon: "square.stack.3d.up"
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var packingLogisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "box.truck.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Packing & Logistics"))
                    .font(.headline)
            }
            
            FormField(
                text: $viewModel.packingTypeValue,
                placeholder: "Packing Type",
                icon: "shippingbox"
            )
            
            FormField(
                text: $viewModel.quantityPerBoxValue,
                placeholder: "Quantity per Box",
                icon: "number",
                keyboardType: .numberPad
            )
            
            FormField(
                text: $viewModel.productionTimeValue,
                placeholder: "Production Time (days)",
                icon: "clock",
                keyboardType: .numberPad
            )
            
            FormField(
                text: $viewModel.portOfDepartureValue,
                placeholder: "Port of Departure",
                icon: "ferry"
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // New Notes Section
    private var notesSection: some View {
        Section(header: Text("Notes")) {
            HStack(alignment: .top) {
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    // Add Product Button at the bottom
    private var addProductButton: some View {
        Button(action: {
            // Ensure we're not in the middle of a view update cycle
            DispatchQueue.main.async {
                save()
            }
        }) {
            HStack {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text(isEditing ? "Update Product" : "Add Product")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(viewModel.name.trimmed().isEmpty ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        // Make sure tap target is at least 44x44 points per Apple guidelines
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .disabled(viewModel.name.trimmed().isEmpty)
    }
    
    private var cancelButton: some View {
        Button(LocalizedStringKey("Cancel")) {
            // Move state changes out of view update cycle
            DispatchQueue.main.async {
                if hasUnsavedChanges() {
                    showUnsavedChangesAlert = true
                } else {
                    isPresented = false
                }
            }
        }
        // Ensure minimum 44x44 hit target per Apple's guidelines
        .frame(minWidth: 44, minHeight: 44)
    }
    
    private var saveButton: some View {
        Button(action: {
            // Ensure save isn't called during view update cycle
            DispatchQueue.main.async {
                save()
            }
        }) {
            Text(LocalizedStringKey("Save"))
        }
        // Only name is required, SKU is now optional
        .disabled(viewModel.name.trimmed().isEmpty)
        .foregroundColor(viewModel.name.trimmed().isEmpty ? .gray : .accentColor)
        // Ensure minimum 44x44 hit target per Apple's guidelines
        .frame(minWidth: 44, minHeight: 44)
    }
    
    private var unsavedChangesAlert: Alert {
        Alert(
            title: Text(LocalizedStringKey("Unsaved Changes")),
            message: Text(LocalizedStringKey("Do you want to save your changes?")),
            primaryButton: .default(Text(LocalizedStringKey("Save"))) {
                save()
            },
            secondaryButton: .destructive(Text(LocalizedStringKey("Discard"))) {
                isPresented = false
            }
        )
    }
    
    // MARK: - Helper Functions
    private func save() {
        print("Save function called")
        
        // Esconder o teclado antes de tentar salvar
        hideKeyboard()
        
        // Add notes to viewModel for saving
        viewModel.notes = notes
        
        // Ensure the form is valid before saving
        guard viewModel.validateForm() else {
            print("Form validation failed")
            // Add visual feedback for validation failure
            #if DEBUG
            print("Validation errors: Name empty? \(viewModel.name.trimmed().isEmpty)")
            #endif
            return
        }
        
        // Use a flag to track save operation
        var success = false
        
        if let product = editingProduct {
            print("Updating existing product")
            success = viewModel.updateProduct(product)
        } else {
            print("Creating new product")
            success = viewModel.saveProduct()
        }
        
        if success {
            print("Save operation successful, dismissing view")
            // Adicione um pequeno delay antes de fechar para garantir que a operação foi concluída
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPresented = false
            }
        } else {
            print("Save operation failed")
            // Could add error feedback here if save fails
        }
    }
    
    private func fetchSuppliers() {
        let context = getContext()
        let request: NSFetchRequest<Supplier> = Supplier.fetchRequest()
        
        do {
            suppliers = try context.fetch(request)
        } catch {
            print("Error fetching suppliers: \(error)")
        }
    }
    
    // Helper method to get the managed object context
    private func getContext() -> NSManagedObjectContext {
        let cdManager: CoreDataManager = {
            let instance = CoreDataManager.shared
            return instance
        }()
        return cdManager.container.viewContext
    }
    
    // Check for unsaved changes
    private func hasUnsavedChanges() -> Bool {
        // Basic info changes
        let hasBasicChanges = !viewModel.name.isEmpty ||
                             !viewModel.sku.isEmpty ||
                             !viewModel.category.isEmpty
        
        // Pricing changes
        let hasPricingChanges = !viewModel.price.isEmpty ||
                               viewModel.currency != "USD" ||
                               viewModel.incotermValue != "FOB"
        
        // Specifications changes
        let hasSpecChanges = !viewModel.width.isEmpty ||
                            !viewModel.height.isEmpty ||
                            !viewModel.depth.isEmpty ||
                            !viewModel.weight.isEmpty ||
                            !viewModel.materials.isEmpty
        
        // Packing and logistics changes
        let hasPackingChanges = !viewModel.packingTypeValue.isEmpty ||
                                !viewModel.quantityPerBoxValue.isEmpty ||
                                !viewModel.productionTimeValue.isEmpty ||
                                !viewModel.portOfDepartureValue.isEmpty
        
        // Notes changes
        let hasNotesChanges = !notes.isEmpty
        
        // Supplier selection
        let hasSupplierChanges = !viewModel.selectedSupplierID.isEmpty
        
        // Image changes
        let hasImageChanges = !viewModel.productImages.isEmpty
        
        // First evaluate primary changes
        let primaryChanges = hasBasicChanges || hasPricingChanges
        
        // Then evaluate secondary changes
        let secondaryChanges = hasSpecChanges || hasPackingChanges
        
        // Then evaluate tertiary changes
        let tertiaryChanges = hasNotesChanges || hasSupplierChanges || hasImageChanges
        
        // Final combined evaluation
        return primaryChanges || secondaryChanges || tertiaryChanges
    }
    
    // Esconder o teclado
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Supplier selector view
struct SupplierSelectorView: View {
    let suppliers: [Supplier]
    @Binding var selectedSupplier: String
    @Binding var isPresented: Bool
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search suppliers...", text: $searchText)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 44) // Ensure minimum 44x44pt touch target
                            .contentShape(Circle()) // Make the entire circle tappable
                    }
                }
            }
            .padding(10)
            .background(Color(UIColor.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            List {
                if suppliers.isEmpty {
                    Text("No suppliers found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredSuppliers, id: \.self) { supplier in
                        Button(action: {
                            let supplierIDString = supplier.objectID.uriRepresentation().absoluteString
                            selectedSupplier = supplierIDString
                            isPresented = false
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(supplier.name ?? "")
                                    
                                    if let contact = supplier.contactPerson, !contact.isEmpty {
                                        Text(contact)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                let supplierIDString = supplier.objectID.uriRepresentation().absoluteString
                                if selectedSupplier == supplierIDString {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 8) // Ensure proper height
                            .contentShape(Rectangle()) // Make the entire row tappable
                        }
                        .buttonStyle(PlainButtonStyle()) // Ensure consistent tap behavior
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Select Supplier")
        .navigationBarItems(trailing: Button("Cancel") {
            isPresented = false
        })
    }
    
    private var filteredSuppliers: [Supplier] {
        if searchText.isEmpty {
            return suppliers
        } else {
            return suppliers.filter { supplier in
                let nameMatch = supplier.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let contactMatch = supplier.contactPerson?.localizedCaseInsensitiveContains(searchText) ?? false
                return nameMatch || contactMatch
            }
        }
    }
}

// MARK: - Preview Provider
struct AddProductView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a simplified preview with just one appearance mode
        NavigationView {
            AddProductView(
                viewModel: createPreviewViewModel(),
                isPresented: .constant(true)
            )
            .environment(\.managedObjectContext, ProductPreviewController.preview.container.viewContext)
        }
        .previewDisplayName("Product Form")
    }
    
    // Helper to create a consistently configured view model for previews
    static func createPreviewViewModel() -> ProductViewModel {
        // Create mock view model with minimal test data
        let viewModel = ProductViewModel()
        viewModel.name = "Sample Product"
        viewModel.sku = "SKU-12345"
        viewModel.price = "99.99"
        
        // Only add an image if system image is available (avoid memory pressure)
        if let sampleImage = UIImage(systemName: "cube.box") {
            viewModel.productImages = [sampleImage]
        }
        
        return viewModel
    }
}

// A helper for previews - renamed to avoid conflict with AddSupplierView
class ProductPreviewController {
    // A singleton for our entire app to use
    static let shared = ProductPreviewController()
    
    // Storage for Core Data
    let container: NSPersistentContainer
    
    // A lightweight test configuration for SwiftUI previews
    static var preview: ProductPreviewController = {
        let controller = ProductPreviewController(inMemory: true)
        
        // Minimal sample data - only what's needed for the preview
        let viewContext = controller.container.viewContext
        
        // Create a basic product
        let product = Product(context: viewContext)
        product.name = "Sample Product"
        product.sku = "SKU-12345"
        product.createdAt = Date()
        
        // Create a basic supplier
        let supplier = Supplier(context: viewContext)
        supplier.name = "Sample Supplier"
        
        do {
            try viewContext.save()
        } catch {
            // Just log the error in preview mode
            print("Preview CoreData error: \(error)")
        }
        
        return controller
    }()
    
    // Initialize with an optional in-memory store
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LogSnap")
        
        if inMemory {
            // Use /dev/null for in-memory store
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                // Just log the error in preview mode
                print("Persistent store error: \(error)")
            }
        }
        
        // Basic settings for preview
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
