// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BodyTracking",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "BodyTracking", targets: ["BodyTracking"]),
        .library(name: "FaceTracking", targets: ["FaceTracking"]),
        .library(name: "HandTracking", targets: ["HandTracking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Reality-Dev/RealityKit-Utilities", from: "1.0.0"),
        .package(url: "https://github.com/Reality-Dev/RealityMorpher", exact: "2.0.11"),
    ],
    targets: [
        .target(name: "BodyTracking",
                dependencies: [.target(name: "BTShared"),
                               .product(name: "RKUtilities", package: "RealityKit-Utilities")]),
        .target(name: "FaceTracking",
                dependencies: [.target(name: "BTShared"),
                               .product(name: "RealityMorpher", package: "RealityMorpher"),
                               .product(name: "RKUtilities", package: "RealityKit-Utilities")]),
        .target(name: "HandTracking",
                dependencies: [.target(name: "BTShared"),
                               .product(name: "RKUtilities", package: "RealityKit-Utilities")]),
        .target(name: "BTShared",
                dependencies: [.product(name: "RKUtilities", package: "RealityKit-Utilities")]),
    ],
    swiftLanguageVersions: [.v5]
)
