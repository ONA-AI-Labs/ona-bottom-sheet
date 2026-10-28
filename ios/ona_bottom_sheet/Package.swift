// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ona_bottom_sheet",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "ona-bottom-sheet", targets: ["ona_bottom_sheet"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "ona_bottom_sheet",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
