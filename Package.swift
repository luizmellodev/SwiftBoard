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
        .package(url: "https://github.com/luizmellodev/SwiftDS-package", from: "0.1.0")
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
            resources: [.process("Resources")]
        ),
        .target(
            name: "SwiftBoardKit",
            dependencies: [
                "SwiftBoard",
                "SwiftBoardServer",
                .product(name: "SwiftDS", package: "SwiftDS-package")
            ],
            path: "Sources/SwiftBoardKit"
        ),
        .executableTarget(
            name: "SwiftBoardDemo",
            dependencies: ["SwiftBoardServer"],
            path: "Sources/SwiftBoardDemo"
        ),
        .testTarget(
            name: "SwiftBoardTests",
            dependencies: ["SwiftBoard", "SwiftBoardServer"],
            path: "Tests/SwiftBoardTests"
        )
    ]
)
