// swift-tools-version: 5.9
import PackageDescription

// DO NOT MODIFY THIS FILE - managed by Capacitor CLI commands
let package = Package(
    name: "CapApp-SPM",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapApp-SPM",
            targets: ["CapApp-SPM"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", exact: "8.3.1"),
        .package(name: "CapacitorFilesystem", path: "../../../node_modules/@capacitor/filesystem"),
        .package(name: "CapawesomeTeamCapacitorFileOpener", path: "../../../node_modules/@capawesome-team/capacitor-file-opener"),
        .package(name: "CapawesomeTeamCapacitorShareTarget", path: "../../../node_modules/@capawesome-team/capacitor-share-target"),
        .package(name: "CapawesomeCapacitorFilePicker", path: "../../../node_modules/@capawesome/capacitor-file-picker")
    ],
    targets: [
        .target(
            name: "CapApp-SPM",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "CapacitorFilesystem", package: "CapacitorFilesystem"),
                .product(name: "CapawesomeTeamCapacitorFileOpener", package: "CapawesomeTeamCapacitorFileOpener"),
                .product(name: "CapawesomeTeamCapacitorShareTarget", package: "CapawesomeTeamCapacitorShareTarget"),
                .product(name: "CapawesomeCapacitorFilePicker", package: "CapawesomeCapacitorFilePicker")
            ]
        )
    ]
)
