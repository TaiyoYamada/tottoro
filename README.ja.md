[English](README.md) | 日本語

# Tottoro

iPhone と Mac で使う、二要素認証のコードのアプリです。Authy の代わりとして、SwiftUI と Apple のフレームワークで作っています。ほかに使っているライブラリは、Apple の swift-protobuf（Google Authenticator の書き出し用 QR コードを読む）と swift-crypto（他のアプリの暗号化した書き出しを開く）だけです。

- QR コードを読み取って、6〜8 桁のコード（TOTP）を表示する
- iPhone はカメラか写真、Mac は画面に表示した QR コードから読み取れる
- Google Authenticator の書き出し用 QR コードから、まとめて取り込める。2FAS、Aegis、Bitwarden Authenticator、Apple の「パスワード」の書き出しのファイルも、暗号化したものを含めて読める
- OS の Credential Exchange で、他のアプリとアカウントを受け渡しできる
- GitHub や Google など、サービスのロゴを出す。ロゴはアプリに同梱している
- 秘密鍵は iCloud キーチェーンで同期する。自前のサーバーはない
- Mac はメインのウィンドウとメニューバーの両方から使える
- Safari やアプリの入力欄に、コードを自動入力できる
- 開くときに Face ID / Touch ID でロックを解除する。タップするまでコードを隠すこともできる

## 動かす

先に [mise](https://mise.jdx.dev) を入れておきます（`brew install mise`）。

```sh
mise run setup
open Tottoro.xcodeproj
```

署名のチームの設定（`Local.xcconfig`）など、詳しい手順は [docs/development.md](docs/development.md) にあります。

## ドキュメント

ドキュメントは英語で書いています。

- [docs/architecture.md](docs/architecture.md): ターゲット、層、フォルダの構成とデータの流れ
- [docs/security.md](docs/security.md): 何を何で守っているか、守れていないもの
- [docs/one-time-codes.md](docs/one-time-codes.md): TOTP の計算と、取り込める QR コードの形式
- [docs/import-formats.md](docs/import-formats.md): 取り込める他のアプリの書き出しの形式
- [docs/privacy.md](docs/privacy.md): プライバシーポリシー
- [docs/development.md](docs/development.md): 開発の準備、ビルド、テスト

## 開発に参加する

[CONTRIBUTING.md](CONTRIBUTING.md) を読んでください。質問やアイデアは [Discussions](https://github.com/TaiyoYamada/tottoro/discussions) で受け付けています。

## セキュリティ

脆弱性は公開の Issue に書かないでください。報告の方法は [SECURITY.md](SECURITY.md) にあります。

## ライセンス

Apache License 2.0 です。[LICENSE](LICENSE) を見てください。
