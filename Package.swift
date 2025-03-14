// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LogSnap",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "LogSnap",
            targets: ["LogSnap"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // You can add external dependencies here if needed
        // For example:
        // .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.1")),
    ],
    targets: [
        .target(
            name: "LogSnap",
            dependencies: [
                // Add any dependencies from above, e.g., "Alamofire"
            ],
            path: "LogSnap",
            exclude: [
                // Files to exclude from the package (if any)
                "Preview Content"
            ],
            resources: [
                // Include any resources needed by the package
                .process("Resources/Assets.xcassets")
            ]),
        .testTarget(
            name: "LogSnapTests",
            dependencies: ["LogSnap"],
            path: "LogSnapTests"),
    ],
    swiftLanguageVersions: [.v5]
)