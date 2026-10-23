// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "device_display_name",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "device-display-name", targets: ["device_display_name"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "device_display_name",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // The plugin collects nothing and tracks nobody; the manifest says so.
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
