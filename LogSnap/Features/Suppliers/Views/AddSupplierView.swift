import SwiftUI
import CoreData
import UIKit

struct AddSupplierView: View {
    @ObservedObject var viewModel: SupplierViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    @State private var showUnsavedChangesAlert = false
    @State private var showContactPersonForm = false
    @State private var notes: String = ""
    
    var editingSupplier: Supplier?
    
    private var isEditing: Bool {
        return editingSupplier != nil
    }
    
    var body: some View {
        KeyboardAwareScrollView {
            VStack(spacing: 20) {
                // Supplier Images - Using the new MultiImagePicker
                MultiImagePicker(selectedImages: $viewModel.supplierImages)
                    .padding(.horizontal)
                
                // Basic Info
                basicInfoSection
                
                // Contact Persons Section
                contactPersonsSection
                
                // Notes Section
                notesSection
                
                // Save Button
                saveButton
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .dismissKeyboardOnDrag()
        .onTapToDismissKeyboard()
        .navigationTitle(isEditing ? "Edit Supplier" : "New Supplier")
        .navigationBarItems(leading: cancelButton, trailing: saveButton)
        .alert(isPresented: $showUnsavedChangesAlert) {
            unsavedChangesAlert
        }
        .sheet(isPresented: $showContactPersonForm) {
            NavigationView {
                AddContactPersonView(
                    contactPerson: viewModel.editingContactPerson,
                    onSave: { contactPerson in
                        if viewModel.isEditingExistingContact {
                            viewModel.updateContactPersonInList(contactPerson)
                        } else {
                            viewModel.addContactPerson(contactPerson)
                        }
                    }
                )
            }
        }
        .onAppear {
            if let supplier = editingSupplier {
                viewModel.loadSupplierForEditing(supplier)
                notes = supplier.notes ?? ""
            }
        }
    }
    
    // MARK: - UI Components
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(.accentColor)
                
                Text("Basic Information")
                    .font(.headline)
            }
            
            FormField(
                text: $viewModel.name,
                placeholder: "Supplier Name",
                icon: "building.2",
                validation: { text in
                    return (!text.trimmed().isEmpty, text.trimmed().isEmpty ? LocalizedStringKey("Name is required") : nil)
                }
            )
            
            FormField(
                text: $viewModel.category,
                placeholder: "Category",
                icon: "folder"
            )
            
            FormField(
                text: $viewModel.email,
                placeholder: "Email Address",
                icon: "envelope",
                keyboardType: .emailAddress,
                capitalization: .never,
                validation: { text in
                    if !text.isEmpty {
                        let isValid = isValidEmail(text)
                        return (isValid, !isValid ? LocalizedStringKey("Invalid email format") : nil)
                    }
                    return (true, nil)
                }
            )
            
            FormField(
                text: $viewModel.phone,
                placeholder: "Phone Number",
                icon: "phone",
                keyboardType: .phonePad
            )
            
            FormField(
                text: $viewModel.address,
                placeholder: "Address",
                icon: "mappin.and.ellipse"
            )
            
            FormField(
                text: $viewModel.website,
                placeholder: "Website",
                icon: "globe",
                keyboardType: .URL,
                capitalization: .never
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var contactPersonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.accentColor)
                
                Text(LocalizedStringKey("Contact Persons"))
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.prepareToAddNewContactPerson()
                    showContactPersonForm = true
                }) {
                    Label(LocalizedStringKey("Add"), systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if viewModel.contactPersons.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text(LocalizedStringKey("No contact persons added yet"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            viewModel.prepareToAddNewContactPerson()
                            showContactPersonForm = true
                        }) {
                            Text(LocalizedStringKey("Add a contact person"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 4)
                    }
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ForEach(viewModel.contactPersons.indices, id: \.self) { index in
                    contactPersonRow(viewModel.contactPersons[index], index: index)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private func contactPersonRow(_ contactPerson: ContactPersonViewModel, index: Int) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contactPerson.name)
                        .font(.system(size: 16, weight: .medium))
                    
                    if !contactPerson.position.isEmpty {
                        Text(contactPerson.position)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !contactPerson.email.isEmpty {
                        Label(contactPerson.email, systemImage: "envelope")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !contactPerson.phone.isEmpty {
                        Label(contactPerson.phone, systemImage: "phone")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Edit button
                Button(action: {
                    viewModel.prepareToEditContactPerson(index)
                    showContactPersonForm = true
                }) {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
                
                // Delete button
                Button(action: {
                    viewModel.removeContactPerson(at: index)
                }) {
                    Image(systemName: "trash.circle")
                        .font(.system(size: 22))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
            
            if index < viewModel.contactPersons.count - 1 {
                Divider()
                    .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var notesSection: some View {
        Section(header: Text("Notes")) {
            HStack(alignment: .top) {
                Image(systemName: "doc.text")
                    .foregroundColor(.gray)
                    .frame(width: 24, height: 24)
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            saveSupplier()
        }) {
            HStack {
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                Text(isEditing ? "Update Supplier" : "Add Supplier")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 16)
            .background(viewModel.name.trimmed().isEmpty ? Color.gray : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .disabled(viewModel.name.trimmed().isEmpty)
        .padding(.top, 16)
    }
    
    private var cancelButton: some View {
        Button(action: {
            if hasUnsavedChanges() {
                showUnsavedChangesAlert = true
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Text("Cancel")
        }
        .frame(minWidth: 44, minHeight: 44)
    }
    
    private var unsavedChangesAlert: Alert {
        Alert(
            title: Text("Unsaved Changes"),
            message: Text("Do you want to save your changes?"),
            primaryButton: .default(Text("Save")) {
                saveSupplier()
            },
            secondaryButton: .destructive(Text("Discard")) {
                presentationMode.wrappedValue.dismiss()
            }
        )
    }
    
    // MARK: - Helper Methods
    
    // Email validation function
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func hasUnsavedChanges() -> Bool {
        return !viewModel.name.isEmpty ||
               !viewModel.email.isEmpty ||
               !viewModel.phone.isEmpty ||
               !viewModel.address.isEmpty ||
               !viewModel.website.isEmpty ||
               !viewModel.notes.isEmpty ||
               !viewModel.supplierImages.isEmpty ||
               !viewModel.contactPersons.isEmpty
    }
    
    private func saveSupplier() {
        // Add notes to viewModel for saving
        viewModel.notes = notes
        
        // Ensure the form is valid before saving
        guard viewModel.validateForm() else {
            return
        }
        
        var success = false
        
        if let supplier = editingSupplier {
            success = viewModel.updateSupplier(supplier)
        } else {
            success = viewModel.saveSupplier()
        }
        
        if success {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview Provider
struct AddSupplierView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a simplified preview with just one appearance mode
        NavigationView {
            AddSupplierView(
                viewModel: createPreviewViewModel()
            )
            .environment(\.managedObjectContext, SupplierPreviewController.preview.container.viewContext)
        }
        .previewDisplayName("Supplier Form")
    }
    
    // Helper to create a consistently configured view model for previews
    static func createPreviewViewModel() -> SupplierViewModel {
        let context = SupplierPreviewController.preview.container.viewContext
        
        // Create mock view model with minimal test data
        let viewModel = SupplierViewModel(context: context)
        viewModel.name = "Acme Corporation"
        viewModel.email = "contact@acme.com"
        viewModel.phone = "555-1234"
        
        return viewModel
    }
}

// Use a renamed controller to avoid conflicts
// Since we've already renamed PersistenceController in AddProductView
#if !_APP_SUPPLIER_PREVIEW_CONTROLLER_DEFINED
private let _APP_SUPPLIER_PREVIEW_CONTROLLER_DEFINED = true

class SupplierPreviewController {
    // A singleton for our entire app to use
    static let shared = SupplierPreviewController()
    
    // Storage for Core Data
    let container: NSPersistentContainer
    
    // A test configuration for SwiftUI previews
    static var preview: SupplierPreviewController = {
        let controller = SupplierPreviewController(inMemory: true)
        
        // Create 1 example supplier
        let viewContext = controller.container.viewContext
        let supplier = Supplier(context: viewContext)
        supplier.name = "Sample Supplier"
        supplier.email = "contact@supplier.com"
        supplier.phone = "555-1234"
        
        do {
            try viewContext.save()
        } catch {
            // Handle error in a way that doesn't crash the preview
            print("Preview error: \(error)")
        }
        
        return controller
    }()
    
    // Initialize with an optional in-memory store
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "LogSnap")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Failed to load persistent stores: \(error)")
            }
        }
        
        // For preview purposes, merge policy to avoid conflicts
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
#endif
