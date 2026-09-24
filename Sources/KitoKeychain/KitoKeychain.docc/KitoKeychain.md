# ``KitoKeychain``

A small, correct wrapper over Keychain Services, plus a secure vault and reveal-on-demand secret views.

## Overview

``KitoKeychain/KitoKeychain`` stores auth tokens, refresh tokens and other
secrets that must survive relaunch but must never touch `UserDefaults`. Create
one instance per logical namespace by passing a distinct `service`, so clearing
one namespace on sign-out doesn't wipe unrelated data.

```swift
let keychain = KitoKeychain(service: "com.yourapp.auth")
try keychain.set(accessToken, for: "accessToken")
let token = try keychain.string(for: "accessToken")

try keychain.set(refreshToken, for: "refreshToken", accessibility: .afterFirstUnlockThisDeviceOnly)
try keychain.removeAll()
```

Items default to `.whenUnlockedThisDeviceOnly`, which never syncs to iCloud
Keychain and is unreadable while the device is locked. The type doesn't prompt
for biometrics itself; gate reads at the call site, for example with
KitoBiometrics.

For secure notes and token storage with a ready-made UI, ``KitoSecureVault``
keeps item titles and kinds in one keychain entry and each secret in its own,
read only when asked for. ``KitoSecureVaultView`` shows the vault and reveals a
secret only after Face ID or Touch ID, and ``KitoRevealableSecret`` does the
same for a single value. Back a vault with ``KitoInMemorySecretStore`` for
previews and tests, since a bare test bundle has no keychain entitlement.

## Topics

### Keychain

- ``KitoKeychain/KitoKeychain``
- ``KitoKeychainError``
- ``KitoSecretStore``
- ``KitoInMemorySecretStore``

### Secure Vault

- ``KitoSecureVault``
- ``KitoSecureItem``
- ``KitoSecureVaultView``
- ``KitoSecureItemComposer``

### Revealing Secrets

- ``KitoRevealableSecret``
- ``KitoSecretMask``
- ``KitoRevealGate``
