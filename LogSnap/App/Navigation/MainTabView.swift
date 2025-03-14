import SwiftUI
import UIKit
import AVFoundation
import CoreData

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showPhotoOptions = false
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @EnvironmentObject var userSettings: UserSettings
    @State private var isShowingAnyPresentation = false
    @State private var showCameraAccessAlert = false
    @State private var alertMessage = ""
    
    // Tab item size for consistent spacing
    private let tabItemSize: CGFloat = UIScreen.main.bounds.width / 5
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // DASHBOARD TAB
                NavigationStack {
                    DashboardView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(LocalizedStringKey("Dashboard"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .id("DashboardTab")
                }
                .tabItem {
                    Label(LocalizedStringKey("Dashboard"), systemImage: "house.fill")
                }
                .tag(0)
                
                // PRODUCTS TAB
                NavigationStack {
                    ProductListView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(LocalizedStringKey("Products"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            ToolbarItem(placement: .primaryAction) {
                                Button(action: {
                                    // Create new product
                                    showProductForm()
                                }) {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                        .id("ProductsTab")
                }
                .tabItem {
                    Label(LocalizedStringKey("Products"), systemImage: "shippingbox.fill")
                }
                .tag(1)
                
                // CENTER CAMERA TAB
                NavigationStack {
                    Color.clear // Empty view, we'll handle the camera action directly
                }
                .tabItem {
                    Label(LocalizedStringKey("Camera"), systemImage: "camera.fill")
                }
                .tag(2)
                
                // SUPPLIERS TAB
                NavigationStack {
                    SupplierListView()
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(LocalizedStringKey("Suppliers"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            ToolbarItem(placement: .primaryAction) {
                                Button(action: {
                                    // Create new supplier
                                    showSupplierForm()
                                }) {
                                    Image(systemName: "plus")
                                }
                            }
                        }
                        .id("SuppliersTab")
                }
                .tabItem {
                    Label(LocalizedStringKey("Suppliers"), systemImage: "building.2.fill")
                }
                .tag(3)
                
                // SETTINGS TAB
                NavigationStack {
                    SettingsView(useOwnNavigation: false)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(LocalizedStringKey("Settings"))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .id("SettingsTab")
                }
                .tabItem {
                    Label(LocalizedStringKey("Settings"), systemImage: "gear")
                }
                .tag(4)
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                // Handle center camera tab selection
                if newValue == 2 {
                    // When camera tab is tapped, check permission and show camera
                    selectedTab = oldValue // Keep the previous tab visually selected
                    if !isShowingAnyPresentation {
                        isShowingAnyPresentation = true
                        checkCameraPermissionAndShowOptions()
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            isShowingAnyPresentation = false
        }) {
            SimpleImagePicker(sourceType: imagePickerSourceType, onImageSelected: { image in
                // Move state changes to the next runloop cycle to avoid view update conflicts
                DispatchQueue.main.async {
                    handleCapturedImage(image)
                }
            })
        }
        .actionSheet(isPresented: $showPhotoOptions) {
            // Move state changes to the next runloop cycle
            DispatchQueue.main.async {
                isShowingAnyPresentation = false
            }
            
            return ActionSheet(
                title: Text(LocalizedStringKey("Photo Options")),
                message: Text(LocalizedStringKey("Select photo destination")),
                buttons: [
                    .default(Text(LocalizedStringKey("Product Photo"))) {
                        // Ensure we're not in the middle of a view update
                        DispatchQueue.main.async {
                            handlePhotoCapture(for: .product)
                        }
                    },
                    .default(Text(LocalizedStringKey("Supplier Photo"))) {
                        // Ensure we're not in the middle of a view update
                        DispatchQueue.main.async {
                            handlePhotoCapture(for: .supplier)
                        }
                    },
                    .cancel()
                ]
            )
        }
        .alert(isPresented: $showCameraAccessAlert) {
            Alert(
                title: Text("Camera Access"),
                message: Text(alertMessage),
                primaryButton: .default(Text("Settings")) {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            fixInputAssistantLayout()
        }
        .preferredColorScheme(userSettings.appearanceMode.systemAppearance)
    }
    
    // MARK: - Helper Methods for Forms
    
    private func showProductForm() {
        // Post notification to show the add product form
        NotificationCenter.default.post(name: NSNotification.Name("ShowAddProduct"), object: nil)
    }
    
    private func showSupplierForm() {
        // Post notification to show the add supplier form
        NotificationCenter.default.post(name: NSNotification.Name("ShowAddSupplier"), object: nil)
    }
    
    // MARK: - Camera Handling
    
    private func checkCameraPermissionAndShowOptions() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showPhotoOptions = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showPhotoOptions = true
                    } else {
                        handleCameraAccessDenied()
                    }
                }
            }
        case .denied, .restricted:
            handleCameraAccessDenied()
        @unknown default:
            handleCameraAccessDenied()
        }
    }
    
    private func handleCameraAccessDenied() {
        alertMessage = "Please allow camera access in Settings to take photos."
        showCameraAccessAlert = true
        isShowingAnyPresentation = false
    }
    
    private enum PhotoDestination {
        case product
        case supplier
    }
    
    private func handlePhotoCapture(for destination: PhotoDestination) {
        // Safety check to prevent multiple presentations
        guard !isShowingAnyPresentation else { return }
        
        // Switch to appropriate tab first
        withAnimation {
            switch destination {
            case .product:
                selectedTab = 1
            case .supplier:
                selectedTab = 3
            }
        }
        
        // Set flag to prevent multiple presentations
        isShowingAnyPresentation = true
        
        // Add a brief delay to allow the tab transition to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Check if we're running on simulator
            #if targetEnvironment(simulator)
            self.imagePickerSourceType = .photoLibrary
            #else
            // Default to photo library which is more reliable
            self.imagePickerSourceType = .photoLibrary
            
            // Only use camera if it's actually available
            if UIImagePickerController.isSourceTypeAvailable(.camera) &&
               AVCaptureDevice.authorizationStatus(for: .video) == .authorized {
                self.imagePickerSourceType = .camera
            }
            #endif
            
            // Present with a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showImagePicker = true
            }
        }
    }
    
    // MARK: - Helper Methods for Keyboard & Presentations
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func fixInputAssistantLayout() {
        // Only set up observers once to avoid duplication
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Small delay to ensure views are fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.adjustInputAssistantConstraints()
            }
        }
    }
    
    private func adjustInputAssistantConstraints() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }
        
        if let assistantView = findInputAssistantView(in: keyWindow) {
            // Remove existing constraints that might cause conflicts
            let constraintsToRemove = assistantView.constraints.filter { constraint in
                return constraint.identifier == "assistantHeight" || 
                       (constraint.firstAttribute == .height && constraint.firstItem === assistantView) ||
                       constraint.identifier == "fixedAssistantHeight"
            }
            
            constraintsToRemove.forEach { $0.isActive = false }
            
            // Add multiple constraints with appropriate priorities to ensure stability
            assistantView.translatesAutoresizingMaskIntoConstraints = false
            
            // Set minimum height constraint with high priority
            let minHeightConstraint = NSLayoutConstraint(
                item: assistantView,
                attribute: .height,
                relatedBy: .greaterThanOrEqual,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 44
            )
            minHeightConstraint.priority = .defaultHigh
            minHeightConstraint.identifier = "minAssistantHeight"
            minHeightConstraint.isActive = true
            
            // Set maximum height constraint with medium priority
            let maxHeightConstraint = NSLayoutConstraint(
                item: assistantView,
                attribute: .height,
                relatedBy: .lessThanOrEqual,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 60
            )
            maxHeightConstraint.priority = .defaultLow + 1
            maxHeightConstraint.identifier = "maxAssistantHeight"
            maxHeightConstraint.isActive = true
            
            // Set preferred height constraint with lowest priority
            let preferredHeightConstraint = NSLayoutConstraint(
                item: assistantView,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 44
            )
            preferredHeightConstraint.priority = .defaultLow
            preferredHeightConstraint.identifier = "preferredAssistantHeight"
            preferredHeightConstraint.isActive = true
            
            // Force layout to apply constraints immediately
            assistantView.layoutIfNeeded()
        }
    }
    
    private func findInputAssistantView(in view: UIView) -> UIView? {
        // Set a reasonable recursion limit to prevent stack overflow
        return findInputAssistantViewWithLimit(in: view, limit: 10)
    }
    
    private func findInputAssistantViewWithLimit(in view: UIView, limit: Int) -> UIView? {
        if limit <= 0 { return nil }
        
        let viewClassName = NSStringFromClass(type(of: view))
        if viewClassName.contains("SystemInputAssistantView") {
            return view
        }
        
        for subview in view.subviews {
            if let found = findInputAssistantViewWithLimit(in: subview, limit: limit - 1) {
                return found
            }
        }
        
        return nil
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        // Validate image to prevent invalid values
        guard image.size.width > 0, image.size.height > 0,
              !image.size.width.isNaN, !image.size.height.isNaN else {
            print("Invalid image dimensions detected, skipping processing")
            return
        }
        
        // Process image on a background queue to avoid UI freezes
        DispatchQueue.global(qos: .userInitiated).async {
            // Normalize image size if needed
            let processedImage = self.ensureValidImage(image)
            
            // Post notification with captured image on main thread
            DispatchQueue.main.async {
                // Determine which notification to send based on tab
                let notificationName = self.selectedTab == 1 ? "ShowAddProduct" : "ShowAddSupplier"
                
                // Only post image notification if we have a valid image
                if processedImage.size.width > 0 && processedImage.size.height > 0 {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NewPhotoAvailable"),
                        object: nil,
                        userInfo: ["image": processedImage]
                    )
                }
                
                // Post the notification to show the appropriate form
                NotificationCenter.default.post(name: NSNotification.Name(notificationName), object: nil)
                
                // Wait for the navigation to complete before continuing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isShowingAnyPresentation = false
                }
            }
        }
    }
    
    // Helper to ensure image is properly formatted to avoid constraint issues
    private func ensureValidImage(_ image: UIImage) -> UIImage {
        // More robust guard against invalid images
        guard image.size.width > 0, image.size.height > 0,
              !image.size.width.isNaN, !image.size.height.isNaN,
              image.size.width.isFinite, image.size.height.isFinite,
              image.cgImage != nil || image.ciImage != nil else {
            print("Invalid image detected, returning placeholder")
            // Create a small valid placeholder with consistent dimensions
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
            return renderer.image { ctx in
                UIColor.gray.setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            }
        }
        
        // Fix orientation with improved error handling
        var correctedImage = image
        if correctedImage.imageOrientation != .up {
            autoreleasepool {
                UIGraphicsBeginImageContextWithOptions(correctedImage.size, false, correctedImage.scale)
                defer { UIGraphicsEndImageContext() }
                
                correctedImage.draw(in: CGRect(origin: .zero, size: correctedImage.size))
                if let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() {
                    if normalizedImage.size.width > 0 && normalizedImage.size.height > 0 {
                        correctedImage = normalizedImage
                    }
                }
            }
        }
        
        // Resize if too large (prevents layout constraint issues)
        let maxDimension: CGFloat = 1200 // Reduce from 1500 to improve performance
        if correctedImage.size.width > maxDimension || correctedImage.size.height > maxDimension {
            // Calculate aspect ratio with safety checks
            var aspectRatio: CGFloat = 1.0
            if correctedImage.size.height > 0 {
                aspectRatio = correctedImage.size.width / correctedImage.size.height
            }
            
            // Guard against invalid aspect ratio with a fallback
            if !aspectRatio.isFinite || aspectRatio.isNaN || aspectRatio <= 0 {
                aspectRatio = 1.0
                print("Invalid aspect ratio detected, using 1.0 as fallback")
            }
            
            // Calculate new size with safety limits
            var newSize: CGSize
            if correctedImage.size.width > correctedImage.size.height {
                newSize = CGSize(width: maxDimension, height: max(1, maxDimension / aspectRatio))
            } else {
                newSize = CGSize(width: max(1, maxDimension * aspectRatio), height: maxDimension)
            }
            
            // Enforce size limits to prevent massive images
            newSize.width = min(newSize.width, 2400)
            newSize.height = min(newSize.height, 2400)
            
            // Final validation of dimensions
            if !newSize.width.isFinite || newSize.width.isNaN || newSize.width <= 0 ||
               !newSize.height.isFinite || newSize.height.isNaN || newSize.height <= 0 {
                print("Invalid new dimensions calculated, returning original image")
                return correctedImage
            }
            
            // Resize the image with improved error handling - returning directly to fix missing return error
            let resizedImage = autoreleasepool {
                UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                defer { UIGraphicsEndImageContext() }
                
                correctedImage.draw(in: CGRect(origin: .zero, size: newSize))
                
                return UIGraphicsGetImageFromCurrentImageContext()
            }
            
            // Combined conditions for better code clarity
            if let validResizedImage = resizedImage, 
               validResizedImage.size.width > 0,
               validResizedImage.size.height > 0 {
                return validResizedImage
            }
        }
        
        // Default return path - always returns the original corrected image if resizing fails
        return correctedImage // This is our fallback return
    }
}

struct MainTabView_Previews: PreviewProvider {
    // Create required dependencies explicitly for the preview
    static let previewUserSettings: UserSettings = {
        let settings = UserSettings()
        // Initialize with default values for preview
        settings.appearanceMode = .light
        settings.iCloudSyncEnabled = false
        settings.selectedLanguage = .english
        return settings
    }()
    
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, CoreDataManager.previewContext)
            .environment(\.locale, .init(identifier: "en"))
            .environmentObject(previewUserSettings)
            .previewDisplayName("English")
    }
} 
