# LogSnap

LogSnap is a bilingual inventory management app designed for tracking products and suppliers. It's built using modern SwiftUI and follows best practices for iOS app development.

<p align="center">
  <img src="LogSnap/Resources/Assets.xcassets/logo.imageset/logo.png" alt="LogSnap Logo" width="200">
</p>

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

## Getting Started

### Prerequisites

- Xcode 13.0 or later
- iOS 15.0+ target deployment
- Swift 5.5+
- Git (for cloning the repository)

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/LogSnap.git
   ```

2. Open the project in Xcode:
   ```
   open LogSnap.xcodeproj
   ```
   
   Or double-click the LogSnap.xcodeproj file in Finder.

3. Build and run on your iOS device or simulator (⌘+R)

### Troubleshooting

If you encounter issues opening or building the project:

- Choose Product > Clean Build Folder (Shift+⌘+K) and build again
- Ensure you're using a compatible Xcode version (13.0+)
- Check that the LogSnap.xcdatamodeld file is properly included
- Verify Info.plist paths are correct in build settings

## Project Structure

The project follows a feature-based architecture with MVVM pattern:

```
LogSnap/
├── App/
│   ├── AppDelegate.swift        # App lifecycle management
│   ├── SceneDelegate.swift      # UI scene lifecycle
│   ├── LogSnapApp.swift         # SwiftUI app entry point
│   └── Navigation/              # App navigation components
├── Features/
│   ├── Products/                # Product management feature
│   │   ├── Views/               # SwiftUI views
│   │   └── ViewModels/          # ViewModels for product features
│   ├── Suppliers/               # Supplier management feature
│   │   ├── Views/               # SwiftUI views
│   │   └── ViewModels/          # ViewModels for supplier features
│   ├── Contacts/                # Contact management feature
│   ├── Dashboard/               # App dashboard feature
│   └── Settings/                # App settings feature
├── Services/
│   ├── CoreDataService/         # CoreData implementation
│   └── [Other services]         # Authentication, networking, etc.
├── Components/
│   ├── Buttons/                 # Reusable button components
│   └── CustomViews/             # Reusable UI components
├── Utils/
│   └── Extensions/              # Swift extensions
└── Resources/
    ├── Assets.xcassets/         # Images and assets
    ├── Info.plist               # App configuration
    └── [Other resources]        # Localization files, etc.
```

## Architecture

LogSnap follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: CoreData entities represent the data layer
- **Views**: SwiftUI views handle UI presentation 
- **ViewModels**: Manage business logic and prepare data for views

### Key Components

- **CoreData**: For persistent storage of products and suppliers
- **SwiftUI**: Framework for building the UI
- **Combine**: For reactive programming and data binding
- **Localization**: Full support for English and Portuguese

## Development Guidelines

1. **Feature-First Organization**: Group files by feature, not by type
2. **Separation of Concerns**: Keep UI and business logic separate
3. **Component Reusability**: Make UI components reusable when possible
4. **Consistent Naming**: Follow Apple's naming conventions
5. **SOLID Principles**: Follow software design principles

### Adding New Features

When adding a new feature:

1. Create a new folder in the Features directory
2. Add Views/ and ViewModels/ subdirectories
3. Implement UI in SwiftUI views
4. Implement business logic in ViewModels
5. Share common components by placing them in the Components directory

## Usage

1. **Products**: Add and manage your inventory
2. **Suppliers**: Keep track of your suppliers and their contact information
3. **Contacts**: Manage contact information for people at supplier companies
4. **Dashboard**: View key metrics about your inventory
5. **Settings**: Configure app preferences, language, and appearance

## Xcode Cloud Setup (Optional)

If you're using Xcode Cloud for CI/CD:

1. In Xcode, go to Product > Xcode Cloud
2. Set up a workflow for your app
3. Configure build settings as needed
4. Set up testing, archiving, and distribution actions

Refer to Apple's [Xcode Cloud documentation](https://developer.apple.com/documentation/xcode/xcode-cloud) for more details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Apple's SwiftUI and CoreData frameworks
- The open-source community for inspiration and best practices 