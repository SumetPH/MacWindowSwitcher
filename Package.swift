// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SimpleWindowSwitcher",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "SimpleWindowSwitcher", targets: ["SimpleWindowSwitcher"]),
  ],
  targets: [
    .executableTarget(
      name: "SimpleWindowSwitcher",
      dependencies: [],
      swiftSettings: [
        .enableUpcomingFeature("BareSlashRegexLiterals")
      ]
    ),
    .testTarget(
      name: "SimpleWindowSwitcherTests",
      dependencies: ["SimpleWindowSwitcher"]
    ),
  ]
)
