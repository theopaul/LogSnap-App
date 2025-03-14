import Foundation
import SwiftUI
import CoreData

struct ContactPersonViewModel: Identifiable {
    var id: String = UUID().uuidString
    var name: String = ""
    var position: String = "" // This maps to jobTitle in Core Data
    var email: String = ""
    var phone: String = ""
    var notes: String = "" // Stored in UserDefaults
    var image: UIImage? // Stored in UserDefaults
    
    init(id: String = UUID().uuidString, 
         name: String = "", 
         position: String = "", 
         email: String = "", 
         phone: String = "", 
         notes: String = "",
         image: UIImage? = nil) {
        self.id = id
        self.name = name
        self.position = position
        self.email = email
        self.phone = phone
        self.notes = notes
        self.image = image
    }
    
    // Create a ContactPersonViewModel from a Core Data ContactPerson entity
    static func from(contactPerson: ContactPerson) -> ContactPersonViewModel {
        // Get image from UserDefaults if it exists
        let contactImage = ContactPersonViewModel.getImageFromUserDefaults(forID: contactPerson.objectID.uriRepresentation().absoluteString)
        
        return ContactPersonViewModel(
            id: contactPerson.objectID.uriRepresentation().absoluteString,
            name: contactPerson.name ?? "",
            position: contactPerson.jobTitle ?? "", // Use jobTitle for position
            email: contactPerson.email ?? "",
            phone: contactPerson.phone ?? "",
            notes: ContactPersonViewModel.getNotesFromUserDefaults(forID: contactPerson.objectID.uriRepresentation().absoluteString),
            image: contactImage
        )
    }
    
    // Apply this view model's values to a Core Data ContactPerson entity
    func apply(to contactPerson: ContactPerson) {
        contactPerson.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        contactPerson.jobTitle = position.trimmingCharacters(in: .whitespacesAndNewlines) // Store position as jobTitle
        contactPerson.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        contactPerson.phone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Store notes in UserDefaults
        ContactPersonViewModel.saveNotesToUserDefaults(
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            forID: contactPerson.objectID.uriRepresentation().absoluteString
        )
        
        // Store image in UserDefaults
        if let contactImage = image {
            ContactPersonViewModel.saveImageToUserDefaults(
                image: contactImage,
                forID: contactPerson.objectID.uriRepresentation().absoluteString
            )
        } else {
            ContactPersonViewModel.removeImageFromUserDefaults(
                forID: contactPerson.objectID.uriRepresentation().absoluteString
            )
        }
    }
    
    // Validate if this ContactPersonViewModel has valid data
    func isValid() -> (Bool, LocalizedStringKey?) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return (false, LocalizedStringKey("Name is required"))
        }
        
        if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            if !emailPredicate.evaluate(with: email) {
                return (false, LocalizedStringKey("Invalid email format"))
            }
        }
        
        return (true, nil)
    }
    
    // MARK: - UserDefaults Helper Methods
    
    // Store additional contact properties in UserDefaults since they don't exist in Core Data
    private static func saveNotesToUserDefaults(notes: String, forID id: String) {
        let key = "contactPerson_notes_\(id)"
        UserDefaults.standard.set(notes, forKey: key)
    }
    
    private static func getNotesFromUserDefaults(forID id: String) -> String {
        let key = "contactPerson_notes_\(id)"
        return UserDefaults.standard.string(forKey: key) ?? ""
    }
    
    private static func saveImageToUserDefaults(image: UIImage, forID id: String) {
        let key = "contactPerson_image_\(id)"
        
        print("DEBUG: Saving contact image for ID: \(id)")
        
        // Skip invalid images
        guard image.size.width > 0, image.size.height > 0,
              !image.size.width.isNaN, !image.size.height.isNaN,
              image.size.width.isFinite, image.size.height.isFinite else {
            print("DEBUG: Skipping invalid contact image")
            removeImageFromUserDefaults(forID: id)
            return
        }
        
        // Optimize image before saving
        var optimizedImage = image
        let maxDimension: CGFloat = 800 // Smaller than product/supplier images as contact images are typically smaller
        
        if image.size.width > maxDimension || image.size.height > maxDimension {
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            let renderer = UIGraphicsImageRenderer(size: newSize)
            optimizedImage = renderer.image { ctx in
                ctx.cgContext.interpolationQuality = .high
                image.draw(in: CGRect(origin: .zero, size: newSize))
            }
        }
        
        // Compress with moderate quality
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.6) else {
            print("DEBUG: Failed to compress contact image to JPEG")
            return
        }
        
        // Use file system for storage instead of UserDefaults
        do {
            // Get application support directory
            guard let appSupportDirectory = try getAppSupportDirectory() else {
                throw NSError(domain: "LogSnap", code: 1001, 
                             userInfo: [NSLocalizedDescriptionKey: "Cannot access application support directory"])
            }
            
            // Create contacts directory
            let contactsDirectory = appSupportDirectory.appendingPathComponent("ContactImages", isDirectory: true)
            try createDirectoryIfNeeded(at: contactsDirectory)
            
            // Create a safe file name
            let safeId = id.replacingOccurrences(of: "/", with: "_")
                         .replacingOccurrences(of: ":", with: "_")
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "\(safeId)_\(timestamp).jpg"
            
            // Full path to save the image file
            let imagePath = contactsDirectory.appendingPathComponent(filename)
            print("DEBUG: Saving contact image to path: \(imagePath.path)")
            
            // Write file with options
            try imageData.write(to: imagePath, options: [.atomicWrite, .completeFileProtection])
            
            // Store only the relative path in UserDefaults
            let relativePath = "ContactImages/\(filename)"
            UserDefaults.standard.set(relativePath, forKey: key)
            
            // Clean up any old images for this contact
            cleanupOldContactImages(for: safeId, in: contactsDirectory, currentFilename: filename)
            
            print("DEBUG: Successfully saved contact image to file system")
        } catch {
            print("ERROR: Failed to save contact image to file system: \(error.localizedDescription)")
            
            // Fallback to UserDefaults only if file system storage fails
            UserDefaults.standard.set(imageData, forKey: key)
            print("DEBUG: Saved contact image to UserDefaults as fallback")
        }
    }
    
    private static func getImageFromUserDefaults(forID id: String) -> UIImage? {
        let key = "contactPerson_image_\(id)"
        print("DEBUG: Loading contact image for ID: \(id)")
        
        // First try loading from file system
        if let relativePath = UserDefaults.standard.string(forKey: key), 
           !relativePath.hasPrefix("ContactImages/") == false {  // Check if it's actually a path and not image data
            do {
                guard let appSupportDirectory = try getAppSupportDirectory() else {
                    throw NSError(domain: "LogSnap", code: 1002, 
                                 userInfo: [NSLocalizedDescriptionKey: "Cannot access application support directory"])
                }
                
                let imagePath = appSupportDirectory.appendingPathComponent(relativePath)
                print("DEBUG: Attempting to load contact image from path: \(imagePath.path)")
                
                if FileManager.default.fileExists(atPath: imagePath.path) {
                    guard let imageData = try? Data(contentsOf: imagePath) else {
                        throw NSError(domain: "LogSnap", code: 1003, 
                                     userInfo: [NSLocalizedDescriptionKey: "Cannot read image data from file"])
                    }
                    
                    guard let image = UIImage(data: imageData) else {
                        throw NSError(domain: "LogSnap", code: 1004, 
                                     userInfo: [NSLocalizedDescriptionKey: "Cannot create image from data"])
                    }
                    
                    print("DEBUG: Successfully loaded contact image from file system")
                    return image
                } else {
                    print("DEBUG: Contact image file does not exist at path: \(imagePath.path)")
                }
            } catch {
                print("ERROR: Error loading contact image from file: \(error.localizedDescription)")
            }
        }
        
        // Fallback to UserDefaults if file system failed or not a path
        if let imageData = UserDefaults.standard.data(forKey: key) {
            guard let image = UIImage(data: imageData) else {
                print("DEBUG: Failed to create image from UserDefaults data")
                return nil
            }
            
            print("DEBUG: Loaded contact image from UserDefaults fallback")
            return image
        }
        
        print("DEBUG: No contact image found for ID: \(id)")
        return nil
    }
    
    private static func removeImageFromUserDefaults(forID id: String) {
        let key = "contactPerson_image_\(id)"
        print("DEBUG: Removing contact image for ID: \(id)")
        
        // First try removing from file system
        if let relativePath = UserDefaults.standard.string(forKey: key) {
            do {
                guard let appSupportDirectory = try getAppSupportDirectory() else {
                    throw NSError(domain: "LogSnap", code: 1005, 
                                 userInfo: [NSLocalizedDescriptionKey: "Cannot access application support directory"])
                }
                
                let imagePath = appSupportDirectory.appendingPathComponent(relativePath)
                print("DEBUG: Attempting to delete contact image at path: \(imagePath.path)")
                
                if FileManager.default.fileExists(atPath: imagePath.path) {
                    try FileManager.default.removeItem(at: imagePath)
                    print("DEBUG: Successfully deleted contact image file")
                } else {
                    print("DEBUG: Contact image file doesn't exist, nothing to delete")
                }
            } catch {
                print("ERROR: Failed to delete contact image file: \(error.localizedDescription)")
            }
        }
        
        // Remove from UserDefaults
        UserDefaults.standard.removeObject(forKey: key)
        print("DEBUG: Removed contact image reference from UserDefaults")
    }
    
    // MARK: - File System Utilities
    
    private static func getAppSupportDirectory() throws -> URL? {
        return try FileManager.default.url(for: .applicationSupportDirectory, 
                                          in: .userDomainMask, 
                                          appropriateFor: nil, 
                                          create: true)
    }
    
    private static func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, 
                                          withIntermediateDirectories: true,
                                          attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            print("DEBUG: Created directory at \(url.path)")
        }
    }
    
    private static func cleanupOldContactImages(for contactId: String, in directory: URL, currentFilename: String) {
        do {
            let fileManager = FileManager.default
            
            // Find all files for this contact
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            let oldFiles = contents.filter { 
                $0.lastPathComponent.starts(with: contactId) && 
                $0.lastPathComponent != currentFilename 
            }
            
            // Delete old files
            for file in oldFiles {
                try fileManager.removeItem(at: file)
                print("DEBUG: Cleaned up old contact image file: \(file.lastPathComponent)")
            }
        } catch {
            print("ERROR: Failed to clean up old contact images: \(error.localizedDescription)")
        }
    }
} 