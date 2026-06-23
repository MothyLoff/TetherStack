// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "TetherStack",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "TetherStack",
            targets: ["TetherStack"]
        ),
    ],
    targets: [
        .target(
            name: "TetherStack"
        ),

    ],
    swiftLanguageModes: [.v6]
)
