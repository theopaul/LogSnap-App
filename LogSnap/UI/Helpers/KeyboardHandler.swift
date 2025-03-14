import SwiftUI
import Combine

class KeyboardInfo: ObservableObject {
    @Published var height: CGFloat = 0
    @Published var isVisible: Bool = false
    
    private var cancellable: AnyCancellable?
    
    init() {
        let notificationCenter = NotificationCenter.default
        
        cancellable = Publishers.Merge(
            notificationCenter.publisher(for: UIResponder.keyboardWillShowNotification)
                .map { notification -> CGFloat in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        return keyboardFrame.height
                    }
                    return 0
                },
            notificationCenter.publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ -> CGFloat in 0 }
        )
        .sink { [weak self] height in
            guard let self = self else { return }
            self.height = height
            self.isVisible = height > 0
        }
    }
}

struct KeyboardAwareScrollView<Content: View>: View {
    @StateObject private var keyboard = KeyboardInfo()
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    
    var showsIndicators: Bool
    var content: Content
    
    init(showsIndicators: Bool = true, @ViewBuilder content: () -> Content) {
        self.showsIndicators = showsIndicators
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: showsIndicators) {
                content
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear.preference(
                                key: ContentHeightPreferenceKey.self, 
                                value: contentGeometry.size.height
                            )
                        }
                    )
                    .padding(.bottom, max(0, keyboard.height - (scrollViewHeight - contentHeight)))
            }
            .onPreferenceChange(ContentHeightPreferenceKey.self) { contentHeight in
                self.contentHeight = contentHeight
            }
            .background(
                GeometryReader { scrollViewGeometry in
                    Color.clear.preference(
                        key: ScrollViewHeightPreferenceKey.self, 
                        value: scrollViewGeometry.size.height
                    )
                }
            )
            .onPreferenceChange(ScrollViewHeightPreferenceKey.self) { scrollViewHeight in
                self.scrollViewHeight = scrollViewHeight
            }
        }
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ScrollViewHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// Extensão para esconder o teclado
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func onTapToDismissKeyboard() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
    
    func dismissKeyboardOnDrag() -> some View {
        self.gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { _ in
                    hideKeyboard()
                }
        )
    }
} 