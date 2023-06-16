// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "NSViewProxy",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "NSViewProxy", targets: ["NSViewProxy"])
    ],
    targets: [
        .target(
            name: "NSViewProxy",
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
            ])
    ]
)
