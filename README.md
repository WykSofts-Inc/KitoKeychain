# KitoKeychain

A small, correct wrapper over Keychain Services — auth tokens, refresh
tokens, and secrets that need to survive relaunch but must never touch
`UserDefaults`.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoKeychain.git", from: "1.0.0"),
```

## Samples

**Store and retrieve an auth token:**
```swift
let keychain = KitoKeychain(service: "com.yourapp.auth")
try keychain.set(accessToken, for: "accessToken")
let token = try keychain.string(for: "accessToken")
```

**Clear everything on sign-out:**
```swift
try keychain.removeAll()
```

**Pair with KitoBiometrics — gate a read behind Face ID:**
```swift
let result = await KitoBiometricAuthenticator().authenticate(reason: "Unlock your saved card")
guard case .success = result else { return }
let cardToken = try keychain.string(for: "cardToken")
```

**Separate namespaces so sign-out doesn't wipe unrelated data:**
```swift
let authKeychain = KitoKeychain(service: "com.yourapp.auth")
let settingsKeychain = KitoKeychain(service: "com.yourapp.settings")
// authKeychain.removeAll() never touches settingsKeychain's items
```

**Custom accessibility (e.g. allow background-refresh reads):**
```swift
try keychain.set(refreshToken, for: "refreshToken", accessibility: .afterFirstUnlockThisDeviceOnly)
```

## A note on testing this package

Keychain Services requires the calling process to hold a keychain-access-group
entitlement. Every real app target has one automatically; a bare `swift test`
run of this package alone does not, so its Keychain calls fail with
`errSecMissingEntitlement` in that specific context — the test suite detects
this and skips (not fails) rather than reporting a false pass or a false
product defect. This is an SPM test-bundle constraint, not a bug in
`KitoKeychain` — it works normally inside any real app, which is the
environment every actual consumer runs in.

## License

MIT
