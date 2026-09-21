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
    targets: [
        .target(name: "KitoKeychain"),
        .testTarget(name: "KitoKeychainTests", dependencies: ["KitoKeychain"]),
    ]
)
