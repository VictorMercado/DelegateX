// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CommandBuilder",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CommandBuilder", targets: ["CommandBuilder"])
    ],
    targets: [
        .executableTarget(
            name: "CommandBuilder",
            dependencies: [],
            path: "Sources"
        )
    ]
)
