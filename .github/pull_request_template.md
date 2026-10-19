## What and why

<!-- What does this change, and why? Link the issue if there is one (Closes #123). -->

## How it was tested

<!-- Devices, OS versions, simulators, and what you tried. -->

## Checklist

- [ ] `mise run lint` passes
- [ ] Tests pass
- [ ] New user-facing strings are in the String Catalog (`Localizable.xcstrings`) in English and Japanese
- [ ] If this touches the Keychain, AutoFill, or the app lock, I checked on real devices:
  - [ ] Accounts sync between iPhone and Mac through iCloud Keychain
  - [ ] The AutoFill suggestion appears on a site with a matching domain
  - [ ] The lock is required before any code is shown, in the app and in AutoFill
- [ ] Docs are updated (`README.md`, `README.ja.md`, `docs/`) if behavior or setup changed
- [ ] The diff contains no real secrets, setup keys, otpauth URLs, or QR codes
