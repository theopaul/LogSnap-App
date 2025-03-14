import SwiftUI
import MessageUI

// No need for these extensions since we'll use the ones from the UserSettings model
// Removing to fix redeclaration errors

struct SettingsView: View {
    @EnvironmentObject var userSettings: UserSettings
    @StateObject private var mailViewModel = MailViewModel()
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - View State
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var showingExportOptionsSheet = false
    @State private var exportType: ExportType = .csv
    @State private var exportFor: ExportCategory = .products
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingICloudAlert = false
    
    // Flag to check if this view should provide its own NavigationView
    var useOwnNavigation = true
    
    var body: some View {
        Group {
            if useOwnNavigation {
                NavigationView {
                    settingsContent
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else {
                settingsContent
            }
        }
        .preferredColorScheme(userSettings.appearanceMode.systemAppearance)
    }
    
    private var settingsContent: some View {
        List {
            // MARK: - Appearance & Language Section
            Section {
                // Appearance setting
                NavigationLink(destination: AppearanceSettingView(userSettings: userSettings)) {
                    SettingRow(
                        icon: "paintbrush",
                        iconColor: .purple,
                        title: "Appearance",
                        value: userSettings.appearanceMode.displayName,
                        isInNavigationLink: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Language setting
                NavigationLink(destination: LanguageSettingView(userSettings: userSettings)) {
                    SettingRow(
                        icon: "globe",
                        iconColor: .blue,
                        title: "Language",
                        value: userSettings.selectedLanguage.displayName,
                        isInNavigationLink: true
                    )
                }
                .buttonStyle(PlainButtonStyle())
            } header: {
                Text(LocalizedStringKey("Appearance & Language"))
            }
            
            // MARK: - Sync & Export Section
            Section {
                // iCloud Sync toggle
                Toggle(isOn: $userSettings.iCloudSyncEnabled) {
                    SettingRow(
                        icon: "cloud",
                        iconColor: .blue,
                        title: "iCloud Sync",
                        hideChevron: true
                    )
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: userSettings.iCloudSyncEnabled) { oldValue, newValue in
                    if oldValue != newValue {
                        showingICloudAlert = true
                    }
                }
                
                if userSettings.iCloudSyncEnabled {
                    Text("Data will be synchronized across your devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 42)
                }
                
                // Export to CSV
                Button(action: {
                    Task {
                        viewModel.exportProductsToCSV()
                    }
                }) {
                    SettingRow(
                        icon: "doc.text",
                        iconColor: .green,
                        title: "Export to CSV"
                    )
                }
                
                // Export to Excel
                Button(action: {
                    Task {
                        viewModel.exportProductsToExcel()
                    }
                }) {
                    SettingRow(
                        icon: "tablecells",
                        iconColor: .green,
                        title: "Export to Excel"
                    )
                }
                
                // Delete All Data
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    SettingRow(
                        icon: "trash",
                        iconColor: .red,
                        title: "Delete All Data",
                        titleColor: .red
                    )
                }
            } header: {
                Text(LocalizedStringKey("Sync & Export"))
            }
            
            // MARK: - Help & Support Section
            Section {
                // Review on App Store
                Button(action: { writeReview() }) {
                    SettingRow(
                        icon: "star",
                        iconColor: .yellow,
                        title: "Review on App Store",
                        showExternalLinkIcon: true
                    )
                }
                
                // Contact via Email
                Button(action: {
                    mailViewModel.sendEmail(subject: "LogSnap App - Support Request")
                }) {
                    SettingRow(
                        icon: "envelope",
                        iconColor: .blue,
                        title: "Contact via Email",
                        showExternalLinkIcon: true
                    )
                }
                .disabled(!mailViewModel.canSendMail)
                .opacity(mailViewModel.canSendMail ? 1 : 0.6)
                
                // Get Support
                Button(action: { getSupport() }) {
                    SettingRow(
                        icon: "questionmark.circle",
                        iconColor: .orange,
                        title: "Get Support",
                        showExternalLinkIcon: true
                    )
                }
                
                // Share App
                Button(action: { showShareSheet = true }) {
                    SettingRow(
                        icon: "square.and.arrow.up",
                        iconColor: .blue,
                        title: "Share App",
                        showExternalLinkIcon: true
                    )
                }
            } header: {
                Text(LocalizedStringKey("Help & Support"))
            }
            
            // MARK: - About Section
            Section {
                // App Version
                HStack {
                    Text(LocalizedStringKey("App Version"))
                    Spacer()
                    Text(getAppVersion())
                        .foregroundColor(.secondary)
                }
                
                // Privacy Policy
                NavigationLink(destination: PrivacyPolicyView()) {
                    Text(LocalizedStringKey("Privacy Policy"))
                }
                
                // Terms of Use
                NavigationLink(destination: TermsOfUseView()) {
                    Text(LocalizedStringKey("Terms of Use"))
                }
            } header: {
                Text(LocalizedStringKey("About"))
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(loadingOverlay)
        .alert(isPresented: $showDeleteConfirmation) {
            deleteConfirmationAlert
        }
        .actionSheet(isPresented: $showingExportOptionsSheet) {
            getExportActionSheet()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [getAppShareText()])
        }
        .sheet(isPresented: $mailViewModel.isShowingMailView) {
            MailView(
                result: $mailViewModel.result,
                subject: mailViewModel.subject,
                recipients: ["support@logsnap.com"]
            )
        }
        .onChange(of: viewModel.exportResult) { _, newValue in
            if let result = newValue {
                showExportResult(result)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(LocalizedStringKey(alertTitle)),
                message: Text(LocalizedStringKey(alertMessage)),
                dismissButton: .default(Text(LocalizedStringKey("OK")))
            )
        }
        .alert(isPresented: $showingICloudAlert) {
            Alert(
                title: Text(LocalizedStringKey("iCloud Sync Setting Changed")),
                message: Text(LocalizedStringKey("Please restart the app for the iCloud sync changes to take effect.")),
                dismissButton: .default(Text(LocalizedStringKey("OK")))
            )
        }
    }
    
    // MARK: - Loading Overlay
    private var loadingOverlay: some View {
        Group {
            if viewModel.isExporting {
                ProgressView(LocalizedStringKey("Exporting..."))
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Alerts and Action Sheets
    private var deleteConfirmationAlert: Alert {
        Alert(
            title: Text(LocalizedStringKey("Delete All Data")),
            message: Text(LocalizedStringKey("Are you sure you want to delete all data? This action cannot be undone.")),
            primaryButton: .destructive(Text(LocalizedStringKey("Delete"))) {
                viewModel.deleteAllData()
            },
            secondaryButton: .cancel()
        )
    }
    
    // MARK: - Action Sheets
    private func getExportActionSheet() -> ActionSheet {
        let exportTypeDesc = exportType == .csv ? "CSV" : "Excel"
        
        return ActionSheet(
            title: Text(LocalizedStringKey("Export Options")),
            message: Text(LocalizedStringKey("Choose what to export to \(exportTypeDesc)")),
            buttons: [
                .default(Text(LocalizedStringKey("All Products"))) {
                    Task {
                        if exportType == .csv {
                            viewModel.exportProductsToCSV()
                        } else {
                            viewModel.exportProductsToExcel()
                        }
                    }
                },
                .default(Text(LocalizedStringKey("All Suppliers"))) {
                    Task {
                        if exportType == .csv {
                            viewModel.exportSuppliersToCSV()
                        } else {
                            viewModel.exportSuppliersToExcel()
                        }
                    }
                },
                .cancel()
            ]
        )
    }
    
    // MARK: - Helper Functions
    private func getAppVersion() -> String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private func getAppShareText() -> String {
        return "Check out LogSnap - a powerful app for tracking your inventory! Download it now: https://apps.apple.com/app/logsnap/id123456789"
    }
    
    private func exportProducts() {
        Task {
            if exportType == .csv {
                viewModel.exportProductsToCSV()
            } else {
                viewModel.exportProductsToExcel()
            }
        }
    }
    
    private func exportSuppliers() {
        Task {
            if exportType == .csv {
                viewModel.exportSuppliersToCSV()
            } else {
                viewModel.exportSuppliersToExcel()
            }
        }
    }
    
    private func showExportResult(_ result: ExportResult) {
        if result.success, let fileURL = result.fileURL {
            // Create a temporary copy of the file in a more accessible location
            let tempURL = createAccessibleCopy(of: fileURL)
            
            // Present activity view controller to share the file on the main thread
            DispatchQueue.main.async {
                self.presentShareSheet(for: tempURL ?? fileURL)
            }
        } else {
            // Show error alert
            let errorMessage = result.errorMessage ?? "Unknown error occurred during export."
            showErrorAlert(message: errorMessage)
        }
    }
    
    private func createAccessibleCopy(of fileURL: URL) -> URL? {
        // Create a temporary directory URL that's accessible to other apps
        guard let tempDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let tempFileURL = tempDir.appendingPathComponent(fileURL.lastPathComponent)
        
        // Try to copy the file to the accessible location
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: tempFileURL.path) {
                try FileManager.default.removeItem(at: tempFileURL)
            }
            
            try FileManager.default.copyItem(at: fileURL, to: tempFileURL)
            return tempFileURL
        } catch {
            print("Error creating accessible copy: \(error)")
            return nil
        }
    }
    
    private func presentShareSheet(for fileURL: URL) {
        // Ensure we're on the main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.presentShareSheet(for: fileURL)
            }
            return
        }
        
        // Create activity items
        let activityItems: [Any] = [fileURL]
        
        // Use UIApplication.shared.windows approach which is safer
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Cannot present share sheet: No root view controller found")
            return
        }
        
        // Find the topmost presented view controller
        let topmostViewController = findTopmostViewController(rootViewController)
        
        // Create and configure the activity view controller
        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // iPad configuration to prevent crashes
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = topmostViewController.view
            popoverController.sourceRect = CGRect(x: topmostViewController.view.bounds.midX,
                                                  y: topmostViewController.view.bounds.midY,
                                                  width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        // Present the view controller
        topmostViewController.present(activityViewController, animated: true)
    }
    
    private func findTopmostViewController(_ viewController: UIViewController) -> UIViewController {
        if let presented = viewController.presentedViewController {
            return findTopmostViewController(presented)
        }
        
        // For tab bar controllers, find the selected view controller
        if let tabBarController = viewController as? UITabBarController,
           let selected = tabBarController.selectedViewController {
            return findTopmostViewController(selected)
        }
        
        // For navigation controllers, find the visible view controller
        if let navigationController = viewController as? UINavigationController,
           let visible = navigationController.visibleViewController {
            return findTopmostViewController(visible)
        }
        
        return viewController
    }
    
    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            // Create a SwiftUI alert that doesn't conflict with other presentations
            self.alertTitle = "Export Failed"
            self.alertMessage = message
            self.showAlert = true
        }
    }
    
    private func writeReview() {
        // This would open the App Store review page
        if let writeReviewURL = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(writeReviewURL)
        }
    }
    
    private func getSupport() {
        // This would open the support website
        if let supportURL = URL(string: "https://www.logsnap.com/support") {
            UIApplication.shared.open(supportURL)
        }
    }
}

// MARK: - Setting Row Component (Fixed)
struct SettingRow: View {
    var icon: String
    var iconColor: Color
    var title: String
    var value: String? = nil
    var titleColor: Color = .primary
    var showExternalLinkIcon: Bool = false
    var hideChevron: Bool = false
    var isInNavigationLink: Bool = false  // New property to handle NavigationLink usage
    
    var body: some View {
        HStack {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            
            // Title
            Text(LocalizedStringKey(title))
                .foregroundColor(titleColor)
                .padding(.leading, 8)
            
            Spacer()
            
            // Value if provided
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            }
            
            // External link icon if needed
            if showExternalLinkIcon {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
            // Only show chevron if not hidden AND not in a NavigationLink
            else if !hideChevron && !isInNavigationLink {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Sub-Settings Views
struct AppearanceSettingView: View {
    @ObservedObject var userSettings: UserSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        List {
            ForEach(AppearanceMode.allCases, id: \.id) { mode in
                Button(action: {
                    withAnimation {
                        userSettings.appearanceMode = mode
                    }
                }) {
                    HStack {
                        Text(mode.localizedName)
                        Spacer()
                        if userSettings.appearanceMode == mode {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(userSettings.appearanceMode.systemAppearance)
    }
}

struct LanguageSettingView: View {
    @ObservedObject var userSettings: UserSettings
    
    var body: some View {
        List {
            ForEach(AppLanguage.allCases, id: \.id) { language in
                Button(action: {
                    withAnimation {
                        userSettings.selectedLanguage = language
                    }
                }) {
                    HStack {
                        Text(language.localizedName)
                        Spacer()
                        if userSettings.selectedLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Export Types
enum ExportType {
    case csv
    case excel
}

enum ExportCategory {
    case products
    case suppliers
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView()
                .environmentObject(UserSettings())
                .environment(\.locale, .init(identifier: "en"))
            
            SettingsView()
                .environmentObject(UserSettings())
                .environment(\.locale, .init(identifier: "pt-BR"))
                .previewDisplayName("Portuguese")
        }
    }
}
