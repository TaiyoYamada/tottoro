# Development

## What you need

- Xcode 27.1 (the version in `.xcode-version`)
- [mise](https://mise.jdx.dev) (`brew install mise`). It installs the other tools at the versions in `mise.toml`: SwiftLint, SwiftFormat, XcodeGen, lefthook, and gitleaks.
- A paid Apple Developer Program team, to run the app with AutoFill. The AutoFill entitlement (`com.apple.developer.authentication-services.autofill-credential-provider`) cannot be signed with a free Personal Team. You can still build without signing and run the tests in the simulator.

## Setup

```sh
mise run setup
```

This installs the tools and the Git hooks, copies `Local.xcconfig.example` to `Local.xcconfig`, and generates `Tottoro.xcodeproj`.

Then fill in `Local.xcconfig`. It is not in Git.

```text
DEVELOPMENT_TEAM = ABCDE12345
APP_BUNDLE_ID_BASE = com.example.tottoro
```

`APP_BUNDLE_ID_BASE` is only needed if you are not the maintainer, because the bundle IDs must belong to your team.

Open `Tottoro.xcodeproj`. The first time, Xcode asks whether to trust the swift-protobuf build plugin. Allow it.

`Tottoro.xcodeproj` is generated, so it is not in Git and is never edited by hand. To change targets or settings, edit `project.yml` (or the files in `Configs/`) and run `mise run generate`. The Git hooks also generate it after a checkout or a pull when `project.yml` changed. Adding or removing source files does not need a new project, because the source folders are Xcode folders.

## Configurations

| | Debug | Release |
|---|---|---|
| Bundle ID | `com.taiyo.tottoro.dev` | `com.taiyo.tottoro` |
| Name on the Home Screen | Tottoro Dev | Tottoro |
| App icon | Orange (`AppIcon-Dev`) | Blue (`AppIcon`) |
| Used for | Run and Test in Xcode | Archive for the App Store |

The Debug build has its own bundle ID, and so its own Keychain access group. You can install it next to the App Store build without risking your real secrets. The extensions and test targets add their own suffix to the same base.

## Build

On the command line, `-skipPackagePluginValidation` is needed to trust the swift-protobuf build plugin.

```sh
# Mac
xcodebuild build -project Tottoro.xcodeproj -scheme Tottoro \
  -destination 'platform=macOS,arch=arm64' -skipPackagePluginValidation

# iPhone simulator
xcodebuild build -project Tottoro.xcodeproj -scheme Tottoro \
  -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation
```

The swift-protobuf build plugin builds `protoc` from its C++ source. Only the first build from a clean state takes a few minutes.

## Tests

The `Tottoro` scheme has three test plans.

| Test plan | What runs | When CI runs it |
|---|---|---|
| `Unit` (default) | `TottoroTests` and `TottoroCoreTests` | Every push and pull request, on iPhone and Mac. Every night also with Thread Sanitizer, which builds everything again and is too slow for every push |
| `UI` | `TottoroUITests` and `TottoroSnapshotTests` | Pull requests to `main`, every night, and by hand |
| `Screenshots` | The App Store screenshots, in English and Japanese | By hand, before a release |

```sh
# TottoroCore only (fast, no simulator)
mise run test-kit

# Unit tests of the app
xcodebuild test -project Tottoro.xcodeproj -scheme Tottoro -testPlan Unit \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' -skipPackagePluginValidation

# UI tests and snapshot tests
xcodebuild test -project Tottoro.xcodeproj -scheme Tottoro -testPlan UI \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' -skipPackagePluginValidation
```

UI tests start the app with `-UITesting`. The app then uses made-up accounts in memory instead of the Keychain, and starts unlocked. This only exists in Debug builds (`Tottoro/Debug/`).

### Snapshot tests

Snapshot tests compare the screens with reference images in `__Snapshots__` folders. The images change with the simulator model and the OS version, so record and compare them on the same simulator as CI: iPhone 17 with iOS 27.0.

When a screen changes on purpose, delete its reference images and run the `UI` test plan. The first run records new images and fails. Check the new images, then run again.

When a snapshot test fails in CI, the result bundle is uploaded as an artifact (`ui-test-results`). It contains the image that was taken and the difference.

### Test plans and targets

The test plans in `TestPlans/` refer to targets by their identifiers in the generated project. XcodeGen generates the same identifiers every time, so they only need updating when a test target is added, removed, or renamed. Edit the test plan in Xcode in that case.

## Lint and format

```sh
mise run format   # format all Swift files
mise run lint     # what CI checks: SwiftFormat, SwiftLint, and the String Catalogs
```

SwiftFormat and SwiftLint use their default rules, with a few changes in `.swiftformat` and `.swiftlint.yml`. SwiftLint also has rules of its own for this app:

- `print` is not allowed. Use `os.Logger`.
- Every value interpolated into a `Logger` message needs `privacy:`. Never mark secrets, setup keys, or codes as `.public`. The rule looks for a logger named `logger` with the message on the same line, so name it that way.
- `try!` and force unwrapping are warnings outside tests. CI treats warnings as errors.

## Git hooks

`mise run setup` installs these with lefthook (`lefthook.yml`).

| Hook | What it does |
|---|---|
| pre-commit | Formats the staged Swift files and stages the result, lints them, checks the String Catalogs, and scans the staged changes for secrets with gitleaks |
| commit-msg | Checks the Conventional Commits format (`scripts/check-commit-message.sh`) |
| pre-push | Runs the `TottoroKit` tests when the push changes `TottoroKit` |
| post-checkout, post-merge | Generates the Xcode project again when `project.yml` changed |

## Localization

The source language is English. Japanese is the only translation for now.

- Write UI text in English in the code. Xcode adds new strings to the String Catalog when it builds.
- Add the Japanese translation in the String Catalog (`Localizable.xcstrings`). Text for the permission dialogs is in `InfoPlist.xcstrings`. The AutoFill extension has its own catalogs.
- Text that should not be translated, such as numbers or algorithm names, uses `Text(verbatim:)`.

CI fails when a string has no Japanese translation, when a catalog has a string the code no longer uses, or when the code has a string that is missing from the catalogs. `xcodebuild` does not update the catalogs, so after building on the command line, run this to update them yourself:

```sh
# Build for both iPhone and Mac into the same DerivedData first
scripts/sync-strings.sh <DerivedData path>
```

## Things to check on a real device

The Keychain and AutoFill cannot be fully checked in the simulator or in unit tests. Check these on real devices:

- An account added on iPhone shows up on Mac too (iCloud Keychain sync).
- After turning on Tottoro in Settings > General > AutoFill & Passwords (System Settings on Mac), code suggestions show up on sites whose domain is set.
- On Mac, "Scan from Screen" asks for the Screen Recording permission the first time, and reads the code after it is allowed.

## Releases

1. Open a pull request from `develop` to `main`. CI runs the UI tests and snapshot tests too.
2. After it is merged, release-please opens a release pull request. It bumps `MARKETING_VERSION` in `project.yml` and updates `CHANGELOG.md` from the commit messages.
3. Merging the release pull request tags the release. Xcode Cloud archives it, with its own build number, and uploads it to App Store Connect for TestFlight and the App Store.
4. The release workflow opens a pull request from `main` back to `develop`. Merge it with a merge commit.

Pull requests opened by GitHub Actions do not start other workflows, so CI does not run on the release pull request. It only changes the version and the changelog.

Xcode Cloud runs `ci_scripts/ci_post_clone.sh` to generate the project. Set `TOTTORO_DEVELOPMENT_TEAM` in the Xcode Cloud workflow.

App Store screenshots:

```sh
scripts/screenshots.sh
```

It writes the PNG files to `build/screenshots/`. The Mac screenshots are of the window only. Put them on a 16:10 background for the Mac App Store.

## Service icons

The logos in `Tottoro/Resources/ServiceIcons.xcassets` and the index `ServiceIcons.json` are generated. Do not edit them by hand. To update them, change `SIMPLE_ICONS_VERSION` in the script if needed, and run:

```sh
python3 scripts/generate-service-icons.py
```

It downloads Simple Icons and the 2FA Directory, and keeps only CC0 icons of services that support TOTP.

## App icon

The app icon is `Tottoro/Resources/AppIcon.icon`, and the development build uses the orange `AppIcon-Dev.icon`. Edit them in Icon Composer. The SVG drafts of the layers are in `Design/AppIcon/`, with a README.

## New files

- Put each screen's View and ViewModel in `Tottoro/Features/<Screen>/`.
- Put code used only on iPhone or only on Mac in `Tottoro/Platform/iOS/` or `Tottoro/Platform/macOS/`, and wrap the whole file in `#if os(...)`.
- Put pure computation in `TottoroKit/Sources/TottoroCore/`, and its tests in `TottoroKit/Tests/TottoroCoreTests/`.
- Use the tokens in `Tottoro/DesignSystem/` for colors, type, and spacing.
