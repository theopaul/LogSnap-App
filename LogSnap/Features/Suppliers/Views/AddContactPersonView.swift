import SwiftUI
import UIKit

struct AddContactPersonView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var position: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var notes: String = ""
    @State private var contactImages: [UIImage] = []
    
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    
    var contactPerson: ContactPersonViewModel?
    var onSave: (ContactPersonViewModel) -> Void
    
    init(contactPerson: ContactPersonViewModel? = nil, onSave: @escaping (ContactPersonViewModel) -> Void) {
        self.contactPerson = contactPerson
        self.onSave = onSave
    }
    
    var body: some View {
        KeyboardAwareScrollView {
            VStack(spacing: 20) {
                // Contact Image - using MultiImagePicker limited to 1 image
                MultiImagePicker(selectedImages: $contactImages, maxImages: 1)
                    .padding(.horizontal)
                
                // Basic Info Section
                basicInfoSection
                
                // Contact Details Section
                contactDetailsSection
                
                // Notes Section
                notesSection
                
                // Add Button
                addButton
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .dismissKeyboardOnDrag()
        .onTapToDismissKeyboard()
        .navigationTitle(contactPerson == nil ? LocalizedStringKey("Add Contact") : LocalizedStringKey("Edit Contact"))
        .navigationBarItems(
            leading: cancelButton,
            trailing: saveButton
        )
        .onAppear {
            loadContactData()
        }
    }
    
    // MARK: - UI Components
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Basic Information"))
                    .font(.headline)
            }
            
            FormField(
                text: $name,
                placeholder: "Contact Name",
                icon: "person",
                validation: { text in
                    let isValid = !text.trimmed().isEmpty
                    nameError = isValid ? nil : NSLocalizedString("Name is required", comment: "")
                    return (isValid, isValid ? nil : LocalizedStringKey("Name is required"))
                }
            )
            
            FormField(
                text: $position,
                placeholder: "Position / Title",
                icon: "briefcase"
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var contactDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Contact Details"))
                    .font(.headline)
            }
            
            FormField(
                text: $email,
                placeholder: "Email Address",
                icon: "envelope",
                keyboardType: .emailAddress,
                capitalization: .never,
                validation: { text in
                    if !text.isEmpty {
                        let isValid = isValidEmail(text)
                        emailError = isValid ? nil : NSLocalizedString("Invalid email format", comment: "")
                        return (isValid, isValid ? nil : LocalizedStringKey("Invalid email format"))
                    }
                    return (true, nil)
                }
            )
            
            FormField(
                text: $phone,
                placeholder: "Phone Number",
                icon: "phone",
                keyboardType: .phonePad
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Notes"))
                    .font(.headline)
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentColor)
                        .frame(width: 24, height: 24)
                        .padding(.top, 8)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var addButton: some View {
        Button(action: {
            save()
        }) {
            HStack {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text(contactPerson == nil ? LocalizedStringKey("Add Contact") : LocalizedStringKey("Update Contact"))
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(name.trimmed().isEmpty ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .disabled(name.trimmed().isEmpty)
        .padding(.top, 16)
    }
    
    private var cancelButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Text(LocalizedStringKey("Cancel"))
        }
        .frame(minWidth: 44, minHeight: 44)
    }
    
    private var saveButton: some View {
        Button(action: {
            save()
        }) {
            Text(LocalizedStringKey("Save"))
        }
        .disabled(name.trimmed().isEmpty)
        .foregroundColor(name.trimmed().isEmpty ? .gray : .accentColor)
        .frame(minWidth: 44, minHeight: 44)
    }
    
    // MARK: - Helper Methods
    
    // Email validation function
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func loadContactData() {
        guard let contactPerson = contactPerson else { return }
        
        name = contactPerson.name
        position = contactPerson.position
        email = contactPerson.email
        phone = contactPerson.phone
        notes = contactPerson.notes
        
        if let image = contactPerson.image {
            contactImages = [image]
        }
    }
    
    private func save() {
        guard !name.trimmed().isEmpty else {
            nameError = NSLocalizedString("Name is required", comment: "")
            return
        }
        
        if !email.isEmpty && !isValidEmail(email) {
            emailError = NSLocalizedString("Invalid email format", comment: "")
            return
        }
        
        var contact = ContactPersonViewModel(
            id: contactPerson?.id ?? UUID().uuidString,
            name: name.trimmed(),
            position: position.trimmed(),
            email: email.trimmed(),
            phone: phone.trimmed(),
            notes: notes.trimmed()
        )
        
        // Set contact image if available
        contact.image = contactImages.first
        
        onSave(contact)
        presentationMode.wrappedValue.dismiss()
    }
} 