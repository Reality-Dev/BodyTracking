// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BodyTracking",
  platforms: [.macOS(.v10_15), .iOS("13.0")],
  products: [
    .library(name: "BodyTracking", targets: ["BodyTracking"])
  ],
  dependencies: [
      .package(name: "RKUtilities", url: "https://github.com/Reality-Dev/RealityKit-Utilities", from: "1.0.0"),
  ],
  targets: [
      .target(name: "BodyTracking",
              dependencies: [.product(name: "RKUtilities", package: "RKUtilities")]),
  ],
  swiftLanguageVersions: [.v5]
)
