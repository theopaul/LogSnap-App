import UIKit
import SwiftUI
import CoreData
import CloudKit

// Register transformers at application load time
// This ensures UIImageValueTransformer is registered before Core Data is used
class AppSetup {
    static let shared = AppSetup()
    private init() {
        UIImageValueTransformer.register()
        UIImageValueTransformerWrapper.registerTransformer()
    }
}

// Initialize the shared instance to trigger registration
private let appSetup = AppSetup.shared

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // Use CoreDataManager instead of creating a new container
    var persistentContainer: NSPersistentContainer {
        return CoreDataManager.shared.container
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register transformers are already handled by AppSetup
        
        // Initialize iCloud key-value store
        initializeICloudKeyValueStore()
        
        // Setup notifications for iCloud sync setting changes
        setupNotifications()
        
        // Run migration for image storage
        migrateImageStorage()
        
        return true
    }
    
    // MARK: - iCloud Setup
    
    private func initializeICloudKeyValueStore() {
        // Start key-value store synchronization
        let kvStore = NSUbiquitousKeyValueStore.default
        
        do {
            // Try to synchronize the key-value store
            let result = kvStore.synchronize()
            if result {
                print("DEBUG: Successfully initialized iCloud key-value store")
            } else {
                print("DEBUG: Failed to initialize iCloud key-value store")
            }
        }
        
        // Register for external changes in the key-value store
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquitousKeyValueStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore
        )
    }
    
    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        // Process changes to update local settings if needed
        if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] {
            print("DEBUG: iCloud key-value store changed for keys: \(changedKeys)")
            
            // Handle any specific key changes
            for key in changedKeys {
                print("DEBUG: Processing changed key: \(key)")
            }
        }
    }
    
    private func setupNotifications() {
        // Listen for changes to the iCloud sync setting
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudSyncSettingChanged),
            name: .iCloudSyncSettingChanged,
            object: nil
        )
    }
    
    @objc private func iCloudSyncSettingChanged() {
        // Show an alert to inform the user that a restart is required
        // In real app, this would display a UIAlertController, but here
        // we just log the message since we can't present UI from AppDelegate easily
        print("DEBUG: iCloud sync setting changed - app restart required for changes to take effect")
        
        // You could post a local notification or use another mechanism to alert the user
        let content = UNMutableNotificationContent()
        content.title = "iCloud Sync Setting Changed"
        content.body = "Please restart the app for changes to take effect."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "iCloudSyncChanged", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Failed to schedule notification: \(error)")
            }
        }
    }
    
    // MARK: - Image Storage Migration
    
    private func migrateImageStorage() {
        print("DEBUG: Checking for image storage migration needs")
        
        // Set a flag to track if we've already migrated
        let migrationKey = "image_storage_migration_completed_v1"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("DEBUG: Image storage migration already completed")
            return
        }
        
        do {
            // Create Application Support directories if needed
            let appSupportDirectory = try FileManager.default.url(for: .applicationSupportDirectory, 
                                                               in: .userDomainMask, 
                                                               appropriateFor: nil, 
                                                               create: true)
            
            // Create directories for each image type
            let productImagesDir = appSupportDirectory.appendingPathComponent("ProductImages", isDirectory: true)
            let supplierImagesDir = appSupportDirectory.appendingPathComponent("SupplierImages", isDirectory: true)
            let contactImagesDir = appSupportDirectory.appendingPathComponent("ContactImages", isDirectory: true)
            
            try createDirectoryIfNeeded(at: productImagesDir)
            try createDirectoryIfNeeded(at: supplierImagesDir)
            try createDirectoryIfNeeded(at: contactImagesDir)
            
            print("DEBUG: Created image storage directories successfully")
            
            // Migration will happen naturally as users interact with the app
            // We just need to ensure the directories exist
            
            // Set the flag to indicate migration setup is complete
            UserDefaults.standard.set(true, forKey: migrationKey)
            
            print("DEBUG: Image storage migration setup completed")
        } catch {
            print("ERROR: Failed to setup image storage migration: \(error.localizedDescription)")
        }
    }
    
    private func createDirectoryIfNeeded(at url: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, 
                                        withIntermediateDirectories: true,
                                        attributes: [FileAttributeKey.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            print("DEBUG: Created directory at \(url.path)")
        }
    }
    
    // MARK: - Core Data Saving support
    func saveContext() {
        CoreDataManager.shared.save()
    }
    
    // Save context when app terminates
    func applicationWillTerminate(_ application: UIApplication) {
        saveContext()
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session
        // Save data if appropriate
    }
    
    // Handle app states
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveContext()
        
        // Synchronize iCloud key-value store
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Refresh data if needed
        
        // Synchronize iCloud key-value store
        NSUbiquitousKeyValueStore.default.synchronize()
    }
} 