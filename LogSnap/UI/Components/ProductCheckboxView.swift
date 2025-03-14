import SwiftUI

public struct ProductCheckboxView: View {
    // MARK: - Properties
    @Binding var isChecked: Bool
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let icon: String
    
    // MARK: - Initializers
    public init(
        isChecked: Binding<Bool>,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        icon: String
    ) {
        self._isChecked = isChecked
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    // MARK: - Body
    public var body: some View {
        Button(action: {
            isChecked.toggle()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isChecked ? .white : .primary.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(isChecked ? Color.accentColor : Color.primary.opacity(0.05))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isChecked ? .accentColor : .secondary)
                    .font(.system(size: 24))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isChecked ? Color.accentColor : Color.primary.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
struct ProductCheckboxView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ProductCheckboxView(
                isChecked: .constant(true),
                title: "In Stock",
                subtitle: "Product is currently available",
                icon: "cube.box.fill"
            )
            
            ProductCheckboxView(
                isChecked: .constant(false),
                title: "Featured Product",
                icon: "star.fill"
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 