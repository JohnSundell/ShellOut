// swift-tools-version:5.8

/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "ShellOut",
    platforms: [.macOS("10.15.4")],
    products: [
        .library(name: "ShellOut", targets: ["ShellOut"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftPackageIndex/ShellQuote", from: "1.0.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", from: "0.5.2"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ShellOut",
            dependencies: [
                .product(name: "ShellQuote", package: "ShellQuote"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "TSCBasic", package: "swift-tools-support-core"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ShellOutTests",
            dependencies: ["ShellOut"],
            exclude: ["Fixtures"]
        )
    ]
)
