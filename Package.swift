// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TnIosBase",
    platforms: [
        .iOS("15.4")
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TnIosBase",
            targets: ["TnIosBase"]),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "TnIosBase",
            dependencies: [
//                "BinaryCodable"
            ]
        ),
        .testTarget(
            name: "TnIosBaseTests",
            dependencies: ["TnIosBase"]),
    ]
)
