// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FreedomIOS",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "FreedomMobileCore", targets: ["FreedomMobileCore"])
    ],
    targets: [
        .target(name: "FreedomMobileCore"),
        .testTarget(name: "FreedomMobileCoreTests", dependencies: ["FreedomMobileCore"])
    ]
)
