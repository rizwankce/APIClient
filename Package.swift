// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APIClient",
    platforms: [.iOS(.v15), .macCatalyst(.v15)],
    products: [
        .library(name: "APIClient", targets: ["APIClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WeTransfer/Mocker.git", from: "2.3.0"),
        .package(url: "https://github.com/kean/Pulse", from: "0.20.0")
    ],
    targets: [
        .target(name: "APIClient", dependencies: [.product(name: "PulseCore", package: "Pulse")]),
        .testTarget(name: "APIClientTests", dependencies: ["APIClient", "Mocker"], resources: [.process("Resources")]),
    ]
)
