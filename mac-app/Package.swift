// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FreedomMac",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "FreedomCore", targets: ["FreedomCore"]),
        .executable(name: "freedom-cli", targets: ["FreedomCLI"])
    ],
    targets: [
        .target(name: "FreedomCore"),
        .executableTarget(name: "FreedomCLI", dependencies: ["FreedomCore"]),
        .testTarget(name: "FreedomCoreTests", dependencies: ["FreedomCore"])
    ]
)
