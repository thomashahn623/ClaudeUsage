// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ClaudeStatus",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ClaudeStatus",
            path: "Sources/ClaudeStatus"
        )
    ]
)
