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
    .package(url: "https://github.com/JacksonUtsch/combine-schedulers", .branch("main")),
		.package(url: "https://github.com/pointfreeco/swift-identified-collections", .branch("0.1.1")),
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
