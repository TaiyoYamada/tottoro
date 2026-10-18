# Contributing to Tottoro

Thank you for helping. Bug reports, ideas, translations, and code are all welcome.

- Questions and ideas: [Discussions](https://github.com/TaiyoYamada/tottoro/discussions)
- Bugs: [Issues](https://github.com/TaiyoYamada/tottoro/issues/new/choose)
- Vulnerabilities: never in public. See [SECURITY.md](SECURITY.md).

Everyone taking part follows the [Code of Conduct](CODE_OF_CONDUCT.md).

## Never share real secrets

Tottoro handles two-factor authentication secrets. In issues, pull requests, tests, screenshots, and logs, never include a real setup key, an `otpauth://` or `otpauth-migration://` URL, or a QR code image from a real account. Use made-up values, such as the ones in the existing tests. The Git hooks and CI scan for secrets, but they cannot catch everything.

## Getting set up

```sh
brew install mise
mise run setup
```

Then put your signing team and a bundle ID prefix of your own in `Local.xcconfig`. [docs/development.md](docs/development.md) has the details, and explains the tests, the lint rules, and the Git hooks.

## Branches and pull requests

- `develop` is the default branch. Open your pull request against `develop`.
- `main` holds released code. It is only updated by pull requests from `develop`.
- Keep a pull request to one change. Open an issue or a discussion first for a large change, so we can agree on the approach before you spend time on it.
- Pull requests from contributors are merged with squash, so the pull request title becomes the commit message. Write the title in the same format as a commit message.

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org). English or Japanese is fine.

```text
feat: show the code in a widget
fix(macos): clear the copied code after a minute
docs: explain how to record snapshots
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. A scope such as `macos` or `autofill` is optional. The commit-msg hook checks the format. The release notes are made from these messages, so describe the change from the user's point of view where you can.

## Before you open a pull request

- `mise run lint` passes. The pre-commit hook formats and lints the files you commit.
- The tests pass. Add tests for new logic, especially in `TottoroCore`.
- New UI text is in English in the code, with a Japanese translation in the String Catalog. See [Localization](docs/development.md#localization).
- If you changed a screen on purpose, record its snapshots again. See [Snapshot tests](docs/development.md#snapshot-tests).
- If you touched the Keychain, AutoFill, or the lock, check them on real devices. See [Things to check on a real device](docs/development.md#things-to-check-on-a-real-device).
- If you changed how something works, update the docs in `docs/`.

## Translations

Translations go in the String Catalogs (`*.xcstrings`). Open them in Xcode to edit them. To add a new language, open an issue first, so we can make sure it will be kept up to date.

## License

By contributing, you agree that your contributions are licensed under the [Apache License 2.0](LICENSE), the same as the rest of the project.
