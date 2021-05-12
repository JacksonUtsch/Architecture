// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Architecture",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15)
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "Architecture",
      targets: ["Architecture"]),
  ],
  dependencies: [
    .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", .branch("1.9.3")),
    .package(url: "https://github.com/pointfreeco/combine-schedulers", .branch("0.5.0")),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Architecture",
      dependencies: ["SwiftyBeaver", .product(name: "CombineSchedulers", package: "combine-schedulers")]),
    .testTarget(
      name: "ArchitectureTests",
      dependencies: ["Architecture"]),
  ]
)
