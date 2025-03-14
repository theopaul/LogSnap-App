import Foundation
import CoreData
import SwiftUI
import Combine

class ContactsViewModel: ObservableObject {
    @Published var contacts: [ContactPerson] = []
    @Published var groupedContacts: [String: [ContactPerson]] = [:]
    @Published var isLoading: Bool = false
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.filterContacts()
            }
            .store(in: &cancellables)
    }
    
    var filteredContacts: [ContactPerson] {
        if searchText.isEmpty {
            return contacts
        } else {
            return contacts.filter { contact in
                let nameMatch = contact.value(forKey: "name") as? String ?? ""
                let jobMatch = contact.value(forKey: "jobTitle") as? String ?? ""
                let emailMatch = contact.value(forKey: "email") as? String ?? ""
                let phoneMatch = contact.value(forKey: "phone") as? String ?? ""
                let supplierName = (contact.value(forKey: "supplier") as? Supplier)?.value(forKey: "name") as? String ?? ""
                
                return nameMatch.localizedCaseInsensitiveContains(searchText) ||
                       jobMatch.localizedCaseInsensitiveContains(searchText) ||
                       emailMatch.localizedCaseInsensitiveContains(searchText) ||
                       phoneMatch.localizedCaseInsensitiveContains(searchText) ||
                       supplierName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func fetchContacts(from context: NSManagedObjectContext) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest = NSFetchRequest<ContactPerson>(entityName: "ContactPerson")
            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "supplier.name", ascending: true),
                NSSortDescriptor(key: "name", ascending: true)
            ]
            
            do {
                let fetchedContacts = try context.fetch(fetchRequest)
                
                DispatchQueue.main.async {
                    self.contacts = fetchedContacts
                    self.filterContacts()
                    self.isLoading = false
                }
            } catch {
                print("Error fetching contacts: \(error)")
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func refreshContacts(from context: NSManagedObjectContext) async {
        // Properly make this method async by running the fetch on a background task
        await Task.detached {
            self.fetchContacts(from: context)
        }.value
    }
    
    private func filterContacts() {
        let filteredContacts: [ContactPerson]
        
        if searchText.isEmpty {
            filteredContacts = contacts
        } else {
            filteredContacts = contacts.filter { contact in
                let name = contact.value(forKey: "name") as? String ?? ""
                let jobTitle = contact.value(forKey: "jobTitle") as? String ?? ""
                let email = contact.value(forKey: "email") as? String ?? ""
                let phone = contact.value(forKey: "phone") as? String ?? ""
                let supplier = contact.value(forKey: "supplier") as? Supplier
                let supplierName = supplier?.value(forKey: "name") as? String ?? ""
                let searchQuery = searchText.lowercased()
                
                return name.lowercased().contains(searchQuery) ||
                       jobTitle.lowercased().contains(searchQuery) ||
                       email.lowercased().contains(searchQuery) ||
                       phone.lowercased().contains(searchQuery) ||
                       supplierName.lowercased().contains(searchQuery)
            }
        }
        
        // Group contacts by supplier
        var grouped: [String: [ContactPerson]] = [:]
        
        for contact in filteredContacts {
            let supplier = contact.value(forKey: "supplier") as? Supplier
            let supplierName = supplier?.value(forKey: "name") as? String ?? "Unknown Supplier"
            
            if grouped[supplierName] == nil {
                grouped[supplierName] = []
            }
            
            grouped[supplierName]?.append(contact)
        }
        
        groupedContacts = grouped
    }
    
    func getContactFullName(_ contact: ContactPerson) -> String {
        let name = contact.value(forKey: "name") as? String ?? ""
        
        if name.isEmpty {
            return "Unnamed Contact"
        } else {
            return name
        }
    }
    
    func getSupplierNames() -> [String] {
        // Return sorted supplier names
        return groupedContacts.keys.sorted()
    }
    
    func getContactsForSupplier(supplierName: String) -> [ContactPerson] {
        return groupedContacts[supplierName] ?? []
    }
    
    func deleteContact(_ contact: ContactPerson, context: NSManagedObjectContext) {
        context.delete(contact)
        
        do {
            try context.save()
            fetchContacts(from: context) // Refresh contacts after deletion
        } catch {
            print("Error deleting contact: \(error)")
        }
    }
} 