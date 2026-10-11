// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "MacWindowSwitcher",
  platforms: [.macOS(.v13)],
  products: [
    .executable(name: "MacWindowSwitcher", targets: ["MacWindowSwitcher"]),
  ],
  targets: [
    .target(name: "MacWindowSwitcherCore"),
    .executableTarget(
      name: "MacWindowSwitcher",
      dependencies: ["MacWindowSwitcherCore"]
    ),
    .testTarget(
      name: "MacWindowSwitcherCoreTests",
      dependencies: ["MacWindowSwitcherCore"]
    ),
    // AppKit view behavior (hit testing, panel focus) cannot live in Core.
    .testTarget(
      name: "MacWindowSwitcherTests",
      dependencies: ["MacWindowSwitcher"]
    ),
  ]
)
