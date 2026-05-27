// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ScreenSwap",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ScreenSwapCore",
            targets: ["ScreenSwapCore"]
        ),
        .executable(
            name: "ScreenSwapApp",
            targets: ["ScreenSwapApp"]
        )
    ],
    targets: [
        .target(
            name: "ScreenSwapCore"
        ),
        .executableTarget(
            name: "ScreenSwapApp",
            dependencies: ["ScreenSwapCore"]
        ),
        .testTarget(
            name: "ScreenSwapCoreTests",
            dependencies: ["ScreenSwapCore"]
        )
    ]
)
