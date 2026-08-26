// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SwiftBoard",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SwiftBoard", targets: ["SwiftBoard"]),
        .library(name: "SwiftBoardServer", targets: ["SwiftBoardServer"]),
        .library(name: "SwiftBoardKit", targets: ["SwiftBoardKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/swhitty/FlyingFox", from: "0.19.0"),
        .package(name: "SwiftDS", path: "../SwiftDS/package")
    ],
    targets: [
        .target(
            name: "SwiftBoard",
            path: "Sources/SwiftBoard"
        ),
        .target(
            name: "SwiftBoardServer",
            dependencies: [
                "SwiftBoard",
                .product(name: "FlyingFox", package: "FlyingFox")
            ],
            path: "Sources/SwiftBoardServer",
            resources: [.copy("Resources")]
        ),
        .executableTarget(
            name: "SwiftBoardDemo",
            dependencies: ["SwiftBoardServer"],
            path: "Sources/SwiftBoardDemo"
        ),
        .target(
            name: "SwiftBoardKit",
            dependencies: [
                "SwiftBoard",
                "SwiftBoardServer",
                .product(name: "SwiftDS", package: "SwiftDS")
            ],
            path: "Sources/SwiftBoardKit"
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
        ),
        .testTarget(
            name: "SwiftBoardTests",
            dependencies: ["SwiftBoard", "SwiftBoardServer"],
            path: "Tests/SwiftBoardTests"
        )
    ]
)
