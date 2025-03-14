import SwiftUI

public struct EnhancedImageCarouselView: View {
    // MARK: - Properties
    let images: [UIImage]
    let onDelete: ((Int) -> Void)?
    @State private var currentPage: Int = 0
    @State private var showFullScreen: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var imageScale: CGFloat = 1.0
    @State private var dragEnabled: Bool = true
    
    // MARK: - Initializers
    public init(
        images: [UIImage],
        onDelete: ((Int) -> Void)? = nil
    ) {
        self.images = images
        self.onDelete = onDelete
    }
    
    // MARK: - Body
    public var body: some View {
        VStack {
            if images.isEmpty {
                emptyStateView
            } else {
                ZStack(alignment: .bottom) {
                    PageViewController(
                        pages: images.map { ImageView(image: $0, dragEnabled: $dragEnabled) },
                        currentPage: $currentPage,
                        dragOffset: $dragOffset
                    )
                    .aspectRatio(1.0, contentMode: .fit)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .onChange(of: imageScale) { oldValue, newValue in
                        // Safer way to update dragEnabled - on next event cycle
                        DispatchQueue.main.async {
                            dragEnabled = newValue <= 1.1
                        }
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showFullScreen = true
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .clipShape(Circle())
                            }
                            .padding([.top, .trailing], 12)
                            
                            if let onDelete = onDelete {
                                Button(action: {
                                    onDelete(currentPage)
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .semibold))
                                        .padding(8)
                                        .background(Color.red.opacity(0.8))
                                        .foregroundColor(.white)
                                        .clipShape(Circle())
                                }
                                .padding([.top, .trailing], 12)
                            }
                        }
                        
                        Spacer()
                        
                        pageIndicator
                    }
                }
                .fullScreenCover(isPresented: $showFullScreen) {
                    ZoomableImageView(
                        image: images[currentPage],
                        onDismiss: { showFullScreen = false }
                    )
                }
            }
        }
    }
    
    // MARK: - Supporting Views
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No images available")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<images.count, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentColor : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentPage ? 1.2 : 1.0)
                    .animation(.spring(), value: currentPage)
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.5))
        .cornerRadius(20)
        .padding(.bottom, 12)
    }
}

// MARK: - Supporting Views
struct ImageView: View {
    let image: UIImage
    @Binding var dragEnabled: Bool
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geo in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = value
                            scale = min(max(newScale, 1.0), 3.0)
                            if scale > 1.1 {
                                dragEnabled = false
                            }
                        }
                        .onEnded { _ in
                            withAnimation {
                                scale = 1.0
                                dragEnabled = true
                            }
                        }
                )
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

struct ZoomableImageView: View {
    let image: UIImage
    let onDismiss: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { value in
                                withAnimation {
                                    lastOffset = offset
                                }
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(lastScale * value, 1.0), 5.0)
                            }
                            .onEnded { value in
                                withAnimation {
                                    lastScale = scale
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2.0
                                        lastScale = 2.0
                                    }
                                }
                            }
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding([.top, .leading], 20)
                    
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

// MARK: - UIViewControllerRepresentable for PageViewController
struct PageViewController: UIViewControllerRepresentable {
    let pages: [ImageView]
    @Binding var currentPage: Int
    @Binding var dragOffset: CGFloat
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        if let firstVC = makeChildViewController(for: 0) {
            pageViewController.setViewControllers([firstVC], direction: .forward, animated: true)
        }
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        if let currentVC = pageViewController.viewControllers?.first,
           let index = context.coordinator.controllers.firstIndex(of: currentVC),
           index != currentPage {
            
            let direction: UIPageViewController.NavigationDirection = index < currentPage ? .forward : .reverse
            if let newVC = makeChildViewController(for: currentPage) {
                pageViewController.setViewControllers([newVC], direction: direction, animated: true)
            }
        }
    }
    
    private func makeChildViewController(for index: Int) -> UIHostingController<ImageView>? {
        guard index >= 0 && index < pages.count else { return nil }
        let controller = UIHostingController(rootView: pages[index])
        controller.view.backgroundColor = .clear
        return controller
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        let parent: PageViewController
        var controllers: [UIViewController] = []
        
        init(_ pageViewController: PageViewController) {
            parent = pageViewController
            controllers = parent.pages.map { UIHostingController(rootView: $0) }
            super.init()
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index == 0 { return nil }
            return controllers[index - 1]
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index + 1 == controllers.count { return nil }
            return controllers[index + 1]
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleViewController) {
                parent.currentPage = index
            }
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
            parent.dragOffset = 1.0 // Any non-zero value to indicate dragging
        }
    }
}

// MARK: - Previews
struct EnhancedImageCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnhancedImageCarouselView(
                images: [
                    UIImage(systemName: "photo")!,
                    UIImage(systemName: "photo.fill")!
                ],
                onDelete: { index in
                    print("Delete image at index: \(index)")
                }
            )
            .frame(height: 300)
            .padding()
            
            EnhancedImageCarouselView(images: [])
                .frame(height: 300)
                .padding()
        }
    }
} 