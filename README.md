# KitoKeychain

A small, correct wrapper over Keychain Services — auth tokens, refresh
tokens, and secrets that need to survive relaunch but must never touch
`UserDefaults`.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoKeychain.git", from: "1.1.0"),
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

## Secure notes and token vault

```swift
@State private var vault = KitoSecureVault(service: "com.yourapp.vault")

KitoSecureVaultView(vault: vault, title: "Vault")
```

Item titles and kinds live in one keychain entry, each secret in its own, read
only when revealed. Secrets reveal after Face ID / Touch ID (passcode fallback),
hide again after 20 seconds, and copy to a device-only clipboard that clears
after a minute. Kinds: secure note, password, access token, API key, card, PIN,
recovery code — each with a sensible mask.

```swift
vault.add("KRA iTax PIN", kind: .pin, secret: "4821", detail: "Renews March")
let pin = vault.secret(for: item)       // gate this yourself outside the view
vault.delete(item)
```

## Reveal one secret

```swift
KitoRevealableSecret("API key", value: apiKey, mask: .partial(prefix: 4, suffix: 4))
KitoRevealableSecret("Card", mask: .lastFour) { try? keychain.string(for: "card") }
```

`KitoSecretMask`: `.dots`, `.lastFour`, `.partial(prefix:suffix:)`.
`KitoRevealGate`: `.deviceOwner` (default), `.none`, `.simulated(allows:)`.

## Previews and tests

`KitoSecureVault(store: KitoInMemorySecretStore())` or `KitoSecureVault.preview([...])`
keeps everything in memory. Any type conforming to `KitoSecretStore` works as a store.

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
