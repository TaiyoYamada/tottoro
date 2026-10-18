// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "TottoroKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TottoroCore", targets: ["TottoroCore"]),
        .library(name: "TottoroStorage", targets: ["TottoroStorage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.39.0"),
    ],
    targets: [
        .target(
            name: "TottoroCore",
            dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")],
            plugins: [.plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")]
        ),
        .target(
            name: "TottoroStorage",
            dependencies: ["TottoroCore"]
        ),
        .testTarget(
            name: "TottoroCoreTests",
            dependencies: ["TottoroCore"]
        ),
    ]
)
