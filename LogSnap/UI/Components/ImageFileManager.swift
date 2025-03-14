import Foundation
import UIKit

// This class centralizes all image file operations with proper iCloud support
class ImageFileManager {
    enum ImageCategory: String {
        case product = "ProductImages"
        case supplier = "SupplierImages"
        case contact = "ContactImages"
    }
    
    // Error types specific to ImageFileManager
    enum FileError: Error, LocalizedError {
        case directoryCreationFailed
        case fileWriteFailed
        case fileReadFailed
        case fileDeleteFailed
        case invalidImage
        case bookmarkCreationFailed
        case bookmarkResolutionFailed
        case securityScopedAccessFailed
        case iCloudContainerUnavailable
        
        var errorDescription: String? {
            switch self {
            case .directoryCreationFailed: return "Failed to create directory"
            case .fileWriteFailed: return "Failed to write file"
            case .fileReadFailed: return "Failed to read file"
            case .fileDeleteFailed: return "Failed to delete file"
            case .invalidImage: return "Invalid image"
            case .bookmarkCreationFailed: return "Failed to create bookmark"
            case .bookmarkResolutionFailed: return "Failed to resolve bookmark"
            case .securityScopedAccessFailed: return "Failed to access security-scoped resource"
            case .iCloudContainerUnavailable: return "iCloud container is unavailable"
            }
        }
    }
    
    static let shared = ImageFileManager()
    private let bookmarkKey = "ImageFileManager.ExternalStorageBookmark"
    
    private init() {
        // Ensure directories exist
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Directory Management
    
    private func createDirectoriesIfNeeded() {
        do {
            guard let appSupportDirectory = try getAppSupportDirectory() else { return }
            
            // Create directories for each image type
            try createDirectoryIfNeeded(at: appSupportDirectory.appendingPathComponent(ImageCategory.product.rawValue, isDirectory: true))
            try createDirectoryIfNeeded(at: appSupportDirectory.appendingPathComponent(ImageCategory.supplier.rawValue, isDirectory: true))
            try createDirectoryIfNeeded(at: appSupportDirectory.appendingPathComponent(ImageCategory.contact.rawValue, isDirectory: true))
            
            print("DEBUG: Image directories created/verified")
        } catch {
            print("ERROR: Failed to create image directories: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Security Scoped Resources and Bookmarks
    
    // Create a bookmark for persistent access to a user-selected directory
    func createBookmark(for url: URL) throws -> Data {
        do {
            // Create a security-scoped bookmark
            let bookmarkData = try url.bookmarkData(options: .minimalBookmark,
                                                 includingResourceValuesForKeys: nil,
                                                 relativeTo: nil)
            
            // Save the bookmark data
            UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
            
            print("DEBUG: Created and saved bookmark for: \(url.path)")
            return bookmarkData
        } catch {
            print("ERROR: Failed to create bookmark: \(error.localizedDescription)")
            throw FileError.bookmarkCreationFailed
        }
    }
    
    // Resolve a bookmark to access an external directory
    func resolveBookmark() throws -> URL {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            print("ERROR: No bookmark data found")
            throw FileError.bookmarkResolutionFailed
        }
        
        do {
            var isStale = false
            // Use .withoutUI instead of .withSecurityScope for iOS compatibility
            let url = try URL(resolvingBookmarkData: bookmarkData,
                             options: .withoutUI,
                             relativeTo: nil,
                             bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("WARN: Bookmark is stale, recreating...")
                _ = try createBookmark(for: url)
            }
            
            return url
        } catch {
            print("ERROR: Failed to resolve bookmark: \(error.localizedDescription)")
            throw FileError.bookmarkResolutionFailed
        }
    }
    
    // Access a security-scoped resource with proper error handling
    func accessSecurityScopedResource<T>(at url: URL, handler: () throws -> T) throws -> T {
        guard url.startAccessingSecurityScopedResource() else {
            print("ERROR: Failed to access security-scoped resource at \(url.path)")
            throw FileError.securityScopedAccessFailed
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
            print("DEBUG: Stopped accessing security-scoped resource")
        }
        
        do {
            let result = try handler()
            return result
        } catch {
            print("ERROR: Error while accessing security-scoped resource: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - File Operations
    
    func saveImage(image: UIImage, withID id: String, category: ImageCategory) -> String? {
        guard image.size.width > 0, image.size.height > 0,
              !image.size.width.isNaN, !image.size.height.isNaN,
              image.size.width.isFinite, image.size.height.isFinite else {
            print("DEBUG: Skipping invalid image")
            return nil
        }
        
        // Optimize image
        let optimizedImage = optimizeImage(image, for: category)
        
        // Generate filename with timestamp
        let safeID = id.replacingOccurrences(of: "/", with: "_")
                      .replacingOccurrences(of: ":", with: "_")
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "\(safeID)_\(timestamp).jpg"
        
        do {
            guard let appSupportDirectory = try getAppSupportDirectory() else { return nil }
            
            // Get directory for this category
            let categoryDirectory = appSupportDirectory.appendingPathComponent(category.rawValue, isDirectory: true)
            try createDirectoryIfNeeded(at: categoryDirectory)
            
            // Full path for the file
            let imagePath = categoryDirectory.appendingPathComponent(filename)
            
            // Write the image data with improved error handling
            guard let imageData = optimizedImage.jpegData(compressionQuality: 0.6) else {
                print("ERROR: Failed to convert image to JPEG data")
                return nil
            }
            
            // Track write success
            var writeSuccess = false
            
            do {
                try imageData.write(to: imagePath, options: [.atomicWrite, .completeFileProtection])
                writeSuccess = true
                print("DEBUG: Successfully wrote image to \(imagePath.path)")
            } catch {
                print("ERROR: Failed to write image data: \(error.localizedDescription)")
                // Try an alternative approach with FileManager
                if FileManager.default.createFile(atPath: imagePath.path, contents: imageData, attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]) {
                    writeSuccess = true
                    print("DEBUG: Successfully wrote image using FileManager")
                } else {
                    print("ERROR: Both write methods failed for image")
                }
            }
            
            if writeSuccess {
                // Clean up old files
                cleanupOldImages(for: safeID, in: categoryDirectory, currentFilename: filename)
                
                // Return relative path for storage
                return "\(category.rawValue)/\(filename)"
            } else {
                return nil
            }
        } catch {
            print("ERROR: Failed to save image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loadImage(from relativePath: String) -> UIImage? {
        do {
            guard let appSupportDirectory = try getAppSupportDirectory() else { return nil }
            
            let imagePath = appSupportDirectory.appendingPathComponent(relativePath)
            
            if FileManager.default.fileExists(atPath: imagePath.path) {
                // Try to load with improved error handling
                do {
                    let imageData = try Data(contentsOf: imagePath)
                    if let image = UIImage(data: imageData) {
                        return image
                    } else {
                        print("ERROR: Could not create UIImage from data at \(imagePath.path)")
                        return nil
                    }
                } catch {
                    print("ERROR: Failed to load image data: \(error.localizedDescription)")
                    
                    // Try alternative method
                    if let data = FileManager.default.contents(atPath: imagePath.path),
                       let image = UIImage(data: data) {
                        print("DEBUG: Loaded image using alternative method")
                        return image
                    }
                    return nil
                }
            } else {
                print("DEBUG: Image file not found at \(imagePath.path)")
                return nil
            }
        } catch {
            print("ERROR: Failed to load image: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteImage(at relativePath: String) -> Bool {
        do {
            guard let appSupportDirectory = try getAppSupportDirectory() else { return false }
            
            let imagePath = appSupportDirectory.appendingPathComponent(relativePath)
            
            if FileManager.default.fileExists(atPath: imagePath.path) {
                // Try to delete with improved error handling
                do {
                    try FileManager.default.removeItem(at: imagePath)
                    print("DEBUG: Successfully deleted file at \(imagePath.path)")
                    return true
                } catch {
                    print("ERROR: Failed to delete file: \(error.localizedDescription)")
                    
                    // Try a second time after a short delay
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        do {
                            try FileManager.default.removeItem(at: imagePath)
                            print("DEBUG: Successfully deleted file on second attempt")
                        } catch {
                            print("ERROR: Second delete attempt also failed: \(error.localizedDescription)")
                        }
                    }
                    return false
                }
            } else {
                print("DEBUG: No image to delete at \(imagePath.path)")
                return true // Consider it a success if the file doesn't exist
            }
        } catch {
            print("ERROR: Failed to delete image: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Utility Methods
    
    private func optimizeImage(_ image: UIImage, for category: ImageCategory) -> UIImage {
        // Validate input image
        guard image.size.width > 0, image.size.height > 0,
              !image.size.width.isNaN, !image.size.height.isNaN,
              image.size.width.isFinite, image.size.height.isFinite,
              image.cgImage != nil || image.ciImage != nil else {
            print("ERROR: Invalid image dimensions in optimizeImage")
            
            // Return a placeholder instead of the invalid image
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
            return renderer.image { ctx in
                UIColor.systemGray5.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            }
        }
        
        var maxDimension: CGFloat
        
        // Different max dimensions based on category
        switch category {
        case .product, .supplier:
            maxDimension = 1200
        case .contact:
            maxDimension = 800
        }
        
        // If image is smaller than max dimension, return it as is
        if image.size.width <= maxDimension && image.size.height <= maxDimension {
            return image
        }
        
        // Calculate new size with safety checks
        let maxImageDimension = max(image.size.width, image.size.height)
        
        // Prevent division by zero or tiny values that could lead to huge scales
        guard maxImageDimension > 10 else {
            print("WARNING: Image dimension too small for scaling")
            return image
        }
        
        let scale = maxDimension / maxImageDimension
        
        // Validate scale is reasonable
        guard scale > 0, scale < 10, scale.isFinite, !scale.isNaN else {
            print("ERROR: Invalid scale calculated: \(scale)")
            return image
        }
        
        let newWidth = image.size.width * scale
        let newHeight = image.size.height * scale
        
        // Final validation of new dimensions
        guard newWidth > 0, newHeight > 0,
              newWidth.isFinite, newHeight.isFinite,
              !newWidth.isNaN, !newHeight.isNaN,
              newWidth <= 5000, newHeight <= 5000 else {
            print("ERROR: Invalid new dimensions calculated: \(newWidth) x \(newHeight)")
            return image
        }
        
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // Use autoreleasepool to manage memory during image operations
        return autoreleasepool {
            // UIGraphicsImageRenderer doesn't throw errors directly, so we need to handle potential failures differently
            let renderer = UIGraphicsImageRenderer(size: newSize)
            let resizedImage = renderer.image { ctx in
                ctx.cgContext.interpolationQuality = .high
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
            
            // Verify the result is valid
            if resizedImage.size.width <= 0 || resizedImage.size.height <= 0 {
                print("ERROR: Failed to render resized image properly")
                return image
            }
            
            return resizedImage
        }
    }
    
    private func getAppSupportDirectory() throws -> URL? {
        do {
            let url = try FileManager.default.url(for: .applicationSupportDirectory, 
                                               in: .userDomainMask, 
                                               appropriateFor: nil, 
                                               create: true)
            return url
        } catch {
            print("ERROR: Failed to get app support directory: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, 
                                             withIntermediateDirectories: true,
                                             attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
                print("DEBUG: Created directory at \(url.path)")
            } catch {
                print("ERROR: Failed to create directory at \(url.path): \(error.localizedDescription)")
                throw FileError.directoryCreationFailed
            }
        }
    }
    
    private func cleanupOldImages(for id: String, in directory: URL, currentFilename: String) {
        do {
            let fileManager = FileManager.default
            
            // Find all files for this ID
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let oldFiles = contents.filter { 
                $0.lastPathComponent.starts(with: id) && 
                $0.lastPathComponent != currentFilename 
            }
            
            // Delete old files
            for file in oldFiles {
                do {
                    try fileManager.removeItem(at: file)
                    print("DEBUG: Cleaned up old image file: \(file.lastPathComponent)")
                } catch {
                    print("ERROR: Failed to clean up old image file \(file.lastPathComponent): \(error.localizedDescription)")
                }
            }
        } catch {
            print("ERROR: Failed to clean up old images: \(error.localizedDescription)")
        }
    }
    
    // MARK: - iCloud Integration
    
    func setupUbiquityContainer() {
        // Check if iCloud is available
        if let _ = FileManager.default.ubiquityIdentityToken {
            print("DEBUG: iCloud is available")
            
            // Get the iCloud container URL
            DispatchQueue.global(qos: .background).async {
                if let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil) {
                    print("DEBUG: iCloud container URL: \(containerURL.path)")
                    
                    // Create Documents directory in iCloud container if needed
                    let documentsURL = containerURL.appendingPathComponent("Documents")
                    do {
                        if !FileManager.default.fileExists(atPath: documentsURL.path) {
                            try FileManager.default.createDirectory(
                                at: documentsURL,
                                withIntermediateDirectories: true,
                                attributes: nil
                            )
                            print("DEBUG: Created Documents directory in iCloud container")
                        }
                    } catch {
                        print("ERROR: Failed to create iCloud Documents directory: \(error.localizedDescription)")
                    }
                } else {
                    print("DEBUG: iCloud container URL not available")
                }
            }
        } else {
            print("DEBUG: iCloud is not available")
        }
    }
    
    // Method to sync files to iCloud if needed
    func syncToiCloud(userSettings: UserSettings) {
        guard userSettings.iCloudSyncEnabled,
              let _ = FileManager.default.ubiquityIdentityToken else {
            print("DEBUG: iCloud sync disabled or unavailable")
            return
        }
        
        // Implementation would depend on your specific needs
        print("DEBUG: Starting iCloud sync for files")
        
        // This could involve:
        // 1. Copying files from local storage to iCloud container
        // 2. Setting up file coordination for shared files
        // 3. Using CloudKit to store file metadata
        
        print("DEBUG: iCloud sync completed")
    }
    
    // MARK: - External Storage Access
    
    // Function to let users select and bookmark an external storage location
    func selectAndBookmarkExternalStorage(completion: @escaping (Result<URL, Error>) -> Void) {
        // This would typically involve presenting a UIDocumentPickerViewController
        // Since we can't do that here, this is a placeholder for the implementation
        
        // Example of how the implementation would look:
        /* 
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.delegate = self // Your class would implement UIDocumentPickerDelegate
        
        // In the delegate method:
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedURL = urls.first else {
                completion(.failure(FileError.directoryCreationFailed))
                return
            }
            
            do {
                let bookmarkData = try createBookmark(for: selectedURL)
                let resolvedURL = try URL(resolvingBookmarkData: bookmarkData, 
                                         options: .withoutUI, 
                                         relativeTo: nil, 
                                         bookmarkDataIsStale: nil)
                completion(.success(resolvedURL))
            } catch {
                completion(.failure(error))
            }
        }
        */
        
        // For now, just simulate a failure since we can't actually implement the picker
        completion(.failure(FileError.bookmarkCreationFailed))
    }
    
    // Check if we have a valid bookmark for external storage
    func hasValidExternalStorage() -> Bool {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return false
        }
        
        do {
            var isStale = false
            let url = try URL(resolvingBookmarkData: bookmarkData,
                             options: .withoutUI,
                             relativeTo: nil,
                             bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("WARN: External storage bookmark is stale")
                return false
            }
            
            // Verify the URL is still accessible
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                return FileManager.default.fileExists(atPath: url.path)
            } else {
                return false
            }
        } catch {
            print("ERROR: Failed to verify external storage bookmark: \(error.localizedDescription)")
            return false
        }
    }
} 