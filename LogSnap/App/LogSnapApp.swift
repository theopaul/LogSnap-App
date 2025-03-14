import SwiftUI
import CoreData

struct LogSnapApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var userSettings = UserSettings()
    
    // Initialize CoreDataManager with UserSettings to respect iCloud sync preference
    // Use lazy initialization to ensure userSettings is fully initialized first
    private lazy var coreDataManager: CoreDataManager = {
        return CoreDataManager.shared(with: userSettings)
    }()
    
    // Initialize CloudKit sync handler
    private let cloudSyncHandler = CloudKitSyncHandler()
    
    var body: some Scene {
        // Create a body function that explicitly returns the scene
        // This allows us to create local copies of any values needed for view modifiers
        let scene = WindowGroup {
            // Capture any needed values before building the view hierarchy
            let viewContext = coreDataManager.container.viewContext
            
            MainTabView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(userSettings)
                // Use simple, direct comparison with enum values
                .preferredColorScheme({
                    switch userSettings.appearanceMode {
                    case .light: return .light
                    case .dark: return .dark
                    default: return nil
                    }
                }())
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .inactive || newPhase == .background {
                        // Save the context if it has changes
                        saveContextIfNeeded()
                    }
                }
        }
        
        return scene
    }
    
    // Helper function to avoid mutating operations in the view context
    private func saveContextIfNeeded() {
        let context = coreDataManager.container.viewContext
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}

// Create a CloudKit sync handler to manage iCloud sync status
class CloudKitSyncHandler {
    private var ubiquitousKeyValueToken: NSObjectProtocol?
    
    init() {
        setupUbiquitousKeyValueStoreObserver()
        
        // Try to sync NSUbiquitousKeyValueStore
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    deinit {
        if let token = ubiquitousKeyValueToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    private func setupUbiquitousKeyValueStoreObserver() {
        // Add observer for changes to the key-value store
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
        
        // Process each changed key
        for key in changedKeys {
            // Handle specific key changes here if needed
            if key.contains("UserSettings") {
                print("DEBUG: User settings changed in iCloud")
                // Update local settings if needed
            }
        }
    }
}
