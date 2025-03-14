import SwiftUI

public struct DestinationButton<Destination: View>: View {
    // MARK: - Properties
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let destination: Destination
    
    // MARK: - Initializers
    public init(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        @ViewBuilder destination: () -> Destination
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.destination = destination()
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews
struct DestinationButton_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                DestinationButton(
                    icon: "shippingbox",
                    title: "View Products",
                    subtitle: "48 products available"
                ) {
                    Text("Products View")
                        .navigationTitle("Products")
                }
                
                DestinationButton(
                    icon: "person.2",
                    title: "View Suppliers"
                ) {
                    Text("Suppliers View")
                        .navigationTitle("Suppliers")
                }
                
                DestinationButton(
                    icon: "gear",
                    title: "Settings",
                    subtitle: "Configure app preferences"
                ) {
                    Text("Settings View")
                        .navigationTitle("Settings")
                }
            }
            .navigationTitle("Dashboard")
        }
        
        NavigationView {
            List {
                DestinationButton(
                    icon: "shippingbox",
                    title: "Ver Produtos",
                    subtitle: "48 produtos disponíveis"
                ) {
                    Text("Visualização de Produtos")
                        .navigationTitle("Produtos")
                }
            }
            .navigationTitle("Painel")
        }
        .environment(\.locale, .init(identifier: "pt"))
        .previewDisplayName("Portuguese")
    }
} 