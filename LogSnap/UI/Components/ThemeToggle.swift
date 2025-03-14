import SwiftUI

public struct ThemeToggle: View {
    // MARK: - Properties
    @Binding var isDarkMode: Bool
    @State private var isAnimating: Bool = false
    
    // MARK: - Initializers
    public init(isDarkMode: Binding<Bool>) {
        self._isDarkMode = isDarkMode
    }
    
    // MARK: - Body
    public var body: some View {
        HStack {
            Text(LocalizedStringKey("Dark Mode"))
                .font(.headline)
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(isDarkMode ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(isDarkMode ? Color.blue : Color.gray)
                    .frame(width: 26, height: 26)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                    .offset(x: isDarkMode ? 10 : -10)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                
                if isDarkMode {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .offset(x: 10)
                } else {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                        .offset(x: -10)
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isAnimating = true
                    isDarkMode.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring()) {
                        isAnimating = false
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

public struct LanguageToggle: View {
    // MARK: - Properties
    @AppStorage("appLanguage") var appLanguage: String = "en"
    
    // MARK: - Initializers
    public init() {}
    
    // MARK: - Body
    public var body: some View {
        HStack {
            Text(LocalizedStringKey("Language"))
                .font(.headline)
            
            Spacer()
            
            Picker("", selection: $appLanguage) {
                Text(LocalizedStringKey("English"))
                    .tag("en")
                
                Text(LocalizedStringKey("Portuguese"))
                    .tag("pt")
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Previews
struct ThemeToggle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                ThemeToggle(isDarkMode: .constant(false))
                    .padding()
                    .previewDisplayName("Light Mode")
                
                ThemeToggle(isDarkMode: .constant(true))
                    .padding()
                    .previewDisplayName("Dark Mode")
                
                LanguageToggle()
                    .padding()
            }
            .previewLayout(.sizeThatFits)
            
            VStack(spacing: 20) {
                ThemeToggle(isDarkMode: .constant(false))
                    .padding()
                    .previewDisplayName("Light Mode - Portuguese")
                
                ThemeToggle(isDarkMode: .constant(true))
                    .padding()
                    .previewDisplayName("Dark Mode - Portuguese")
                
                LanguageToggle()
                    .padding()
            }
            .environment(\.locale, .init(identifier: "pt"))
            .previewLayout(.sizeThatFits)
        }
    }
} 