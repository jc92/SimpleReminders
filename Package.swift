// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimpleReminders",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SimpleReminders", targets: ["SimpleReminders"]),
    ],
    dependencies: [
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "SimpleReminders",
            dependencies: ["HotKey"],
            path: "Sources/SimpleReminders",
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .define("APPKIT_APP")
            ]
        ),
    ]
)
