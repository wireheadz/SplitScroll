// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SplitScroll",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "SplitScroll", targets: ["SplitScroll"])],
    targets: [
        .target(name: "ScrollCore"),
        .target(name: "SenderBridge", linkerSettings: [.linkedFramework("CoreGraphics"), .linkedFramework("IOKit")]),
        .executableTarget(name: "SplitScroll", dependencies: ["ScrollCore", "SenderBridge"]),
        .testTarget(name: "ScrollCoreTests", dependencies: ["ScrollCore"])
    ]
)
