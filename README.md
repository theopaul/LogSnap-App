# LogSnap

LogSnap is a bilingual inventory management app designed for tracking products and suppliers. It's built using modern SwiftUI and follows best practices for iOS app development.

## Features

- **Product Management**
  - Add, edit, and delete products
  - Track product details (name, SKU, category, price, dimensions, etc.)
  - Capture and manage product images
  - Search and filter products

- **Supplier Management**
  - Add, edit, and delete suppliers
  - Track supplier details and contact information
  - Quick actions to contact suppliers (email, phone, maps, website)
  - Search and filter suppliers

- **User Experience**
  - Modern, clean SwiftUI interface
  - Dark mode support
  - Bilingual support (English and Portuguese)
  - Responsive design following Apple's Human Interface Guidelines

## Technical Implementation

### Architecture

LogSnap follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: CoreData entities (Product, Supplier)
- **Views**: SwiftUI views for UI representation
- **ViewModels**: Handle business logic and data manipulation

### Components

- **CoreData**: For persistent storage of products and suppliers
- **SwiftUI**: Framework for building the UI
- **Combine**: For reactive programming and data binding
- **Localization**: Full support for English and Portuguese

### Project Structure

```
LogSnap/
├── App/
│   └── LogSnapApp.swift         # Main app entry point
├── Core/
│   ├── Extensions/              # Swift extensions
│   ├── Utilities/               # Helper functions and constants
│   └── Localization/            # Localized strings
├── Data/
│   ├── CoreData/                # Data models and persistence
│   └── Repositories/            # Data access layer
├── Features/
│   ├── Products/                # Product-related features
│   │   ├── Models/
│   │   ├── ViewModels/
│   │   └── Views/
│   └── Suppliers/               # Supplier-related features
│       ├── Models/
│       ├── ViewModels/
│       └── Views/
├── UI/
│   ├── Components/              # Reusable UI components
│   └── Themes/                  # Visual styling
└── Main/
    └── MainTabView.swift        # Main container view
```

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run on your iOS device or simulator

## Usage

1. **Products**: Add and manage your inventory
2. **Suppliers**: Keep track of your suppliers and their contact information
3. **Dark Mode**: Toggle between light and dark mode in the app settings
4. **Language**: Switch between English and Portuguese in the app settings

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Apple's SwiftUI and CoreData frameworks
- The open-source community for inspiration and best practices 