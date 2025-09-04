
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YXTNetworking",
    platforms: [
        .iOS(.v14), .macOS(.v12)
    ],
    products: [
        .library(name: "YXTNetworking", targets: ["YXTNetworking"])
    ],
    targets: [
        .target(name: "YXTNetworking", path: "Sources")
    ]
)
