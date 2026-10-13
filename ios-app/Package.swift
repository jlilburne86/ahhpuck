// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FreedomMobileCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "FreedomMobileCore", targets: ["FreedomMobileCore"])
    ],
    targets: [
        .target(
            name: "FreedomMobileCore",
            path: "Sources/FreedomMobileCore"
        ),
        .testTarget(
            name: "FreedomMobileCoreTests",
            dependencies: ["FreedomMobileCore"],
            path: "Tests/FreedomMobileCoreTests"
        )
    ]
)
