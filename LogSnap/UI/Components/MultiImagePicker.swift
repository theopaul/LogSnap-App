import SwiftUI
import Photos
import PhotosUI
import Combine

// Import our local components
// This ensures ModernImagePicker is available
// The SwiftUI compiler will find these files implicitly, but it's good practice to import them explicitly

struct MultiImagePicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showActionSheet = false
    @State private var maxImages: Int
    @State private var isProcessingImages = false
    
    init(selectedImages: Binding<[UIImage]>, maxImages: Int = 9) {
        self._selectedImages = selectedImages
        self._maxImages = State(initialValue: maxImages)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .foregroundColor(.accentColor)
                
                Text("Images")
                    .font(.headline)
                
                Spacer()
                
                if isProcessingImages {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 8)
                }
                
                Text("\(selectedImages.count)/\(maxImages)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if selectedImages.count < maxImages {
                        Button(action: {
                            showActionSheet = true
                        }) {
                            VStack {
                                Image(systemName: "plus.viewfinder")
                                    .font(.system(size: 24))
                                    .foregroundColor(.accentColor)
                                
                                Text("Add Images")
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color(uiColor: .systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    ForEach(selectedImages.indices, id: \.self) { index in
                        imageThumbNail(for: index)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
        .confirmationDialog("Select Image Source", isPresented: $showActionSheet, titleVisibility: .visible) {
            Button("Photo Library") {
                showImagePicker = true
            }
            
            Button("Camera") {
                showCamera = true
            }
            
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose where to select your images from")
        }
        .sheet(isPresented: $showImagePicker) {
            PHImagePicker(selectedImages: $selectedImages, maxSelections: maxImages - selectedImages.count, isProcessing: $isProcessingImages)
        }
        .sheet(isPresented: $showCamera) {
            // Use ModernImagePicker for camera if iOS 14+
            if #available(iOS 14.0, *) {
                ModernImagePicker(onImageSelected: { newImage in
                    if selectedImages.count < maxImages {
                        isProcessingImages = true
                        DispatchQueue.global(qos: .userInitiated).async {
                            let processedImage = processImage(newImage)
                            
                            DispatchQueue.main.async {
                                if selectedImages.count < maxImages {
                                    selectedImages.append(processedImage)
                                }
                                isProcessingImages = false
                            }
                        }
                    } else {
                        isProcessingImages = false
                    }
                })
            } else {
                // Fall back to SimpleImagePicker for older iOS versions
                SimpleImagePicker(sourceType: .camera, onImageSelected: { newImage in
                    if selectedImages.count < maxImages {
                        isProcessingImages = true
                        DispatchQueue.global(qos: .userInitiated).async {
                            let processedImage = processImage(newImage)
                            
                            DispatchQueue.main.async {
                                if selectedImages.count < maxImages {
                                    selectedImages.append(processedImage)
                                }
                                isProcessingImages = false
                            }
                        }
                    } else {
                        isProcessingImages = false
                    }
                })
            }
        }
    }
    
    private func imageThumbNail(for index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: selectedImages[index])
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .cornerRadius(10)
                .clipped()
            
            Button(action: {
                withAnimation {
                    if index < selectedImages.count {
                        selectedImages.remove(at: index)
                    }
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .clipShape(Circle())
                    .frame(width: 30, height: 30)
            }
            .padding(4)
            .contentShape(Circle())
            .accessibilityLabel("Remove image")
        }
    }
    
    private func processImage(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1200
        
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        if originalWidth > maxDimension || originalHeight > maxDimension {
            let widthRatio = maxDimension / originalWidth
            let heightRatio = maxDimension / originalHeight
            let scaleFactor = min(widthRatio, heightRatio)
            
            let newWidth = originalWidth * scaleFactor
            let newHeight = originalHeight * scaleFactor
            
            let newSize = CGSize(width: newWidth, height: newHeight)
            
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { ctx in
                ctx.cgContext.interpolationQuality = .high
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            return resizedImage
        }
        
        return image
    }
}

struct PHImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    var maxSelections: Int
    @Binding var isProcessing: Bool
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        
        // Use the newer PHPickerConfiguration initializer without parameters if iOS 15+
        if #available(iOS 15.0, *) {
            configuration = PHPickerConfiguration(photoLibrary: .shared())
            // Enable selection order tracking in iOS 15+
            configuration.selection = .ordered
        }
        
        // Configure the picker
        configuration.selectionLimit = maxSelections
        configuration.filter = .images
        
        // Enable live photos if iOS 15+
        if #available(iOS 15, *) {
            configuration.preferredAssetRepresentationMode = .current
        }
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PHImagePicker
        
        init(_ parent: PHImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Always dismiss the picker first to improve UX
            picker.dismiss(animated: true)
            
            guard !results.isEmpty else { return }
            
            DispatchQueue.main.async {
                self.parent.isProcessing = true
            }
            
            // Use task groups for concurrent image loading with iOS 15+
            if #available(iOS 15.0, *) {
                Task {
                    var processedImages: [UIImage] = []
                    
                    await withTaskGroup(of: UIImage?.self) { group in
                        for result in results {
                            group.addTask {
                                await self.loadImage(from: result)
                            }
                        }
                        
                        for await image in group {
                            if let image = image {
                                processedImages.append(image)
                            }
                        }
                    }
                    
                    // Process the results on the main thread
                    await MainActor.run {
                        let dedupedImages = self.deduplicateImages(images: processedImages)
                        let remainingSlots = self.parent.maxSelections
                        let imagesToAdd = Array(dedupedImages.prefix(remainingSlots))
                        
                        if !imagesToAdd.isEmpty {
                            self.parent.selectedImages.append(contentsOf: imagesToAdd)
                        }
                        
                        self.parent.isProcessing = false
                    }
                }
            } else {
                // Fallback for iOS 14 using DispatchGroup
                let group = DispatchGroup()
                var processedImages: [UIImage] = []
                
                for result in results {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] reading, error in
                        defer { group.leave() }
                        
                        if let error = error {
                            print("ERROR: Failed to load image: \(error.localizedDescription)")
                            return
                        }
                        
                        if let image = reading as? UIImage {
                            let processed = self?.processImage(image) ?? image
                            processedImages.append(processed)
                        }
                    }
                }
                
                group.notify(queue: .main) { [weak self] in
                    guard let self = self else { return }
                    
                    let dedupedImages = self.deduplicateImages(images: processedImages)
                    let remainingSlots = self.parent.maxSelections
                    let imagesToAdd = Array(dedupedImages.prefix(remainingSlots))
                    
                    if !imagesToAdd.isEmpty {
                        self.parent.selectedImages.append(contentsOf: imagesToAdd)
                    }
                    
                    self.parent.isProcessing = false
                }
            }
        }
        
        // iOS 15+ async image loading
        @available(iOS 15.0, *)
        private func loadImage(from result: PHPickerResult) async -> UIImage? {
            // Check if we can get a UIImage directly
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                do {
                    // Use a continuation to wrap the completion handler
                    return try await withCheckedThrowingContinuation { continuation in
                        result.itemProvider.loadObject(ofClass: UIImage.self) { reading, error in
                            if let error = error {
                                continuation.resume(throwing: error)
                                return
                            }
                            
                            if let image = reading as? UIImage {
                                let processed = self.processImage(image)
                                continuation.resume(returning: processed)
                            } else {
                                continuation.resume(returning: nil)
                            }
                        }
                    }
                } catch {
                    print("ERROR: Failed to load image: \(error.localizedDescription)")
                    return nil
                }
            }
            return nil
        }
        
        private func deduplicateImages(images: [UIImage]) -> [UIImage] {
            let existingHashes = Set(parent.selectedImages.map { self.hashForImage($0) })
            
            return images.filter { !existingHashes.contains(self.hashForImage($0)) }
        }
        
        private func hashForImage(_ image: UIImage) -> Int {
            // Use modern APIs for thumbnail generation if available
            if #available(iOS 15.0, *) {
                let size = CGSize(width: 32, height: 32)
                
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1.0
                
                let renderer = UIGraphicsImageRenderer(size: size, format: format)
                
                let thumbnailData = renderer.jpegData(withCompressionQuality: 0.3) { ctx in
                    image.draw(in: CGRect(origin: .zero, size: size))
                }
                
                return thumbnailData.hashValue
            } else {
                // Fallback to older method for iOS 14
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
                let downsizedImage = renderer.image { context in
                    image.draw(in: CGRect(origin: .zero, size: CGSize(width: 32, height: 32)))
                }
                return downsizedImage.pngData()?.hashValue ?? image.hashValue
            }
        }
        
        private func processImage(_ image: UIImage) -> UIImage {
            let maxDimension: CGFloat = 1200
            
            let originalWidth = image.size.width
            let originalHeight = image.size.height
            
            if originalWidth > maxDimension || originalHeight > maxDimension {
                let widthRatio = maxDimension / originalWidth
                let heightRatio = maxDimension / originalHeight
                let scaleFactor = min(widthRatio, heightRatio)
                
                let newWidth = originalWidth * scaleFactor
                let newHeight = originalHeight * scaleFactor
                
                let newSize = CGSize(width: newWidth, height: newHeight)
                
                let renderer = UIGraphicsImageRenderer(size: newSize)
                return renderer.image { ctx in
                    ctx.cgContext.interpolationQuality = .high
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                }
            }
            
            return image
        }
    }
}
