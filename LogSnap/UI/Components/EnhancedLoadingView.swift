import SwiftUI

public struct EnhancedLoadingView: View {
    // MARK: - Properties
    let message: LocalizedStringKey
    @State private var isAnimating: Bool = false
    
    // MARK: - Initializers
    public init(message: LocalizedStringKey = "Loading...") {
        self.message = message
    }
    
    // MARK: - Body
    public var body: some View {
        VStack(spacing: 20) {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.accentColor.opacity(0.3), Color.accentColor]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 50, height: 50)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .onAppear {
                    isAnimating = true
                }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(20)
    }
}

public struct FullScreenLoadingView: View {
    // MARK: - Properties
    let message: LocalizedStringKey
    let isLoading: Bool
    
    // MARK: - Initializers
    public init(
        isLoading: Bool,
        message: LocalizedStringKey = "Loading..."
    ) {
        self.isLoading = isLoading
        self.message = message
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                VStack {
                    EnhancedLoadingView(message: message)
                        .frame(width: 200, height: 150)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(UIColor.systemBackground))
                                .shadow(color: Color.black.opacity(0.2), radius: 10)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(), value: isLoading)
    }
}

// MARK: - Previews
struct EnhancedLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            EnhancedLoadingView()
                .frame(width: 200, height: 150)
            
            EnhancedLoadingView(message: "Uploading image...")
                .frame(width: 200, height: 150)
            
            ZStack {
                Text("Background Content")
                
                FullScreenLoadingView(isLoading: true)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 