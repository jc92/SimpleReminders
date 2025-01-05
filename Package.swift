// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SimpleReminders",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SimpleReminders",
            targets: ["SimpleReminders"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "SimpleReminders",
            path: "Sources/SimpleReminders",
            swiftSettings: [
                .define("APPKIT_APP")
            ]
        )
    ]
)
