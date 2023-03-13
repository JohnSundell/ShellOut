// swift-tools-version:4.2

/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import PackageDescription

let package = Package(
    name: "ShellOut",
    products: [
        .library(name: "ShellOut", targets: ["ShellOut"])
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftPackageIndex/ShellQuote", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "ShellOut",
            dependencies: [
                .product(name: "ShellQuote", package: "ShellQuote")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ShellOutTests",
            dependencies: ["ShellOut"]
        )
    ]
)
