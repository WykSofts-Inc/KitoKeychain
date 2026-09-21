//
//  KitoKeychain.swift
//  KitoKeychain
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import Security

/// A small, correct wrapper over Keychain Services — for auth tokens,
/// refresh tokens, and other secrets that must survive app relaunches but
/// never touch `UserDefaults`. Pairs with `KitoBiometrics`: gate reads with
/// a biometric prompt at the call site, this type doesn't do that itself.
///
/// One instance per logical namespace — pass a distinct `service` per use
/// case (e.g. `"com.yourapp.authToken"`) so clearing one doesn't clear another.
public struct KitoKeychain: Sendable {
    /// Mirrors `kSecAttrAccessible` — when the item is readable relative to
    /// device lock state. `.whenUnlockedThisDeviceOnly` (the default) never
    /// syncs to iCloud Keychain and is unreadable while the device is
    /// locked — the right default for auth tokens.
    public enum Accessibility: Sendable {
        case whenUnlocked
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlock
        case afterFirstUnlockThisDeviceOnly

        var secAttribute: CFString {
            switch self {
            case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
            case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
            case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }

    public let service: String
    public let accessGroup: String?

    public init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.accessGroup = accessGroup
    }

    public func set(_ value: Data, for key: String, accessibility: Accessibility = .whenUnlockedThisDeviceOnly) throws {
        var query = baseQuery(for: key)
        query[kSecValueData as String] = value
        query[kSecAttrAccessible as String] = accessibility.secAttribute

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let update: [String: Any] = [kSecValueData as String: value]
            let updateStatus = SecItemUpdate(baseQuery(for: key) as CFDictionary, update as CFDictionary)
            guard updateStatus == errSecSuccess else { throw KitoKeychainError.osStatus(updateStatus) }
        } else if status != errSecSuccess {
            throw KitoKeychainError.osStatus(status)
        }
    }

    public func set(_ value: String, for key: String, accessibility: Accessibility = .whenUnlockedThisDeviceOnly) throws {
        guard let data = value.data(using: .utf8) else {
            throw KitoKeychainError.invalidStringEncoding
        }
        try set(data, for: key, accessibility: accessibility)
    }

    public func data(for key: String) throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw KitoKeychainError.osStatus(status) }
        return result as? Data
    }

    public func string(for key: String) throws -> String? {
        guard let data = try data(for: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func remove(_ key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KitoKeychainError.osStatus(status)
        }
    }

    /// Removes every item under this instance's `service` namespace — use
    /// on sign-out to guarantee no stale token survives.
    public func removeAll() throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KitoKeychainError.osStatus(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }
}

public enum KitoKeychainError: Error, LocalizedError {
    case osStatus(OSStatus)
    case invalidStringEncoding

    public var errorDescription: String? {
        switch self {
        case .osStatus(let status):
            return (SecCopyErrorMessageString(status, nil) as String?) ?? "Keychain error \(status)"
        case .invalidStringEncoding:
            return "Couldn't encode the string as UTF-8."
        }
    }
}
