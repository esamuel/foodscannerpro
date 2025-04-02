// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Components",
            targets: ["Components"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jrendel/SwiftKeychainWrapper.git", from: "4.0.1"),
    ],
    targets: [
        .target(
            name: "Components",
            dependencies: ["SwiftKeychainWrapper"]),
        .testTarget(
            name: "ComponentsTests",
            dependencies: ["Components"]),
    ]
) 