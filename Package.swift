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
    .package(url: "https://github.com/pointfreeco/combine-schedulers", .upToNextMajor(from: "0.5.3")),
		.package(url: "https://github.com/pointfreeco/swift-identified-collections", .upToNextMajor(from: "0.3.2")),
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
