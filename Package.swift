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
        // Dependencies would go here
        // For example:
        // .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "LogSnap",
            dependencies: [],
            path: "LogSnap"),
        .testTarget(
            name: "LogSnapTests",
            dependencies: ["LogSnap"],
            path: "LogSnapTests"),
    ]
)