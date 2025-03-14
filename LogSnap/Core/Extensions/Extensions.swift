import Foundation
import CoreData
import SwiftUI

// MARK: - NSArray Extensions
extension NSArray {
    func toStringArray() -> [String] {
        return self.compactMap { $0 as? String }
    }
}

// MARK: - Array<String> Extensions
extension Array where Element == String {
    func toNSArray() -> NSArray {
        return self as NSArray
    }
}

// MARK: - String Extensions
extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Date Extensions
extension Date {
    func timeAgoString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Product Extensions
extension Product {
    func getFirstImagePath() -> String? {
        guard let paths = imagePaths?.toStringArray(), !paths.isEmpty else {
            return nil
        }
        return paths.first
    }
    
    func getDimensionsComponents() -> (width: String, height: String, depth: String) {
        guard let dimensionsString = dimensions else {
            return ("", "", "")
        }
        
        let components = dimensionsString.components(separatedBy: ["x", "×"])
        if components.count == 3 {
            return (components[0], components[1], components[2])
        }
        return ("", "", "")
    }
    
    func getImages() -> [UIImage] {
        // Only check for path-based images
        guard let paths = imagePaths?.toStringArray() else {
            return []
        }
        
        return paths.compactMap { path in
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            let fileURL = documentsDirectory.appendingPathComponent(path)
            guard let imageData = try? Data(contentsOf: fileURL) else {
                return nil
            }
            
            return UIImage(data: imageData)
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let primaryApp = Color("Primary")
    static let secondaryApp = Color("Secondary")
    static let backgroundApp = Color("Background")
    // Using a different name to avoid conflict with generated asset symbols
    static let customAccent = Color("Accent")
}

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// Helper shape for custom corner radius
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
} 