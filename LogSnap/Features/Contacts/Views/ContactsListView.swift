import SwiftUI
import CoreData

// No need for a special import as PlaceholderViews.swift is part of the same module

struct ContactsListView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject private var viewModel: ContactsViewModel = ContactsViewModel()
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search contacts", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        viewModel.searchText = newValue
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.contacts.isEmpty {
                emptyView
            } else {
                contactsList
            }
        }
        .navigationTitle("Contacts")
        .onAppear {
            viewModel.fetchContacts(from: viewContext)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Contacts Found")
                .font(.headline)
            
            Text("Add contacts to suppliers to keep track of your key contacts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: SupplierListView()) {
                Text("Go to Suppliers")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contactsList: some View {
        List {
            ForEach(viewModel.getSupplierNames(), id: \.self) { supplierName in
                Section(header: Text(supplierName)) {
                    ForEach(viewModel.getContactsForSupplier(supplierName: supplierName), id: \.objectID) { contact in
                        ContactListRow(contact: contact, onEdit: {
                            // Edit contact action - would use ContactsFormView here
                        }, onDelete: {
                            viewModel.deleteContact(contact, context: viewContext)
                        })
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .refreshable {
            Task {
                await viewModel.refreshContacts(from: viewContext)
            }
        }
    }
}

// Renamed to avoid conflict with ContactRow in AddSupplierView
struct ContactListRow: View {
    let contact: ContactPerson
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contact.value(forKey: "name") as? String ?? "Unnamed Contact")
                .font(.headline)
            
            if let jobTitle = contact.value(forKey: "jobTitle") as? String, !jobTitle.isEmpty {
                Text(jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                if let email = contact.value(forKey: "email") as? String, !email.isEmpty {
                    Link(destination: URL(string: "mailto:\(email)")!) {
                        Image(systemName: "envelope")
                            .foregroundColor(.blue)
                    }
                }
                
                if let phone = contact.value(forKey: "phone") as? String, !phone.isEmpty {
                    Link(destination: URL(string: "tel:\(phone)")!) {
                        Image(systemName: "phone")
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ContactsFormView (Renamed to avoid conflicts)
struct ContactsFormView: View {
    let context: NSManagedObjectContext
    let onSave: (ContactPerson) -> Void
    
    @State private var name = ""
    @State private var jobTitle = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var selectedSupplier: Supplier?
    @State private var showingSupplierPicker = false
    @State private var suppliers: [Supplier] = []
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Contact Information")) {
                TextField("Name", text: $name)
                TextField("Job Title", text: $jobTitle)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }
            
            Section(header: Text("Supplier")) {
                Button(action: {
                    showingSupplierPicker = true
                }) {
                    HStack {
                        Text("Select Supplier")
                        Spacer()
                        Text(selectedSupplier?.name ?? "None")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Section {
                Button("Save Contact") {
                    saveContact()
                }
                .disabled(name.isEmpty && jobTitle.isEmpty)
            }
        }
        .onAppear {
            fetchSuppliers()
        }
        .sheet(isPresented: $showingSupplierPicker) {
            NavigationView {
                List {
                    ForEach(suppliers, id: \.objectID) { supplier in
                        Button(action: {
                            selectedSupplier = supplier
                            showingSupplierPicker = false
                        }) {
                            HStack {
                                Text(supplier.name ?? "Unnamed Supplier")
                                Spacer()
                                if supplier == selectedSupplier {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Select Supplier")
                .navigationBarItems(leading: Button("Cancel") {
                    showingSupplierPicker = false
                })
            }
        }
    }
    
    private func fetchSuppliers() {
        let request = NSFetchRequest<Supplier>(entityName: "Supplier")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Supplier.name, ascending: true)]
        
        do {
            suppliers = try context.fetch(request)
        } catch {
            print("Error fetching suppliers: \(error)")
        }
    }
    
    private func saveContact() {
        guard !name.isEmpty else { return }
        
        let newContact = ContactPerson(context: context)
        newContact.setValue(name, forKey: "name")
        newContact.setValue(jobTitle, forKey: "jobTitle")
        newContact.setValue(email, forKey: "email")
        newContact.setValue(phone, forKey: "phone")
        newContact.setValue(selectedSupplier, forKey: "supplier")
        newContact.setValue(Date(), forKey: "createdAt")
        
        do {
            try context.save()
            onSave(newContact)
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving contact: \(error)")
        }
    }
}

// MARK: - ContactDetailView (Placeholder)
struct ContactDetailView: View {
    let contact: ContactPerson
    let context: NSManagedObjectContext
    
    var body: some View {
        List {
            Section(header: Text("Contact Information")) {
                if let name = contact.value(forKey: "name") as? String, !name.isEmpty {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(name)
                            .foregroundColor(.gray)
                    }
                }
                
                if let jobTitle = contact.value(forKey: "jobTitle") as? String, !jobTitle.isEmpty {
                    HStack {
                        Text("Job Title")
                        Spacer()
                        Text(jobTitle)
                            .foregroundColor(.gray)
                    }
                }
                
                if let email = contact.value(forKey: "email") as? String, !email.isEmpty {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(email)
                            .foregroundColor(.gray)
                    }
                }
                
                if let phone = contact.value(forKey: "phone") as? String, !phone.isEmpty {
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(phone)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            if let supplier = contact.value(forKey: "supplier") as? Supplier {
                Section(header: Text("Supplier")) {
                    NavigationLink(destination: SupplierDetailPlaceholder(supplier: supplier)) {
                        HStack {
                            Text("Company")
                            Spacer()
                            Text(supplier.value(forKey: "name") as? String ?? "Unknown Supplier")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section {
                Button(action: {
                    callContact()
                }) {
                    HStack {
                        Spacer()
                        Label("Call Contact", systemImage: "phone.fill")
                        Spacer()
                    }
                }
                .disabled((contact.value(forKey: "phone") as? String)?.isEmpty ?? true)
                
                Button(action: {
                    emailContact()
                }) {
                    HStack {
                        Spacer()
                        Label("Email Contact", systemImage: "envelope.fill")
                        Spacer()
                    }
                }
                .disabled((contact.value(forKey: "email") as? String)?.isEmpty ?? true)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func callContact() {
        guard let phone = contact.value(forKey: "phone") as? String, !phone.isEmpty else { return }
        
        let cleanedPhone = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        guard let url = URL(string: "tel://\(cleanedPhone)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func emailContact() {
        guard let email = contact.value(forKey: "email") as? String, !email.isEmpty else { return }
        
        guard let url = URL(string: "mailto:\(email)") else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
} 