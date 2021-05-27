// swift-tools-version:5.4

import PackageDescription

let package = Package(
  name: "Architecture",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    .library(
      name: "Architecture",
      targets: [
        "Architecture",
      ]),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", .branch("1.9.3")),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", .branch("0.5.0")),
  ],
  targets: [
    .target(
      name: "Architecture",
      dependencies: ["SwiftyBeaver", .product(name: "CombineSchedulers", package: "combine-schedulers")]),
    .testTarget(
      name: "ArchitectureTests",
      dependencies: ["Architecture"]),
  ]
)
