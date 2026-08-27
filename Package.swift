// swift-tools-version: 6.0
//
//  Package.swift
//  WelcomeKit
//

import PackageDescription

let package = Package(
    name: "WelcomeKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "WelcomeKit",
            targets: ["WelcomeKit"]
        )
    ],
    targets: [
        .target(
            name: "WelcomeKit"
        ),
        .testTarget(
            name: "WelcomeKitTests",
            dependencies: ["WelcomeKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
