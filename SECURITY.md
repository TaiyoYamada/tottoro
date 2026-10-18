# Security Policy

Tottoro stores two-factor authentication secrets. Please report security problems privately so they can be fixed before they are public.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting: open the [Security tab](https://github.com/TaiyoYamada/tottoro/security) and choose "Report a vulnerability", or go straight to the [new advisory form](https://github.com/TaiyoYamada/tottoro/security/advisories/new).

Please include:

- What the problem is and what an attacker could do with it
- Steps to reproduce
- Device, OS version, and app version (or the commit on `develop`)

Do not:

- Open a public issue, pull request, or discussion about the vulnerability.
- Include real 2FA secrets, setup keys, `otpauth://` or `otpauth-migration://` URLs, or QR code images. Create a test account or use a made-up secret such as `JBSWY3DPEHPK3PXP`.

## Supported versions

| Version | Supported |
|---|---|
| Latest App Store release (iOS and macOS) | Yes |
| `develop` branch | Yes |
| Older releases | No |

## Scope

Examples of issues we want to hear about:

- Secrets leaking out of the Keychain, or into logs, crash reports, or other files
- Bypassing the app lock (Face ID / Touch ID) to see codes
- The AutoFill extension returning codes without asking the user to unlock
- Codes leaking through the clipboard (for example, not expiring on iPhone, or syncing through Universal Clipboard)
- Parsing bugs in `otpauth://` or `otpauth-migration://` QR codes, such as crashes or wrong accounts from crafted input

Some limits are known and by design, such as the passcode fallback for the lock and the lack of per-item biometric protection on synced Keychain items. See [docs/security.md](docs/security.md) for the threat model and the list of known limitations.
