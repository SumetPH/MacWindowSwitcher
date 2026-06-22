// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "MacWindowSwitcher",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "MacWindowSwitcher", targets: ["MacWindowSwitcher"]),
  ],
  targets: [
    .executableTarget(
      name: "MacWindowSwitcher",
      dependencies: [],
      swiftSettings: [
        .enableUpcomingFeature("BareSlashRegexLiterals")
      ]
    ),
    .testTarget(
      name: "MacWindowSwitcherTests",
      dependencies: ["MacWindowSwitcher"]
    ),
  ]
)
