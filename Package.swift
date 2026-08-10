// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FretTemplateBuilder",
    platforms: [.macOS("14.0")],
    products: [
        .executable(name: "fret-template-builder", targets: ["FretTemplateBuilder"])
    ],
    targets: [
        .executableTarget(
            name: "FretTemplateBuilder",
            path: "Sources/FretTemplateBuilder"
        )
    ]
)
