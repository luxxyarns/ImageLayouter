// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImageLayouter",
    platforms: [.iOS(.v14), .macOS(.v12)  ],

    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ImageLayouter",
            targets: ["ImageLayouter"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/SDWebImage/SDWebImage", from: "5.0.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "2.0.0"),
        .package(url: "https://github.com/hyperoslo/Cache", from: "6.0.0"),
        .package(url: "https://github.com/ejjonny/alpacka", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ImageLayouter",
            dependencies: [
                .product(name: "SDWebImage", package: "SDWebImage"),
                .product(name: "SDWebImageSwiftUI", package: "SDWebImageSwiftUI"),
                .product(name: "Cache", package: "Cache"),
                .product(name: "Alpacka", package: "Alpacka"),
            ]),
        .testTarget(
            name: "ImageLayouterTests",
            dependencies: ["ImageLayouter"]),
    ]
)
 
