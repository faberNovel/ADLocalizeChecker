// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalizeChecker",
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "LocalizeChecker",
            dependencies: ["LocalizeCheckerCore", "Commander"]
        ),
        .target(name: "LocalizeCheckerCore"),
        .testTarget(
            name: "LocalizeCheckerCoreTests",
            dependencies: ["LocalizeCheckerCore"]
        ),
    ]
)
