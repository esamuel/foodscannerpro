// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "foodscannerpro",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "Components",
            type: .dynamic,
            targets: ["Components"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jrendel/SwiftKeychainWrapper.git", from: "4.0.1")
    ],
    targets: [
        .target(
            name: "Components",
            dependencies: [
                .product(name: "SwiftKeychainWrapper", package: "SwiftKeychainWrapper")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]),
        .testTarget(
            name: "ComponentsTests",
            dependencies: ["Components"]),
    ]
) 