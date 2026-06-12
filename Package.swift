// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeakPatch",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "SpeakPatch", targets: ["SpeakPatch"])
    ],
    targets: [
        .executableTarget(
            name: "SpeakPatch",
            path: "Sources/SpeakPatch"
        )
    ]
)
