// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Version: 0.4.1

import PackageDescription

let package = Package(
    name: "RitualistCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RitualistCore",
            type: .static,
            targets: ["RitualistCore"]
        ),
    ],
    dependencies: [
        // No external dependencies for pure domain entities
    ],
    targets: [
        .target(
            name: "RitualistCore",
            dependencies: [],
            path: "Sources/RitualistCore"
        ),
        .testTarget(
            name: "RitualistCoreTests",
            dependencies: ["RitualistCore"],
            path: "Tests/RitualistCoreTests"
        ),
    ]
)
