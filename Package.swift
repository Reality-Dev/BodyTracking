// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "BodyTracking",
  platforms: [.iOS("13.0")],
  products: [
    .library(name: "BodyTracking", targets: ["BodyTracking"])
  ],
  dependencies: [],
  targets: [
    .target(name: "BodyTracking", dependencies: [])
  ],
  swiftLanguageVersions: [.v5]
)
