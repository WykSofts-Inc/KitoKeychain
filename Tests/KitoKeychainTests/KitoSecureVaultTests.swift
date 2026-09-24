//
//  KitoSecureVaultTests.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoKeychain

@MainActor
final class KitoSecureVaultTests: XCTestCase {
    func testAddReadDeleteRoundTrip() {
        let vault = KitoSecureVault(store: KitoInMemorySecretStore())
        let item = vault.add("M-Pesa PIN", kind: .pin, secret: "4821", detail: "Safaricom")
        XCTAssertNotNil(item)
        XCTAssertEqual(vault.items.count, 1)
        XCTAssertEqual(vault.secret(for: item!), "4821")

        vault.update(item!, secret: "9034")
        XCTAssertEqual(vault.secret(for: item!), "9034")

        vault.delete(item!)
        XCTAssertTrue(vault.items.isEmpty)
        XCTAssertNil(vault.secret(for: item!))
        XCTAssertNil(vault.lastError)
    }

    func testIndexSurvivesANewVaultOnTheSameStore() {
        let store = KitoInMemorySecretStore()
        let first = KitoSecureVault(store: store)
        first.add("GitHub token", kind: .token, secret: "ghp_123")
        first.add("Recovery codes", kind: .recoveryCode, secret: "a1b2 c3d4")

        let second = KitoSecureVault(store: store)
        XCTAssertEqual(second.items.map(\.title), ["GitHub token", "Recovery codes"])
        XCTAssertEqual(second.secret(for: second.items[0]), "ghp_123")
    }

    func testDeleteAllClearsSecretsAndIndex() throws {
        let store = KitoInMemorySecretStore()
        let vault = KitoSecureVault(store: store)
        let item = vault.add("Wi-Fi", kind: .password, secret: "karibu2026")!
        vault.deleteAll()
        XCTAssertTrue(vault.items.isEmpty)
        XCTAssertNil(try store.secretData(for: KitoSecureVault.secretKey(item.id)))
        XCTAssertNil(try store.secretData(for: KitoSecureVault.indexKey))
    }

    func testPreviewIsPrefilled() {
        let vault = KitoSecureVault.preview([("Card", .card, "4242424242424242", nil)])
        XCTAssertEqual(vault.items.first?.kind, .card)
    }
}

final class KitoSecretMaskTests: XCTestCase {
    func testDotsHideLength() {
        XCTAssertEqual(KitoSecretMask.dots.apply(to: "a"), "••••••••")
        XCTAssertEqual(KitoSecretMask.dots.apply(to: String(repeating: "x", count: 40)), "••••••••")
    }

    func testLastFour() {
        XCTAssertEqual(KitoSecretMask.lastFour.apply(to: "4242424242424242"), "•••• 4242")
        XCTAssertEqual(KitoSecretMask.lastFour.apply(to: "123"), "••••")
    }

    func testPartial() {
        XCTAssertEqual(KitoSecretMask.partial(prefix: 3, suffix: 2).apply(to: "sk_live_9f2a"), "sk_••••••2a")
        XCTAssertEqual(KitoSecretMask.partial(prefix: 4, suffix: 4).apply(to: "short"), "•••••")
    }

    func testKindsPickSensibleMasks() {
        XCTAssertEqual(KitoSecureItem.Kind.card.defaultMask, .lastFour)
        XCTAssertEqual(KitoSecureItem.Kind.pin.defaultMask, .dots)
    }

    func testRevealGateNoneAllows() async {
        let allowed = await KitoRevealGate.none.authenticate("x")
        XCTAssertTrue(allowed)
        let denied = await KitoRevealGate.simulated(allows: false, delay: .zero).authenticate("x")
        XCTAssertFalse(denied)
    }
}
