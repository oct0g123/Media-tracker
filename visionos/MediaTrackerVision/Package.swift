// swift-tools-version: 5.9
// This is provided for reference only.
// The actual app must be built with an Xcode project targeting visionOS 1.0+.
// See SETUP.md for instructions.

import PackageDescription

let package = Package(
    name: "MediaTrackerVision",
    platforms: [.visionOS(.v1)],
    products: [
        .library(name: "MediaTrackerVision", targets: ["MediaTrackerVision"]),
    ],
    targets: [
        .target(
            name: "MediaTrackerVision",
            path: "Sources",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
