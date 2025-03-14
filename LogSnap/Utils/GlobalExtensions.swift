import Foundation
import CoreData
import SwiftUI

// MARK: - Core Data Extensions

// Removing the NSManagedObjectID Identifiable conformance for now
// Instead, we'll use objectID directly in our Views

// MARK: - String Extensions

extension String {
    // Check if string is a valid email address
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    // Check if string is empty or only whitespace
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - View Extensions

extension View {
    // Hide keyboard when tapping outside of a text field
    func hideKeyboardWhenTappedOutside() -> some View {
        return self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
} 