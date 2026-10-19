# Import formats

Tottoro reads the export files of other authenticator apps, and receives accounts through Credential Exchange. `ExportFileImporter` in `TottoroCore` looks at the content, not the file name, to decide the format.

Each format below was checked against the source code of the app that writes it. Only TOTP codes with 6 to 8 digits and SHA-1, SHA-256 or SHA-512 are imported. Other entries, such as counter-based codes (HOTP) and Steam codes, are counted as skipped and shown to the person.

The same account is not added twice. An account counts as the same when its secret, algorithm, digits and period match one that is already in Tottoro, even if the names differ.

## 2FAS (`.2fas`)

JSON with `schemaVersion` (up to 4) and `services`. Each service has `name`, `secret` (base32) and `otp` with `account`, `issuer`, `digits`, `period`, `algorithm` and `tokenType`. Old versions without `otp` are all TOTP.

An encrypted backup has an empty `services` and puts them in `servicesEncrypted`: `base64(ciphertext + tag):base64(salt):base64(iv)`.

- Key: PBKDF2-HMAC-SHA256 with 10,000 rounds, 32 bytes. This is far below today's recommendation, but it is what 2FAS uses.
- Cipher: AES-256-GCM with a 12-byte IV and the 16-byte tag at the end of the ciphertext.
- The salt is 32 bytes from the iOS app and 256 bytes from the Android app, so its length is read from the file.
- A wrong password shows up as a failed GCM tag.

Sources: [2fas-ios](https://github.com/twofas/2fas-ios/blob/17a5ca5381bed2226ea6dc92180e62287effa605/TwoFAS/Protection/ExchangeFileEncryption.swift), [2fas-android](https://github.com/twofas/2fas-android/blob/56d7444789caca73a6b772ab17a110cc7f4766c2/core/cipher/src/main/java/com/twofasapp/cipher/backup/internal/BackupKeyGeneratorPbkdf.kt).

## Aegis (`.json`, `.txt`)

JSON with `version: 1`, `header` and `db`. In a plain vault, `header.slots` is null and `db` is the content. Entries have `type`, `name`, `issuer` and `info` with `secret`, `algo`, `digits` and `period`.

In an encrypted vault, `db` is base64:

1. For a password slot (`type: 1`), the key-encryption key is scrypt(password, `salt`, N = `n`, r = `r`, p = `p`, 32 bytes).
2. That key opens the slot's `key` with AES-256-GCM (`key_params.nonce`, `key_params.tag`). The result is the master key.
3. The master key opens `db` with AES-256-GCM (`header.params.nonce`, `header.params.tag`).

Tottoro refuses scrypt parameters that would need more than 256 MB of memory, so that a crafted file cannot use up the memory. Aegis's default (N = 32768, r = 8, p = 1) needs about 32 MB.

Aegis can also export a text file with one `otpauth://` URI per line. Tottoro reads it like any otpauth list.

Source: [docs/vault.md](https://github.com/beemdevelopment/Aegis/blob/d6f4e5925a97e4e91593f1542085eae03432a759/docs/vault.md).

## Bitwarden Authenticator (`.json`, `.csv`)

The export cannot be encrypted.

- JSON: `{encrypted, items}`. Each item has `name` and `login.totp`, and on iOS also `login.username`.
- CSV: the column `login_totp`. The iOS app puts blank lines between rows. The Android app writes rows with more fields than the header.

`login.totp` is one of the following:

- an `otpauth://` URI. The Android app writes the label with HTML entities, such as `&amp;`, which Tottoro decodes.
- `steam://...`, which is skipped.
- a bare base32 secret, read as TOTP with SHA-1, 6 digits and 30 seconds.

Sources: [bitwarden/ios](https://github.com/bitwarden/ios/blob/c34af98c96c83c43f481f43539f691ccd1b46734/AuthenticatorShared/Core/Vault/Services/ExportItemsService.swift), [bitwarden/android](https://github.com/bitwarden/android/blob/1470154cf3d3d0511cdbe5bfc6493971b6478edf/authenticator/src/main/kotlin/com/bitwarden/authenticator/data/authenticator/repository/AuthenticatorRepositoryImpl.kt).

## Apple Passwords (`.csv`)

Apple does not document the columns. Exports seen in practice have the header `Title,URL,Username,Password,Notes,OTPAuth`, with an `otpauth://` URI in `OTPAuth`. Tottoro looks the columns up by name, and uses the host of `URL` as the account's AutoFill domain. Rows without a code, which are most rows in a password export, are ignored and not counted. This has not been checked against a real export yet.

## Ente Auth and other otpauth lists (`.txt`)

One `otpauth://` URI per line. Ente Auth writes some labels with spaces left unencoded, and also exports codes that are in its trash, marked with `codeDisplay` containing `"trashed": true`. Tottoro encodes the spaces and leaves trashed codes out. `otpauth-migration://` lines from Google Authenticator in the same file are read too.

Ente Auth's encrypted export uses Argon2id and XChaCha20-Poly1305, which are not supported.

Source: [ente-io/ente](https://github.com/ente-io/ente/blob/f4cdad4b7e4d292e88de65b668a2e11afb7fcbe8/mobile/apps/auth/lib/ui/settings/data/export_widget.dart).

## Credential Exchange

iOS 26 and macOS 26 can move credentials between apps through the system, using the FIDO Alliance's Credential Exchange Format (CXF). Nothing is written to a file.

- Import: when another app exports to Tottoro, the system opens Tottoro with the activity `ASCredentialExchangeActivity`. Tottoro waits until it is unlocked, then calls `ASCredentialImportManager.importCredentials(token:)`. Only TOTP credentials are used. Passwords and passkeys in the same export are ignored.
- Export: Settings > Export to Another App. Tottoro asks the person to confirm it is them, even when the app is already unlocked, then calls `ASCredentialExportManager`.
- The AutoFill extension declares `SupportsCredentialExchange` and `SupportedCredentialExchangeVersions` (1.0) in its `Info.plist`, and the app lists the activity in `NSUserActivityTypes`.
- CXF names the exporting app with a relying party identifier (a domain). Tottoro has no domain of its own, so it uses `taiyoyamada.github.io`.
