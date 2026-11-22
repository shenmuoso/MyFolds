// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "MyFolds",
    platforms: [.macOS("27.0")],
    products: [.executable(name: "MyFolds", targets: ["MyFolds"]), .library(name: "MyFoldsCore", targets: ["MyFoldsCore"])],
    targets: [
        .target(name: "CArchive", linkerSettings: [.linkedLibrary("archive")]),
        .target(name: "MyFoldsCore", dependencies: ["CArchive"]),
        .executableTarget(name: "MyFolds", dependencies: ["MyFoldsCore"]),
        .testTarget(name: "MyFoldsCoreTests", dependencies: ["MyFoldsCore", "CArchive"], resources: [.copy("Fixtures")]),
        .testTarget(name: "MyFoldsUITests", dependencies: ["MyFolds"], resources: [.copy("Fixtures")])
    ]
)
