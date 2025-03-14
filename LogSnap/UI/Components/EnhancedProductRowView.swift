import SwiftUI

public struct EnhancedProductRowView: View {
    // MARK: - Properties
    let productName: String
    let productSKU: String
    let productCategory: String?
    let productPrice: Double?
    let productCurrency: String?
    let productImage: UIImage?
    let onTap: (() -> Void)?
    let showChevron: Bool
    let insideNavigationLink: Bool
    
    // MARK: - Initializers
    public init(
        productName: String,
        productSKU: String,
        productCategory: String? = nil,
        productPrice: Double? = nil,
        productCurrency: String? = nil,
        productImage: UIImage? = nil,
        onTap: (() -> Void)? = nil,
        showChevron: Bool = false,
        insideNavigationLink: Bool = false
    ) {
        self.productName = productName
        self.productSKU = productSKU
        self.productCategory = productCategory
        self.productPrice = productPrice
        self.productCurrency = productCurrency
        self.productImage = productImage
        self.onTap = onTap
        self.showChevron = showChevron
        self.insideNavigationLink = insideNavigationLink
    }
    
    // MARK: - Body
    public var body: some View {
        Group {
            if insideNavigationLink {
                rowContent
            } else {
                Button(action: {
                    onTap?()
                }) {
                    rowContent
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Row Content
    private var rowContent: some View {
        HStack(spacing: 16) {
            productImageView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(productName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(productSKU)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    if let category = productCategory, !category.isEmpty {
                        categoryPill
                    }
                    
                    if let price = productPrice, let currency = productCurrency {
                        pricePill(price: price, currency: currency)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            if showChevron && !insideNavigationLink {
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.secondary.opacity(0.5))
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    // MARK: - Supporting Views
    private var productImageView: some View {
        Group {
            if let image = productImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    )
            }
        }
    }
    
    private var categoryPill: some View {
        Text(productCategory ?? "")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(Color.blue)
            .cornerRadius(12)
    }
    
    private func pricePill(price: Double, currency: String) -> some View {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        let formattedPrice = formatter.string(from: NSNumber(value: price)) ?? "\(currency) \(price)"
        
        return Text(formattedPrice)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.2))
            .foregroundColor(Color.green)
            .cornerRadius(12)
    }
}

// MARK: - Previews
struct EnhancedProductRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Full details
            EnhancedProductRowView(
                productName: "Wireless Headphones",
                productSKU: "WH-1000XM4",
                productCategory: "Electronics",
                productPrice: 349.99,
                productCurrency: "USD",
                productImage: UIImage(systemName: "headphones")
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Full Details")
            
            // Minimal details
            EnhancedProductRowView(
                productName: "Power Adapter",
                productSKU: "PA-20W",
                productImage: nil
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Minimal Details")
            
            // Portuguese locale
            EnhancedProductRowView(
                productName: "Fones de Ouvido",
                productSKU: "FO-2023",
                productCategory: "Eletrônicos",
                productPrice: 999.99,
                productCurrency: "BRL",
                productImage: UIImage(systemName: "headphones")
            )
            .padding()
            .previewLayout(.sizeThatFits)
            .environment(\.locale, .init(identifier: "pt"))
            .previewDisplayName("Portuguese")
        }
    }
} 