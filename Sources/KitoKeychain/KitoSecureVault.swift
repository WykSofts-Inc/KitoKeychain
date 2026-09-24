//
//  KitoSecureVault.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import Observation

/// One entry in a `KitoSecureVault`. Only the non-secret parts live here; the secret itself is
/// stored separately in the vault's store and read on demand.
public struct KitoSecureItem: Identifiable, Codable, Hashable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case note, password, token, apiKey, card, pin, recoveryCode

        public var displayName: String {
            switch self {
            case .note: return "Secure note"
            case .password: return "Password"
            case .token: return "Access token"
            case .apiKey: return "API key"
            case .card: return "Card"
            case .pin: return "PIN"
            case .recoveryCode: return "Recovery code"
            }
        }

        public var systemImage: String {
            switch self {
            case .note: return "note.text"
            case .password: return "key.fill"
            case .token: return "person.badge.key.fill"
            case .apiKey: return "chevron.left.forwardslash.chevron.right"
            case .card: return "creditcard.fill"
            case .pin: return "circle.grid.3x3.fill"
            case .recoveryCode: return "lifepreserver.fill"
            }
        }

        /// The mask that suits this kind of secret.
        public var defaultMask: KitoSecretMask {
            switch self {
            case .card: return .lastFour
            case .apiKey, .token: return .partial(prefix: 4, suffix: 4)
            case .note, .password, .pin, .recoveryCode: return .dots
            }
        }
    }

    public let id: UUID
    public var title: String
    public var kind: Kind
    /// A non-secret line under the title: "Expires 12 Oct", "Equity Bank".
    public var detail: String?
    public var createdAt: Date

    public init(id: UUID = UUID(), title: String, kind: Kind, detail: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.kind = kind
        self.detail = detail
        self.createdAt = createdAt
    }
}

/// A small vault of secure notes, passwords and tokens on top of the keychain: item titles and
/// kinds in one index entry, each secret in its own entry, read only when you ask for it.
/// Pair it with `KitoSecureVaultView`, which reveals a secret only after Face ID.
@MainActor
@Observable
public final class KitoSecureVault {
    public private(set) var items: [KitoSecureItem] = []
    /// The last error, readable for display; `nil` after a successful operation.
    public private(set) var lastError: String?

    @ObservationIgnored private let store: any KitoSecretStore
    static let indexKey = "kito.vault.index"

    /// A vault in the keychain under `service`.
    public convenience init(service: String, accessGroup: String? = nil) {
        self.init(store: KitoKeychain(service: service, accessGroup: accessGroup))
    }

    /// A vault in any store — `KitoInMemorySecretStore()` for previews and tests.
    public init(store: any KitoSecretStore) {
        self.store = store
        load()
    }

    /// Re-reads the index from the store.
    public func load() {
        perform {
            guard let data = try store.secretData(for: Self.indexKey) else { items = []; return }
            items = try JSONDecoder().decode([KitoSecureItem].self, from: data)
        }
    }

    @discardableResult
    public func add(_ title: String, kind: KitoSecureItem.Kind, secret: String, detail: String? = nil) -> KitoSecureItem? {
        let item = KitoSecureItem(title: title, kind: kind, detail: detail)
        let saved = perform {
            try store.storeSecret(Data(secret.utf8), for: Self.secretKey(item.id))
            try saveIndex(items + [item])
            items.append(item)
        }
        return saved ? item : nil
    }

    /// Replaces an item's secret.
    public func update(_ item: KitoSecureItem, secret: String) {
        perform { try store.storeSecret(Data(secret.utf8), for: Self.secretKey(item.id)) }
    }

    /// Reads an item's secret. Gate the call yourself (the view does it with Face ID).
    public func secret(for item: KitoSecureItem) -> String? {
        var value: String?
        perform {
            value = try store.secretData(for: Self.secretKey(item.id)).flatMap { String(data: $0, encoding: .utf8) }
        }
        return value
    }

    public func delete(_ item: KitoSecureItem) {
        perform {
            try store.removeSecret(for: Self.secretKey(item.id))
            let remaining = items.filter { $0.id != item.id }
            try saveIndex(remaining)
            items = remaining
        }
    }

    /// Removes every item and its secret.
    public func deleteAll() {
        perform {
            for item in items { try store.removeSecret(for: Self.secretKey(item.id)) }
            try store.removeSecret(for: Self.indexKey)
            items = []
        }
    }

    /// A vault in memory, pre-filled — for previews and demos.
    public static func preview(_ entries: [(title: String, kind: KitoSecureItem.Kind, secret: String, detail: String?)]) -> KitoSecureVault {
        let vault = KitoSecureVault(store: KitoInMemorySecretStore())
        for entry in entries { vault.add(entry.title, kind: entry.kind, secret: entry.secret, detail: entry.detail) }
        return vault
    }

    static func secretKey(_ id: UUID) -> String { "kito.vault.item.\(id.uuidString)" }

    private func saveIndex(_ items: [KitoSecureItem]) throws {
        try store.storeSecret(try JSONEncoder().encode(items), for: Self.indexKey)
    }

    @discardableResult
    private func perform(_ work: () throws -> Void) -> Bool {
        do {
            try work()
            lastError = nil
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }
}
