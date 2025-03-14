import SwiftUI
import Combine

class UserSettings: ObservableObject {
    // Keys for settings
    private enum SettingKeys {
        static let appearanceMode = "appearanceMode"
        static let iCloudSyncEnabled = "iCloudSyncEnabled"
        static let selectedLanguage = "selectedLanguage"
    }
    
    // MARK: - Published properties
    @Published var appearanceMode: AppearanceMode
    @Published var iCloudSyncEnabled: Bool
    @Published var selectedLanguage: AppLanguage
    
    // MARK: - Private properties
    // Make this lazy to avoid using self during initialization
    private lazy var isCloudAvailable: Bool = {
        return FileManager.default.ubiquityIdentityToken != nil
    }()
    
    // MARK: - Initialization
    init() {
        // Load settings without property observers first to avoid "self" usage issues
        
        // 1. Initialize appearance mode
        let rawAppearanceMode = UserDefaults.standard.string(forKey: SettingKeys.appearanceMode)
        if let savedMode = rawAppearanceMode, let mode = AppearanceMode(rawValue: savedMode) {
            self.appearanceMode = mode
        } else {
            self.appearanceMode = .automatic
        }
        
        // 2. Initialize iCloud sync setting
        self.iCloudSyncEnabled = UserDefaults.standard.bool(forKey: SettingKeys.iCloudSyncEnabled)
        
        // 3. Initialize language setting
        let rawLanguage = UserDefaults.standard.string(forKey: SettingKeys.selectedLanguage)
        if let savedLanguage = rawLanguage, let language = AppLanguage(rawValue: savedLanguage) {
            self.selectedLanguage = language
        } else {
            // Default to English, but try to detect device language
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.starts(with: "pt") {
                self.selectedLanguage = .portuguese
            } else {
                self.selectedLanguage = .english
            }
        }
        
        // Setup property observers after initialization
        setupObservers()
        
        // Register for iCloud availability changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ubiquityIdentityChanged),
            name: NSNotification.Name.NSUbiquityIdentityDidChange,
            object: nil
        )
        
        // Try to get values from iCloud if available
        syncFromCloud()
    }
    
    private func setupObservers() {
        // Now that initialization is complete, we can safely add property observers
        // Attach observers manually to prevent self usage during initialization
        $appearanceMode
            .dropFirst() // Skip the initial value
            .sink { [weak self] _ in
                self?.saveAppearanceMode()
            }
            .store(in: &cancellables)
        
        $iCloudSyncEnabled
            .dropFirst() // Skip the initial value
            .sink { [weak self] newValue in
                self?.saveICloudSyncSetting()
                
                // Notify that a restart is needed for changes to take effect
                let oldValue = UserDefaults.standard.bool(forKey: SettingKeys.iCloudSyncEnabled)
                if newValue != oldValue {
                    NotificationCenter.default.post(name: .iCloudSyncSettingChanged, object: nil)
                }
            }
            .store(in: &cancellables)
        
        $selectedLanguage
            .dropFirst() // Skip the initial value
            .sink { [weak self] _ in
                self?.saveLanguageSetting()
                NotificationCenter.default.post(name: .languageChanged, object: nil)
            }
            .store(in: &cancellables)
    }
    
    // Store for our cancellables
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Settings Management
    
    private func saveAppearanceMode() {
        saveSetting(appearanceMode.rawValue, forKey: SettingKeys.appearanceMode)
    }
    
    private func saveICloudSyncSetting() {
        saveSetting(iCloudSyncEnabled, forKey: SettingKeys.iCloudSyncEnabled)
    }
    
    private func saveLanguageSetting() {
        saveSetting(selectedLanguage.rawValue, forKey: SettingKeys.selectedLanguage)
    }
    
    private func saveSetting(_ value: Any, forKey key: String) {
        // Save to UserDefaults
        UserDefaults.standard.set(value, forKey: key)
        
        // If iCloud is available, also save to iCloud
        if isCloudAvailable {
            NSUbiquitousKeyValueStore.default.set(value, forKey: key)
            NSUbiquitousKeyValueStore.default.synchronize()
        }
    }
    
    private func loadSetting(forKey key: String) -> Any? {
        // Try to get from iCloud first if available
        if isCloudAvailable, let value = NSUbiquitousKeyValueStore.default.object(forKey: key) {
            return value
        }
        
        // Fall back to UserDefaults
        return UserDefaults.standard.object(forKey: key)
    }
    
    @objc private func ubiquityIdentityChanged(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.syncFromCloud()
        }
    }
    
    private func syncFromCloud() {
        // Only try to sync from cloud if it's available
        if !isCloudAvailable {
            return
        }
        
        print("DEBUG: iCloud available, checking for settings")
        
        // Get values from iCloud if available
        if let cloudAppearanceMode = NSUbiquitousKeyValueStore.default.string(forKey: SettingKeys.appearanceMode),
           let mode = AppearanceMode(rawValue: cloudAppearanceMode) {
            self.appearanceMode = mode
        }
        
        self.iCloudSyncEnabled = NSUbiquitousKeyValueStore.default.bool(forKey: SettingKeys.iCloudSyncEnabled)
        
        if let cloudLanguage = NSUbiquitousKeyValueStore.default.string(forKey: SettingKeys.selectedLanguage),
           let language = AppLanguage(rawValue: cloudLanguage) {
            self.selectedLanguage = language
        }
    }
    
    private func syncSettingsWithCloud() {
        // If iCloud becomes available, push current settings to cloud
        if isCloudAvailable {
            print("DEBUG: iCloud became available, syncing settings")
            saveAppearanceMode()
            saveICloudSyncSetting()
            saveLanguageSetting()
        }
    }
    
    // MARK: - Methods
    func resetAllSettings() {
        appearanceMode = .automatic
        iCloudSyncEnabled = false
        selectedLanguage = .english
    }
    
    func deleteAllData() {
        // This will be implemented to clear all CoreData entities
        // Implementation will depend on your CoreData structure
    }
}

// MARK: - App Settings Enums
enum AppearanceMode: String, CaseIterable, Identifiable {
    case automatic = "automatic"
    case light = "light"
    case dark = "dark"
    
    var id: String { self.rawValue }
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .automatic: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var systemAppearance: ColorScheme? {
        switch self {
        case .automatic: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    // For compatibility with existing code
    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case portuguese = "pt-BR"
    
    var id: String { self.rawValue }
    
    var localizedName: String {
        switch self {
        case .english: return "English"
        case .portuguese: return "Português"
        }
    }
    
    var locale: Locale {
        return Locale(identifier: self.rawValue)
    }
    
    // For compatibility with existing code
    var displayName: String {
        switch self {
        case .english: return "English"
        case .portuguese: return "Português"
        }
    }
}

// Extension on UserSettings for backward compatibility
extension UserSettings {
    // For compatibility with code that expects isDarkMode
    var isDarkMode: Bool {
        get { appearanceMode == .dark }
        set { appearanceMode = newValue ? .dark : .light }
    }
    
    // For compatibility with code that expects currency
    var currency: String {
        get { "USD" } // Default to USD, should be replaced with actual user currency preference
        set { /* No-op for backward compatibility */ }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let languageChanged = Notification.Name("com.logsnap.languageChanged")
    static let iCloudSyncSettingChanged = Notification.Name("com.logsnap.iCloudSyncSettingChanged")
} 