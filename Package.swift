// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "fontlift",
    platforms: [
        .macOS(.v12)  // macOS Monterey or later
    ],
    products: [
        // Executable product name defines the installed binary name.
        .executable(name: "fontlift-mac", targets: ["fontlift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "fontlift",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "fontliftTests",
            dependencies: ["fontlift"]
        )
    ]
)
