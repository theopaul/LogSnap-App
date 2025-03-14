# LogSnap

LogSnap is an iOS application built with SwiftUI and CoreData that helps users capture, organize, and manage information through images and structured data.

## Features

- Image capture and storage with optimization
- CoreData integration for structured data management
- iCloud synchronization for cross-device accessibility
- Modern SwiftUI interface with dark mode support
- Comprehensive product, supplier, and contact management

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.5+

## Installation

1. Clone the repository
   ```
   git clone https://github.com/theopaul/LogSnap.git
   ```

2. Open the project in Xcode
   ```
   cd LogSnap
   open LogSnap.xcodeproj
   ```

3. Build and run the application on your device or simulator

## Architecture

LogSnap follows a Model-View-ViewModel (MVVM) architecture:

- **Models**: Core Data entities representing products, suppliers, and contacts
- **Views**: SwiftUI views for user interface components
- **ViewModels**: Intermediary objects that handle business logic and data preparation

## Acknowledgements

- SwiftUI for the user interface
- CoreData for persistent storage
- CloudKit for iCloud synchronization

## License

This project is proprietary and confidential. Unauthorized copying, distribution, or use is strictly prohibited.

© 2024 Theo Santana