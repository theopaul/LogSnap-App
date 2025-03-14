import SwiftUI
import CoreData

struct SupplierDetailView: View {
    let supplier: Supplier
    @StateObject private var viewModel = SupplierViewModel()
    @State private var showEditSupplier = false
    @State private var showDeleteConfirmation = false
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text(supplier.name ?? "")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Divider()
                }
                .padding(.horizontal)
                
                // Contact Info
                Group {
                    if let contactPerson = supplier.contactPerson, !contactPerson.isEmpty {
                        infoRow(
                            title: "Contact Person",
                            value: contactPerson,
                            icon: "person.fill"
                        )
                    }
                    
                    if let email = supplier.email, !email.isEmpty {
                        Button(action: {
                            openEmail(email)
                        }) {
                            infoRow(
                                title: "Email",
                                value: email,
                                icon: "envelope.fill",
                                isLink: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if let phone = supplier.phone, !phone.isEmpty {
                        Button(action: {
                            openPhone(phone)
                        }) {
                            infoRow(
                                title: "Phone",
                                value: phone,
                                icon: "phone.fill",
                                isLink: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if let address = supplier.address, !address.isEmpty {
                        Button(action: {
                            openMaps(address)
                        }) {
                            infoRow(
                                title: "Address",
                                value: address,
                                icon: "location.fill",
                                isLink: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if let website = supplier.website, !website.isEmpty {
                        Button(action: {
                            openWebsite(website)
                        }) {
                            infoRow(
                                title: "Website",
                                value: website,
                                icon: "globe",
                                isLink: true
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Notes
                if let notes = supplier.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(notes)
                            .font(.body)
                        
                        Divider()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(LocalizedStringKey("Supplier Details"))
        .navigationBarItems(trailing: 
            HStack {
                Button(action: {
                    showEditSupplier = true
                }) {
                    Text(LocalizedStringKey("Edit"))
                }
                
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        )
        .actionSheet(isPresented: $showDeleteConfirmation) {
            ActionSheet(
                title: Text(LocalizedStringKey("Delete Supplier")),
                message: Text(LocalizedStringKey("Are you sure?")),
                buttons: [
                    .destructive(Text(LocalizedStringKey("Delete"))) {
                        viewModel.deleteSupplier(supplier)
                        presentationMode.wrappedValue.dismiss()
                    },
                    .cancel()
                ]
            )
        }
        .sheet(isPresented: $showEditSupplier) {
            NavigationView {
                AddSupplierView(
                    viewModel: viewModel,
                    editingSupplier: supplier
                )
            }
        }
        .onAppear {
            // Preload supplier info for potential editing
            viewModel.loadSupplierForEditing(supplier)
        }
    }
    
    private func infoRow(title: LocalizedStringKey, value: String, icon: String, isLink: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .frame(width: 24)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(isLink ? .accentColor : .primary)
                
                if isLink {
                    Spacer()
                    
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            
            Divider()
        }
        .padding(.horizontal)
    }
    
    // Helper functions to handle external actions
    private func openEmail(_ email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPhone(_ phone: String) {
        let cleanPhone = phone.replacingOccurrences(of: " ", with: "")
                              .replacingOccurrences(of: "-", with: "")
                              .replacingOccurrences(of: "(", with: "")
                              .replacingOccurrences(of: ")", with: "")
        
        if let url = URL(string: "tel:\(cleanPhone)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openMaps(_ address: String) {
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(encodedAddress)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite(_ website: String) {
        var websiteUrl = website
        if !website.lowercased().hasPrefix("http") {
            websiteUrl = "https://" + website
        }
        
        if let url = URL(string: websiteUrl) {
            UIApplication.shared.open(url)
        }
    }
}

struct SupplierDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.previewContext
        
        // Create a fetch request but handle it safely
        let fetchRequest: NSFetchRequest<Supplier> = Supplier.fetchRequest()
        let supplier: Supplier
        
        // Try to fetch a supplier, or create a new one
        do {
            let fetchedSuppliers = try context.fetch(fetchRequest)
            if let fetchedSupplier = fetchedSuppliers.first {
                supplier = fetchedSupplier
            } else {
                supplier = Supplier(context: context)
                supplier.name = "Preview Supplier"
                supplier.email = "preview@example.com"
            }
        } catch {
            // Fallback to creating a new supplier
            supplier = Supplier(context: context)
            supplier.name = "Preview Supplier"
            supplier.email = "preview@example.com"
        }
        
        return Group {
            NavigationView {
                SupplierDetailView(supplier: supplier)
            }
            .environment(\.managedObjectContext, context)
            .environment(\.locale, .init(identifier: "en"))
            
            NavigationView {
                SupplierDetailView(supplier: supplier)
            }
            .environment(\.managedObjectContext, context)
            .environment(\.locale, .init(identifier: "pt"))
            .previewDisplayName("Portuguese")
        }
    }
} 