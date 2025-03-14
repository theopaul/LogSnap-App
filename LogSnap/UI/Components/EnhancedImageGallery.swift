import SwiftUI

public struct EnhancedImageGallery: View {
    // MARK: - Properties
    let images: [UIImage]
    let onTap: ((UIImage, Int) -> Void)?
    let maxHeight: CGFloat
    
    // MARK: - Initializers
    public init(
        images: [UIImage],
        maxHeight: CGFloat = 120,
        onTap: ((UIImage, Int) -> Void)? = nil
    ) {
        self.images = images
        self.maxHeight = maxHeight
        self.onTap = onTap
    }
    
    // MARK: - Body
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if images.isEmpty {
                emptyStateView
            } else {
                LazyHStack(spacing: 12) {
                    ForEach(0..<images.count, id: \.self) { index in
                        imageView(for: images[index], at: index)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .frame(height: maxHeight)
    }
    
    // MARK: - Supporting Views
    private func imageView(for image: UIImage, at index: Int) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: maxHeight - 20, height: maxHeight - 20)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            .onTapGesture {
                onTap?(image, index)
            }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(.secondary)
            
            Text(LocalizedStringKey("No images"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews
struct EnhancedImageGallery_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Product Gallery")
                .font(.headline)
                .padding(.leading, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            EnhancedImageGallery(
                images: [
                    UIImage(systemName: "photo")!,
                    UIImage(systemName: "photo.fill")!,
                    UIImage(systemName: "photo")!,
                    UIImage(systemName: "photo.fill")!
                ],
                onTap: { image, index in
                    print("Tapped image at index: \(index)")
                }
            )
            
            Text("Empty Gallery")
                .font(.headline)
                .padding(.leading, 16)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            EnhancedImageGallery(images: [])
        }
        .padding(.vertical)
        .previewLayout(.sizeThatFits)
    }
} 