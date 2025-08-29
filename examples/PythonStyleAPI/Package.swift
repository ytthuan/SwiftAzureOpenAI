// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PythonStyleAPI",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(path: "../..") // SwiftAzureOpenAI package
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "PythonStyleAPI",
            dependencies: ["SwiftAzureOpenAI"]
        ),
    ]
)