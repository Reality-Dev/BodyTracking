// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BodyTracking",
  platforms: [.iOS("15.0")],
  products: [
    .library(name: "BodyTracking", targets: ["BodyTracking"]),
    .library(name: "FaceTracking", targets: ["FaceTracking"]),
    .library(name: "HandTracking", targets: ["HandTracking"])
  ],
  dependencies: [
      .package(name: "RKUtilities", url: "https://github.com/Reality-Dev/RealityKit-Utilities", from: "1.0.0"),
      .package(url: "https://github.com/Reality-Dev/RealityMorpher", branch: "main")
  ],
  targets: [
      .target(name: "BodyTracking",
              dependencies: [.target(name: "BTShared"),
                             .product(name: "RKUtilities", package: "RKUtilities")]),
      .target(name: "FaceTracking",
              dependencies: [.target(name: "BTShared"),
                             .product(name: "RealityMorpher", package: "RealityMorpher"),
                             .product(name: "RKUtilities", package: "RKUtilities")]),
      .target(name: "HandTracking",
              dependencies: [.target(name: "BTShared"),
                             .product(name: "RKUtilities", package: "RKUtilities")]),
      .target(name: "BTShared",
              dependencies: [.product(name: "RKUtilities", package: "RKUtilities")]),
  ],
  swiftLanguageVersions: [.v5]
)
