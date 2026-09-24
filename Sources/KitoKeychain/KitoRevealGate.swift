//
//  KitoRevealGate.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import LocalAuthentication

/// What has to happen before a secret is shown. `.deviceOwner` asks for Face ID / Touch ID with
/// the passcode as fallback; `.simulated(allows:)` answers on cue for previews and demos.
public struct KitoRevealGate: Sendable {
    public var authenticate: @Sendable (_ reason: String) async -> Bool

    public init(authenticate: @escaping @Sendable (_ reason: String) async -> Bool) {
        self.authenticate = authenticate
    }

    /// Face ID / Touch ID, falling back to the device passcode. A device with no passcode at all
    /// has nothing to check against, so it reveals.
    public static let deviceOwner = KitoRevealGate { reason in
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return (error as? LAError)?.code == .passcodeNotSet
        }
        return (try? await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)) ?? false
    }

    /// Reveals without asking.
    public static let none = KitoRevealGate { _ in true }

    public static func simulated(allows: Bool = true, delay: Duration = .milliseconds(900)) -> KitoRevealGate {
        KitoRevealGate { _ in
            try? await Task.sleep(for: delay)
            return allows
        }
    }
}
