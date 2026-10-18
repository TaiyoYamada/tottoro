# Tottoro

iPhone と Mac で使う、二要素認証のコードのアプリです。Authy の代わりとして、SwiftUI と Apple の標準フレームワークだけで作っています。

- QR コードを読み取って、6〜8 桁のコード（TOTP）を表示する
- iPhone はカメラか写真、Mac は画面に表示した QR コードから読み取れる
- Google Authenticator の書き出し用 QR コードから、まとめて取り込める
- 秘密鍵は iCloud キーチェーンで同期する。自前のサーバーはない
- Mac はメインのウィンドウとメニューバーの両方から使える
- Safari やアプリの入力欄に、コードを自動入力できる
- 開くときに Face ID / Touch ID でロックを解除する

## 動かす

```sh
xcodegen generate
open Tottoro.xcodeproj
```

署名のチームの設定など、詳しい手順は [docs/development.md](docs/development.md) にあります。

## ドキュメント

- [docs/architecture.md](docs/architecture.md): ターゲット、層、フォルダの構成とデータの流れ
- [docs/security.md](docs/security.md): 何を何で守っているか、守れていないもの
- [docs/one-time-codes.md](docs/one-time-codes.md): TOTP の計算と、取り込める QR コードの形式
- [docs/development.md](docs/development.md): 開発の準備、ビルド、テスト
