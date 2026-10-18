# Architecture

## Targets

| Target | Kind | Contents |
|---|---|---|
| `Tottoro` | App (iPhone and Mac) | All of the UI. It does not use Mac Catalyst; one target builds for both |
| `TottoroAutoFill` | AutoFill extension (iPhone and Mac) | Passes codes to text fields in Safari and other apps |
| `TottoroKit` | Local Swift Package | Code shared by the app and the extension |
| `TottoroTests` | Unit tests | Tests for the app's ViewModels |
| `TottoroSnapshotTests` | Snapshot tests (iPhone only) | Images of the screens and components, in English and Japanese, light and dark |
| `TottoroUITests` | UI tests | Main flows on iPhone, and the App Store screenshots on iPhone and Mac |

`TottoroKit` is split into two libraries.

| Library | Contents | Side effects |
|---|---|---|
| `TottoroCore` | Account types, TOTP computation, Base32, parsing of otpauth URLs and Google's export format, the storage protocol | None |
| `TottoroStorage` | Saving to the Keychain, registering AutoFill suggestions with the OS | Yes |

Code without side effects lives in `TottoroCore` so that `swift test` alone can run its tests. The Keychain does not work without entitlements, so `TottoroStorage` has no tests. It is checked on real devices.

## Layers

The app uses MVVM.

```text
View (SwiftUI)
  ↓ only touches the ViewModel
ViewModel (@Observable)
  ↓
AccountStore (one for the whole app)
  ↓ through the AccountRepository protocol
KeychainAccountRepository (TottoroStorage)
```

- Views only touch ViewModels. They do not touch domain types or storage directly.
- `AccountStore` is the single owner of the account list. On Mac, the main window and the menu bar share the same one. An account added in one shows up in the other right away.
- Every time the list changes, `AccountStore` registers the AutoFill suggestions again (`CredentialIdentityRegistrar`). Accounts added on other devices are added to the suggestions when the list is reloaded.
- In tests, `AccountRepository` is replaced with a fake that keeps data in memory (`InMemoryAccountRepository`). It lives in `Tottoro/Debug/`, inside `#if DEBUG`, because UI tests use it from the app too.
- The app, the extension, and their unit tests use `MainActor` as the default actor (`SWIFT_DEFAULT_ACTOR_ISOLATION`). `TottoroKit` does not depend on the UI, so it keeps the default. `TottoroUITests` keeps the default too, because `XCTestCase` cannot be main-actor isolated as a whole.

## Folders

```text
project.yml                 XcodeGen settings. The .xcodeproj is generated from this
Configs/                    Build settings per configuration (bundle IDs, display name)
TestPlans/                  Unit, UI, and Screenshots test plans
mise.toml                   Tool versions and tasks (setup, lint, format)
lefthook.yml                Git hooks
scripts/                    String Catalog checks, App Store screenshots, commit message check
ci_scripts/                 Xcode Cloud
Tottoro/
  App/                      App entry point, AccountStore, AppLock, RootView
  Debug/                    Code for tests only, inside #if DEBUG
  Features/                 A View and a ViewModel for each screen
    AccountList/            The main screen, same as Authy
    AddAccount/             QR scanning, manual entry, import from Google
    EditAccount/            Editing the name, domain, and color
    Lock/                   The screen shown while locked
  Platform/
    Clipboard.swift         Copying codes (different on iPhone and Mac)
    iOS/                    VisionKit camera screen
    macOS/                  Menu bar, reading QR codes from the screen
  DesignSystem/             Spacing, type, and color tokens, and shared components
  Resources/                Assets.xcassets, String Catalogs, PrivacyInfo.xcprivacy
TottoroAutoFill/            The AutoFill extension
TottoroKit/                 The local Swift Package
TottoroTests/               ViewModel tests, in the same layout as Features
TottoroSnapshotTests/       Snapshot tests. Reference images are in __Snapshots__ next to each test
TottoroUITests/             UI tests and the App Store screenshots
docs/                       These documents
```

Files in `Platform/iOS` and `Platform/macOS` are wrapped entirely in `#if os(iOS)` / `#if os(macOS)`.

The source folders are Xcode folders (buildable folders), not groups. A file added on disk shows up in Xcode without generating the project again.

## Screens

The screens rebuild Authy's UI in SwiftUI.

- The main screen shows the selected account's code in large type at the top, and a grid of account circles below. The top background uses the selected account's color. Tap to copy the code. Long press (right-click on Mac) to edit or delete.
- The countdown ring uses `TimelineView(.animation)` to shrink smoothly in step with screen redraws.
- The Mac menu bar uses `MenuBarExtra` with the `.window` style and shows a search field and a list. Click to copy.
- Standard OS components (`NavigationStack`, `Form`, `List`, `ContentUnavailableView`) are used as they are. They get the iOS 26 / macOS 26 Liquid Glass look on their own.

## Data flow

### Adding

```text
QR code (camera / Photos / Mac screen)
  → string (otpauth:// or otpauth-migration://)
  → AddAccountViewModel.handleScannedPayloads
  → turned into Account by OTPAuthURI / GoogleMigrationParser
  → AccountStore.add
  → saved to the Keychain, and AutoFill suggestions registered again
```

### Sync

Keychain items have `kSecAttrSynchronizable` set, so iCloud Keychain syncs them between iPhone and Mac. The Keychain has no notification for "changed on another device". So the app reloads when it comes to the foreground and when the menu bar is opened.

### AutoFill

1. The app registers accounts that have a domain with `ASCredentialIdentityStore`.
2. When you focus a code field in Safari or elsewhere, the OS shows suggestions whose domain matches.
3. When a suggestion is picked, the extension asks you to unlock, then reads the Keychain, computes the code, and returns it.

When the list is opened from the "Passcodes" button on a text field, all accounts are listed, with the ones matching the current site first.
