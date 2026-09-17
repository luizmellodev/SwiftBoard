// swift-tools-version: 5.10
import PackageDescription

/// Maintainer demos for the SwiftBoardKit product (SwiftBoard + SwiftDS).
let package = Package(
    name: "SwiftBoardExamples",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "SwiftBoardKitDemo",
            dependencies: [
                .product(name: "SwiftBoardKit", package: "SwiftBoard")
            ],
            path: "Sources/SwiftBoardKitDemo"
        ),
        .executableTarget(
            name: "SwiftBoardiOSDemo",
            dependencies: [
                .product(name: "SwiftBoardKit", package: "SwiftBoard")
            ],
            path: "Sources/SwiftBoardiOSDemo"
        )
    ]
)
