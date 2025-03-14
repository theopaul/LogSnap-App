import SwiftUI
import CoreData

struct LogSnapContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var userSettings: UserSettings
    let viewContext: NSManagedObjectContext
    let saveAction: (NSManagedObjectContext) -> Void
    
    var body: some View {
        MainTabView()
            .environment(\.managedObjectContext, viewContext)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .inactive || newPhase == .background {
                    saveAction(viewContext)
                }
            }
            .preferredColorScheme(colorScheme)
    }
    
    // Computed property that can safely access userSettings in a view context
    private var colorScheme: ColorScheme? {
        switch userSettings.appearanceMode {
        case .light: return .light
        case .dark: return .dark
        default: return nil
        }
    }
}

// CloudKit sync handler to manage iCloud sync status
class CloudKitSyncHandler {
    // Create shared instance using a singleton pattern
    static let shared = CloudKitSyncHandler()
    
    private var ubiquitousKeyValueToken: NSObjectProtocol?
    
    // Public initializer
    init() {
        setupUbiquitousKeyValueStoreObserver()
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    deinit {
        if let token = ubiquitousKeyValueToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    private func setupUbiquitousKeyValueStoreObserver() {
        ubiquitousKeyValueToken = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] notification in
            self?.handleUbiquitousKeyValueStoreChange(notification)
        }
    }
    
    private func handleUbiquitousKeyValueStoreChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            return
        }
        
        print("DEBUG: Received iCloud key-value store updates for keys: \(changedKeys)")
        
        for key in changedKeys {
            if key.contains("UserSettings") {
                print("DEBUG: User settings changed in iCloud")
            }
        }
    }
}

// Main app with improved architecture to avoid mutating getters
struct LogSnapApp: App {
    // Stored property for CoreData context to avoid mutating getter issues
    private let managedObjectContext: NSManagedObjectContext
    
    // StateObject for user settings
    @StateObject private var userSettings = UserSettings()
    
    // Shared CloudKit handler
    private let cloudSyncHandler: CloudKitSyncHandler
    
    // Initialize everything in init to avoid mutating operations in body
    init() {
        // Create CoreDataManager directly without using shared
        let cdManager = CoreDataManager(userSettings: UserSettings())
        self.managedObjectContext = cdManager.container.viewContext
        self.cloudSyncHandler = CloudKitSyncHandler.shared
    }
    
    var body: some Scene {
        // Just use the stored context - no mutation required
        WindowGroup {
            LogSnapContentView(
                viewContext: managedObjectContext,
                saveAction: saveIfNeeded
            )
            .environmentObject(userSettings)
        }
    }
    
    // Method that takes context as parameter to avoid accessing self
    private func saveIfNeeded(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
