// swift-tools-version:5.9
import PackageDescription

// SpamCore: pure logic (phone normalization, rule engine). Foundation only,
// so `swift test` runs on a cheap Linux runner.
let package = Package(
    name: "SpamCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SpamCore", targets: ["SpamCore"])
    ],
    targets: [
        .target(name: "SpamCore"),
        .testTarget(name: "SpamCoreTests", dependencies: ["SpamCore"])
    ],
    swiftLanguageVersions: [.v5]
)
