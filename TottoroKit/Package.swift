// swift-tools-version: 6.2

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
        // 他のアプリの暗号化した書き出しを開く鍵の導出（scrypt と PBKDF2）に使う。CryptoKit にはない
        .package(url: "https://github.com/apple/swift-crypto.git", from: "5.0.1"),
    ],
    targets: [
        .target(
            name: "TottoroCore",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "CryptoExtras", package: "swift-crypto"),
            ],
            plugins: [.plugin(name: "SwiftProtobufPlugin", package: "swift-protobuf")],
        ),
        .target(
            name: "TottoroStorage",
            dependencies: ["TottoroCore"],
        ),
        .testTarget(
            name: "TottoroCoreTests",
            dependencies: ["TottoroCore"],
        ),
    ],
)
