// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "RokketaKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "RokketaCore", targets: ["RokketaCore"]),
        .library(name: "RokketaStorage", targets: ["RokketaStorage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.39.0"),
    ],
    targets: [
        .target(
            name: "RokketaCore",
            dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")],
            plugins: [.plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")]
        ),
        .target(
            name: "RokketaStorage",
            dependencies: ["RokketaCore"]
        ),
        .testTarget(
            name: "RokketaCoreTests",
            dependencies: ["RokketaCore"]
        ),
    ]
)
