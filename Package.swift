// swift-tools-version: 5.9
//
//  Package.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoKeychain",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoKeychain", targets: ["KitoKeychain"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.1.0"),
    ],
    targets: [
        .target(name: "KitoKeychain", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoKeychainTests", dependencies: ["KitoKeychain"]),
    ]
)
