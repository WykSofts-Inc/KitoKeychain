//
//  KitoKeychainTests.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoKeychain

/// Keychain Services requires the calling process to hold a
/// keychain-access-group entitlement. A real app target always has one; a
/// bare SPM test bundle run headless (no host app, ad-hoc signed) does not,
/// and every Keychain call fails with `errSecMissingEntitlement` (-34018)
/// regardless of query correctness. That's an environment constraint, not a
/// defect in `KitoKeychain` — these tests skip (not fail) when they hit it,
/// so a real signature-and-entitlement gap doesn't masquerade as green, but
/// this known, unfixable-from-here limitation doesn't block CI either.
/// **Verify KitoKeychain for real inside a host app target** (or this
/// package's own consuming app once one exists) where the entitlement is
/// present — that's the environment every actual consumer runs in.
private let missingEntitlementStatus: OSStatus = -34018

final class KitoKeychainTests: XCTestCase {
    private func makeKeychain() -> KitoKeychain {
        KitoKeychain(service: "com.wyksoftsinc.kitokeychain.tests.\(UUID().uuidString)")
    }

    private func skipIfNoKeychainEntitlement(_ error: Error) throws {
        if case KitoKeychainError.osStatus(missingEntitlementStatus) = error {
            throw XCTSkip("No keychain-access-group entitlement in this bare test bundle — run inside a host app target to exercise real Keychain access.")
        }
        throw error
    }

    func testSetAndGetStringRoundTrips() throws {
        let keychain = makeKeychain()
        do {
            try keychain.set("hunter2", for: "password")
            XCTAssertEqual(try keychain.string(for: "password"), "hunter2")
        } catch {
            try skipIfNoKeychainEntitlement(error)
        }
    }

    func testGetMissingKeyReturnsNilNotThrows() throws {
        let keychain = makeKeychain()
        do {
            let result = try keychain.data(for: "never-set")
            XCTAssertNil(result)
        } catch {
            try skipIfNoKeychainEntitlement(error)
        }
    }

    func testSetTwiceUpdatesRatherThanThrowingDuplicate() throws {
        let keychain = makeKeychain()
        do {
            try keychain.set("first", for: "token")
            try keychain.set("second", for: "token")
            XCTAssertEqual(try keychain.string(for: "token"), "second")
        } catch {
            try skipIfNoKeychainEntitlement(error)
        }
    }

    func testRemoveDeletesTheItem() throws {
        let keychain = makeKeychain()
        do {
            try keychain.set("value", for: "key")
            try keychain.remove("key")
            XCTAssertNil(try keychain.data(for: "key"))
        } catch {
            try skipIfNoKeychainEntitlement(error)
        }
    }

    func testRemoveMissingKeyDoesNotThrow() throws {
        let keychain = makeKeychain()
        do {
            try keychain.remove("never-existed")
        } catch {
            try skipIfNoKeychainEntitlement(error)
        }
    }

    func testRemoveAllClearsEveryItemInService() throws {
        let keychain = makeKeychain()
        do {
            try keychain.set("a", for: "key1")
            try keychain.set("b", for: "key2")
            try keychain.removeAll()
            XCTAssertNil(try keychain.data(for: "key1"))
            XCTAssertNil(try keychain.data(for: "key2"))
        } catch {
            try skipIfNoKeychainEntitlement(error)
        }
    }

    func testDifferentServicesAreIsolated() throws {
        let a = KitoKeychain(service: "com.wyksoftsinc.tests.a.\(UUID().uuidString)")
        let b = KitoKeychain(service: "com.wyksoftsinc.tests.b.\(UUID().uuidString)")
        do {
            try a.set("secret", for: "key")
            XCTAssertNil(try b.data(for: "key"), "a different service namespace must not see another's items")
        } catch {
            try skipIfNoKeychainEntitlement(error)
        }
    }

    func testKeychainErrorDescribesMissingEntitlementReadably() {
        let error = KitoKeychainError.osStatus(missingEntitlementStatus)
        XCTAssertNotNil(error.errorDescription)
    }

    func testInvalidStringEncodingHasMessage() {
        XCTAssertEqual(KitoKeychainError.invalidStringEncoding.errorDescription, "Couldn't encode the string as UTF-8.")
    }
}
