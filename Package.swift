// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EurorackMIDI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "EurorackMIDILib",
            targets: ["EurorackMIDILib"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/MIDIKit", exact: "0.10.7"),
        .package(url: "https://github.com/elai950/AlertToast", branch: "master"),
        .package(url: "https://github.com/nonstrict-hq/CloudStorage", from: "0.5.0")
    ],
    targets: [
        .target(
            name: "EurorackMIDILib",
            dependencies: [
                .product(name: "MIDIKitIO", package: "MIDIKit"),
                .product(name: "AlertToast", package: "AlertToast"),
                .product(name: "CloudStorage", package: "CloudStorage")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "EurorackMIDITests",
            dependencies: ["EurorackMIDILib"],
            path: "Tests"
        )
    ]
)
