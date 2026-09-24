//
//  KitoSecretStore.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Somewhere secrets live. `KitoKeychain` is the real one; `KitoInMemorySecretStore` keeps them
/// in memory for previews, demos and tests (a bare test bundle has no keychain entitlement).
public protocol KitoSecretStore: Sendable {
    func secretData(for key: String) throws -> Data?
    func storeSecret(_ data: Data, for key: String) throws
    func removeSecret(for key: String) throws
    func removeAllSecrets() throws
}

extension KitoKeychain: KitoSecretStore {
    public func secretData(for key: String) throws -> Data? { try data(for: key) }
    public func storeSecret(_ data: Data, for key: String) throws { try set(data, for: key) }
    public func removeSecret(for key: String) throws { try remove(key) }
    public func removeAllSecrets() throws { try removeAll() }
}

/// Secrets in memory only — gone when the process ends.
public final class KitoInMemorySecretStore: KitoSecretStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: Data]

    public init(_ values: [String: Data] = [:]) {
        self.values = values
    }

    public func secretData(for key: String) throws -> Data? { lock.withLock { values[key] } }
    public func storeSecret(_ data: Data, for key: String) throws { lock.withLock { values[key] = data } }
    public func removeSecret(for key: String) throws { _ = lock.withLock { values.removeValue(forKey: key) } }
    public func removeAllSecrets() throws { lock.withLock { values.removeAll() } }
}
