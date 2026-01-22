// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EurorackMIDI",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "EurorackMIDI",
            targets: ["App"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/orchetect/MIDIKit", exact: "0.10.7"),
        .package(url: "https://github.com/elai950/AlertToast", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "MIDIKitIO", package: "MIDIKit"),
                .product(name: "AlertToast", package: "AlertToast")
            ],
            path: "Sources/App"
        )
    ]
)
