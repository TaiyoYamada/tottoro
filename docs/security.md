# Security

What Tottoro holds is two-factor authentication secrets. If one leaks, someone who also has the password can get into the account. If one is lost, you cannot log in unless the site turns off two-factor authentication for you.

## What is protected and how

| What | Mechanism | What it prevents |
|---|---|---|
| Secrets (on the device) | Keychain, `kSecAttrAccessibleWhenUnlocked` | Reading them from a locked device |
| Secrets (sync) | End-to-end encryption of iCloud Keychain | Reading them on Apple's servers or in transit |
| Codes on screen | Face ID / Touch ID lock (`AppLock`) | Someone else looking at codes on an unlocked device |
| Codes on screen, in public | Settings > Hide Codes. Codes show only after a tap | People nearby reading a code over your shoulder |
| Exporting | Asks to confirm it is you again, even when the app is unlocked. Goes through the system's Credential Exchange, so nothing is written to a file | Someone with an unlocked app moving all secrets out |
| AutoFill | The extension also asks to unlock every time | Someone else entering codes on an unlocked device |
| The App Switcher | On iPhone, the screen and any open sheet are covered as soon as the app becomes inactive, before the system takes the App Switcher snapshot | Codes and setup keys showing in the App Switcher |
| Copied codes | On iPhone, they expire after 1 minute and do not go to the Mac through Universal Clipboard. On Mac, they are marked with `org.nspasteboard.ConcealedType` | Codes staying on the clipboard |

## What is cryptographic and what is a UI gate

The secrets themselves are protected by cryptography: Keychain encryption and the end-to-end encryption of iCloud Keychain. The encryption keys are tied to the device passcode and the Secure Enclave.

The Face ID / Touch ID lock is a UI gate. The Keychain can protect each item so that it cannot be read without biometric authentication (for example, `.userPresence` in `SecAccessControl`). But this protection cannot be set on items that sync. So Tottoro chose sync, and implements the lock as a gate in the app's UI.

This means that while the device is unlocked, Tottoro and the AutoFill extension can read the Keychain without Face ID. The Face ID lock only prevents codes on screen from being seen. Other apps cannot read the items because their access group is different.

## What is not protected

- The lock uses `deviceOwnerAuthentication`, so if biometrics fail, it can be opened with the passcode. Anyone who knows the passcode can see the codes.
- A device without a passcode cannot open Tottoro at all. Without a passcode, anyone holding the device could read everything on it, so the lock would mean nothing. The app and the AutoFill extension explain this and ask the person to set one. The accounts are still in iCloud Keychain, so other devices of the same person can show them.
- If someone learns both the Apple ID password and the passcode of any of your devices, they can sync iCloud Keychain to a new device. This is a matter of Apple ID security, and Tottoro cannot prevent it.
- On iPhone, the app locks when it goes to the background, or after 1 or 5 minutes in the background if the person chose that in Settings. The time is measured with `ContinuousClock`, which keeps counting while the device sleeps and does not go back when the clock in Settings is changed. There is no option to turn the lock off. On Mac, it locks when the display sleeps and when the user is switched. If only the screen is locked on Mac (without sleeping), the app does not lock. The Mac Settings window is also behind the lock.
- Clipboard history apps that ignore `ConcealedType` will record codes.
- There is no backup yet. iCloud Keychain is the only place the secrets are stored. Deleted accounts cannot be restored, so the app asks for confirmation before deleting.

## The AutoFill extension

- The extension reads the same Keychain access group as the app (`$(AppIdentifierPrefix)$(APP_BUNDLE_ID)`).
- Even when an OS suggestion is picked (`provideCredentialWithoutUserInteraction`), it never returns a code without showing UI. It always returns `userInteractionRequired` and moves to the screen that asks to unlock.
- Only the domain, the account name, and the account id are registered with the OS. Secrets are not registered.

## Importing files from other apps

Export files from other apps are untrusted input. `ExportFileImporter` refuses files over 10 MB, and refuses scrypt parameters in Aegis vaults that would need more than 256 MB of memory. Passwords for encrypted files are used only to open the file and are not stored. Key derivation and decryption use CryptoKit and Apple's swift-crypto (`CryptoExtras`), not code written for Tottoro. See [import-formats.md](import-formats.md).

## Development builds

- The Debug build has its own bundle ID (`….dev`), so it also has its own Keychain access group. A development build on the same device cannot read or delete the secrets of the App Store build.
- UI tests start the app with the `-UITesting` launch argument. It replaces the Keychain with an in-memory store full of made-up accounts, and skips the lock. The code for it is inside `#if DEBUG` (`Tottoro/Debug/`), so it is not in the Release build that goes to the App Store.
- The app collects no data and does no tracking. `PrivacyInfo.xcprivacy` declares this for the app and the extension, and declares the app's use of `UserDefaults` for its settings. See [privacy.md](privacy.md).
- Service logos are built into the app (`scripts/generate-service-icons.py`). Downloading them by domain would tell a third party which services the person uses.

## Checks before code is merged

- A pre-commit hook and CI run gitleaks, so secrets do not end up in Git.
- SwiftLint rejects `print`, and asks for `privacy:` on every value in a `Logger` message, so secrets do not end up in logs.
- Parsers for QR code contents are tested with thousands of broken inputs (`MalformedInputTests`).

## Planned

- Exporting an encrypted backup file (a key derived from a password, with PBKDF2 or scrypt)
