//
//  KitoSecretMask.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// How a hidden secret is drawn before it's revealed.
public enum KitoSecretMask: Equatable, Sendable {
    /// Eight dots, whatever the length — gives nothing away.
    case dots
    /// Dots, then the last four characters: `•••• 4242`.
    case lastFour
    /// The first `prefix` and last `suffix` characters around dots: `sk_l••••••9f2a`.
    case partial(prefix: Int, suffix: Int)

    public func apply(to secret: String) -> String {
        let characters = Array(secret)
        switch self {
        case .dots:
            return String(repeating: "•", count: 8)
        case .lastFour:
            guard characters.count > 4 else { return String(repeating: "•", count: 4) }
            return "•••• " + String(characters.suffix(4))
        case .partial(let prefix, let suffix):
            let prefix = max(prefix, 0), suffix = max(suffix, 0)
            guard characters.count > prefix + suffix else { return String(repeating: "•", count: max(characters.count, 4)) }
            return String(characters.prefix(prefix)) + String(repeating: "•", count: 6) + String(characters.suffix(suffix))
        }
    }
}
