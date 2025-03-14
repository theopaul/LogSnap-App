import SwiftUI
import CoreData

struct ProductDetailView: View {
    let product: Product
    @StateObject private var viewModel = ProductViewModel()
    @State private var showEditProduct = false
    @State private var showDeleteConfirmation = false
    @State private var showFullScreenImage = false
    @State private var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Product Images
                productImagesSection
                
                // Basic Info Section
                basicInfoSection
                
                // Price & MOQ Section
                pricingSection
                
                // Dimensions & Weight Section
                specificationsSection
                
                // Notes Section
                notesSection
                
                // Dates Section
                datesSection
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Product Details"))
        .navigationBarItems(trailing: navigationButtons)
        .actionSheet(isPresented: $showDeleteConfirmation) {
            deleteConfirmationSheet
        }
        .sheet(isPresented: $showEditProduct) {
            NavigationView {
                AddProductView(
                    viewModel: viewModel,
                    isPresented: $showEditProduct,
                    editingProduct: product
                )
            }
        }
        .onAppear {
            // Preload product info for potential editing
            viewModel.loadProductForEditing(product)
        }
    }
    
    // MARK: - UI Components
    
    private var productImagesSection: some View {
        let productImages = product.getImages()
        return Group {
            if !productImages.isEmpty {
                EnhancedImageCarouselView(images: productImages)
                    .frame(height: 300)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Basic Information"))
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text(product.name ?? "")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Label {
                        Text("SKU").foregroundColor(.secondary)
                        Text(product.sku ?? "")
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    if let category = product.category, !category.isEmpty {
                        Label {
                            Text("Category").foregroundColor(.secondary)
                            Text(category)
                                .fontWeight(.medium)
                        } icon: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.03))
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
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    if product.price > 0 {
                        VStack(alignment: .leading) {
                            Text("Price")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .firstTextBaseline) {
                                Text(formatCurrency(value: product.price, currency: product.currency ?? "USD"))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    if product.moq > 0 {
                        VStack(alignment: .trailing) {
                            Text("MOQ")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("\(product.moq)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.03))
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
            
            VStack(alignment: .leading, spacing: 16) {
                if let dimensions = product.dimensions, !dimensions.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Dimensions")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        HStack {
                            let components = product.getDimensionsComponents()
                            dimensionComponent(value: components.width, label: "W")
                            Text("×").foregroundColor(.secondary)
                            dimensionComponent(value: components.height, label: "H")
                            Text("×").foregroundColor(.secondary)
                            dimensionComponent(value: components.depth, label: "D")
                        }
                    }
                }
                
                if product.weight > 0 {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Weight")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 4)
                            
                            Text("\(String(format: "%.2f", product.weight)) kg")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                if let materials = product.materials, !materials.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Materials")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(materials)
                            .font(.body)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var notesSection: some View {
        Section(header: Text("Notes")) {
            if let notes = product.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentColor)
                        .frame(width: 24, height: 24)
                    
                    Text(notes)
                        .padding(.vertical, 4)
                }
                .padding(.vertical, 4)
            } else {
                Text("No notes available")
                    .foregroundColor(.gray)
                    .italic()
            }
        }
    }
    
    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Timestamps"))
                    .font(.headline)
            }
            
            VStack(spacing: 8) {
                if let createdAt = product.createdAt {
                    HStack {
                        Text("Created")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(createdAt.formattedDate())
                            .font(.subheadline)
                    }
                }
                
                if let updatedAt = product.updatedAt {
                    HStack {
                        Text("Updated")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(updatedAt.formattedDate())
                            .font(.subheadline)
                    }
                }
            }
            .padding(12)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var navigationButtons: some View {
        HStack {
            Button(action: {
                showEditProduct = true
            }) {
                Text(LocalizedStringKey("Edit"))
            }
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }
    
    private var deleteConfirmationSheet: ActionSheet {
        ActionSheet(
            title: Text(LocalizedStringKey("Delete Product")),
            message: Text(LocalizedStringKey("Are you sure you want to delete this product? This action cannot be undone.")),
            buttons: [
                .destructive(Text(LocalizedStringKey("Delete"))) {
                    viewModel.deleteProduct(product)
                    presentationMode.wrappedValue.dismiss()
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helper Views
    
    private func dimensionComponent(value: String, label: String) -> some View {
        VStack(alignment: .center) {
            Text(value)
                .font(.body)
                .fontWeight(.medium)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 40)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Helper Functions
    
    private func formatCurrency(value: Double, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency) \(value)"
    }
}

// MARK: - Preview Provider
struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a simplified preview with just one appearance mode
        NavigationView {
            ProductDetailView(product: createPreviewProduct())
                .environment(\.managedObjectContext, ProductPreviewController.preview.container.viewContext)
        }
        .previewDisplayName("Product Details")
    }
    
    // Helper to create a consistently configured product for previews
    static func createPreviewProduct() -> Product {
        let context = ProductPreviewController.preview.container.viewContext
        
        // Create a sample product with all fields populated
        let product = Product(context: context)
        product.name = "Premium Wooden Chair"
        product.sku = "WD-CH-001"
        product.category = "Furniture"
        product.price = 149.99
        product.currency = "USD"
        product.moq = 100
        product.dimensions = "60 × 80 × 95"
        product.weight = 5.5
        product.materials = "Solid oak wood with premium fabric upholstery"
        product.notes = "This premium wooden chair features a classic design with modern touches. Each piece is handcrafted by skilled artisans."
        product.createdAt = Date().addingTimeInterval(-3600 * 24 * 7) // 7 days ago
        product.updatedAt = Date()
        
        return product
    }
} 