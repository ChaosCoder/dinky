// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DinkyCoreImage",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "DinkyCoreShared", targets: ["DinkyCoreShared"]),
        .library(name: "DinkyCoreImage", targets: ["DinkyCoreImage"]),
        .library(name: "DinkyCoreVideo", targets: ["DinkyCoreVideo"]),
        .library(name: "DinkyCoreAudio", targets: ["DinkyCoreAudio"]),
        .library(name: "DinkyCorePDF", targets: ["DinkyCorePDF"]),
        .library(name: "DinkyCLILib", targets: ["DinkyCLILib"]),
        .executable(name: "dinky", targets: ["DinkyCLIApp"]),
    ],
    targets: [
        .target(
            name: "DinkyCoreShared",
            path: "DinkyCoreImage/Sources/DinkyCoreShared"
        ),
        .target(
            name: "DinkyCoreImage",
            dependencies: ["DinkyCoreShared"],
            path: "DinkyCoreImage/Sources/DinkyCoreImage"
        ),
        .target(
            name: "DinkyCoreVideo",
            dependencies: ["DinkyCoreShared", "DinkyCoreImage"],
            path: "DinkyCoreImage/Sources/DinkyCoreVideo"
        ),
        .target(
            name: "DinkyCoreAudio",
            dependencies: ["DinkyCoreShared"],
            path: "DinkyCoreImage/Sources/DinkyCoreAudio"
        ),
        .target(
            name: "DinkyCorePDF",
            dependencies: ["DinkyCoreShared", "DinkyCoreImage"],
            path: "DinkyCoreImage/Sources/DinkyCorePDF"
        ),
        .target(
            name: "DinkyCLILib",
            dependencies: [
                "DinkyCoreShared",
                "DinkyCoreImage",
                "DinkyCoreVideo",
                "DinkyCoreAudio",
                "DinkyCorePDF",
            ],
            path: "DinkyCoreImage/Sources/DinkyCLILib"
        ),
        .executableTarget(
            name: "DinkyCLIApp",
            dependencies: ["DinkyCLILib"],
            path: "DinkyCoreImage/Sources/DinkyCLIApp"
        ),
        .testTarget(
            name: "DinkyCLILibTests",
            dependencies: ["DinkyCLILib", "DinkyCoreImage", "DinkyCoreVideo", "DinkyCoreAudio", "DinkyCorePDF", "DinkyCoreShared"],
            path: "DinkyCoreImage/Tests/DinkyCLILibTests"
        ),
    ]
)
