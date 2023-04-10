// swift-tools-version:5.3

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
      ]
		),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/combine-schedulers", .branch("0.5.0")),
		.package(url: "https://github.com/pointfreeco/swift-identified-collections", .branch("0.1.1")),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", .branch("0.2.0")),
  ],
  targets: [
    .target(
      name: "Architecture",
      dependencies: [
				.product(name: "CombineSchedulers", package: "combine-schedulers"),
				.product(name: "IdentifiedCollections", package: "swift-identified-collections")
			]
		),
    .testTarget(
      name: "ArchitectureTests",
      dependencies: ["Architecture"]),
  ]
)
