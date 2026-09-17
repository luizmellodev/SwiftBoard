// swift-tools-version: 5.10
import PackageDescription

/// Maintainer-only package: SwiftDS demos. The published SwiftBoard package does not
/// depend on SwiftDS. Requires a sibling checkout at ../../SwiftDS/package.
let package = Package(
    name: "SwiftBoardExamples",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SwiftBoardKit", targets: ["SwiftBoardKit"])
    ],
    dependencies: [
        .package(path: ".."),
        .package(name: "SwiftDS", path: "../../SwiftDS/package")
    ],
    targets: [
        .target(
            name: "SwiftBoardKit",
            dependencies: [
                .product(name: "SwiftBoard", package: "SwiftBoard"),
                .product(name: "SwiftBoardServer", package: "SwiftBoard"),
                .product(name: "SwiftDS", package: "SwiftDS")
            ],
            path: ".",
            exclude: ["Package.swift", "README.md", "Sources"],
            sources: ["SwiftDSCatalogRegistrar.swift"]
        ),
        .executableTarget(
            name: "SwiftBoardKitDemo",
            dependencies: ["SwiftBoardKit"],
            path: "Sources/SwiftBoardKitDemo"
        ),
        .executableTarget(
            name: "SwiftBoardiOSDemo",
            dependencies: ["SwiftBoardKit"],
            path: "Sources/SwiftBoardiOSDemo"
        )
    ]
)
