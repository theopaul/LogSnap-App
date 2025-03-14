import SwiftUI

public struct EnhancedEmptyStateView: View {
    // MARK: - Properties
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?
    
    // MARK: - Initializers
    public init(
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        systemImage: String,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 70))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.bottom, 10)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Previews
struct EnhancedEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EnhancedEmptyStateView(
                title: "No Products",
                message: "You haven't added any products yet. Add your first product to get started!",
                systemImage: "cube.box",
                actionTitle: "Add Product",
                action: {}
            )
            .previewDisplayName("With Action")
            
            EnhancedEmptyStateView(
                title: "No Search Results",
                message: "We couldn't find any matches for your search. Try a different search term.",
                systemImage: "magnifyingglass"
            )
            .previewDisplayName("Without Action")
            
            EnhancedEmptyStateView(
                title: "Sem Produtos",
                message: "Você ainda não adicionou nenhum produto. Adicione seu primeiro produto para começar!",
                systemImage: "cube.box",
                actionTitle: "Adicionar Produto",
                action: {}
            )
            .environment(\.locale, .init(identifier: "pt"))
            .previewDisplayName("Portuguese")
        }
    }
} 