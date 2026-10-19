English | [日本語](README.ja.md)

# Tottoro

A two-factor authentication code app for iPhone and Mac. It is a replacement for Authy, built with SwiftUI and Apple's frameworks. The only other libraries are Apple's swift-protobuf, to read Google Authenticator's export QR codes, and swift-crypto, to open encrypted exports from other apps.

- Scans QR codes and shows 6 to 8 digit codes (TOTP)
- Reads QR codes from the camera or Photos on iPhone, and from the screen on Mac
- Imports many accounts at once from Google Authenticator's export QR codes, and from export files of 2FAS, Aegis, Bitwarden Authenticator, and Apple Passwords, including encrypted ones
- Moves accounts to and from other apps with the system's Credential Exchange
- Shows the logo of each service, such as GitHub or Google, with logos built into the app
- Syncs secrets with iCloud Keychain. There is no server of its own
- On Mac, works from both the main window and the menu bar
- Fills in codes in Safari and in app text fields with AutoFill
- Unlocks with Face ID / Touch ID when you open it, and can hide codes until you tap them

## Run it

Install [mise](https://mise.jdx.dev) first (`brew install mise`). Then:

```sh
mise run setup
open Tottoro.xcodeproj
```

Setting your signing team (`Local.xcconfig`) and the other steps are in [docs/development.md](docs/development.md).

## Docs

- [docs/architecture.md](docs/architecture.md): targets, layers, folders, and how data flows
- [docs/security.md](docs/security.md): what is protected and how, and what is not
- [docs/one-time-codes.md](docs/one-time-codes.md): how TOTP codes are computed, and which QR code formats can be imported
- [docs/import-formats.md](docs/import-formats.md): the export files of other apps that can be imported
- [docs/privacy.md](docs/privacy.md): privacy policy
- [docs/development.md](docs/development.md): setup, building, and testing

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Ask questions and share ideas in [Discussions](https://github.com/TaiyoYamada/tottoro/discussions).

## Security

Do not report vulnerabilities in public issues. See [SECURITY.md](SECURITY.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).
