// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Components",
            targets: ["Components"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jrendel/SwiftKeychainWrapper.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "Components",
            dependencies: ["SwiftKeychainWrapper"])
    ]
) 