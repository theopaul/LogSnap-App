import Foundation
import UIKit
import AVFoundation

// Helper class to manage camera configuration and compatibility
class CameraConfigHelper {
    static let shared = CameraConfigHelper()
    
    // Device identification properties
    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    // Check if current device has multiple back cameras (Wide/Ultra-wide)
    var hasMultipleBackCameras: Bool {
        if #available(iOS 13.0, *) {
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera],
                mediaType: .video,
                position: .back)
            return discoverySession.devices.count > 1
        }
        return false
    }
    
    // Check if device requires special camera handling
    var requiresSpecialCameraHandling: Bool {
        // iPhone 11, 12, 13, 14 series and newer often need special handling
        // due to their multiple camera configurations
        
        // These models have a BackWide camera that sometimes causes issues
        let specialModelIdentifiers = [
            "iPhone12,1", "iPhone12,3", "iPhone12,5", // iPhone 11 series
            "iPhone13,1", "iPhone13,2", "iPhone13,3", "iPhone13,4", // iPhone 12 series
            "iPhone14,2", "iPhone14,3", "iPhone14,4", "iPhone14,5", // iPhone 13 series
            "iPhone14,7", "iPhone14,8", "iPhone15,2", "iPhone15,3", // iPhone 14 series
            "iPhone15,4", "iPhone15,5", "iPhone16,1", "iPhone16,2"  // iPhone 15 series
        ]
        
        return specialModelIdentifiers.contains(deviceModel) || hasMultipleBackCameras
    }
    
    // Configure the image picker controller based on device capabilities
    func configureImagePicker(_ picker: UIImagePickerController) {
        guard picker.sourceType == .camera else { return }
        
        // Basic configuration for all devices
        picker.cameraCaptureMode = .photo
        picker.cameraFlashMode = .auto
        
        // Special handling for devices with multiple cameras
        if requiresSpecialCameraHandling {
            // Don't set a specific cameraDevice - let system choose
            // This avoids "Unsupported Device Mode" errors
            
            // Additional settings to improve compatibility
            picker.modalPresentationStyle = .fullScreen
            
            // Support all available media types
            picker.mediaTypes = ["public.image"]
            picker.videoQuality = .typeHigh
            
            // Log detected configuration
            print("DEBUG: Using special camera configuration for device: \(deviceModel)")
        } else {
            // For older devices, we can use standard settings
            if UIImagePickerController.isCameraDeviceAvailable(.rear) {
                picker.cameraDevice = .rear
            }
            print("DEBUG: Using standard camera configuration")
        }
    }
    
    // Detect camera orientation issues and apply fixes
    func checkForOrientationIssues() -> Bool {
        // This was a common issue on iOS 14 and earlier
        if #available(iOS 15.0, *) {
            return false // iOS 15+ handles this better
        }
        
        // Check if device is in an orientation that might cause camera issues
        let currentOrientation = UIDevice.current.orientation
        let incompatibleOrientations: [UIDeviceOrientation] = [
            .landscapeLeft, .landscapeRight, .portraitUpsideDown
        ]
        
        return incompatibleOrientations.contains(currentOrientation) && requiresSpecialCameraHandling
    }
    
    // Get a user-friendly device name for debugging
    var userFriendlyDeviceName: String {
        let deviceName: String
        
        switch deviceModel {
        case "iPhone12,1": deviceName = "iPhone 11"
        case "iPhone12,3": deviceName = "iPhone 11 Pro"
        case "iPhone12,5": deviceName = "iPhone 11 Pro Max"
        case "iPhone13,1": deviceName = "iPhone 12 mini"
        case "iPhone13,2": deviceName = "iPhone 12"
        case "iPhone13,3": deviceName = "iPhone 12 Pro"
        case "iPhone13,4": deviceName = "iPhone 12 Pro Max"
        case "iPhone14,2": deviceName = "iPhone 13 Pro"
        case "iPhone14,3": deviceName = "iPhone 13 Pro Max"
        case "iPhone14,4": deviceName = "iPhone 13 mini"
        case "iPhone14,5": deviceName = "iPhone 13"
        case "iPhone14,7": deviceName = "iPhone 14"
        case "iPhone14,8": deviceName = "iPhone 14 Plus"
        case "iPhone15,2": deviceName = "iPhone 14 Pro"
        case "iPhone15,3": deviceName = "iPhone 14 Pro Max"
        case "iPhone15,4": deviceName = "iPhone 15"
        case "iPhone15,5": deviceName = "iPhone 15 Plus"
        case "iPhone16,1": deviceName = "iPhone 15 Pro"
        case "iPhone16,2": deviceName = "iPhone 15 Pro Max"
        default: deviceName = "Unknown iPhone (\(deviceModel))"
        }
        
        return deviceName
    }
} 