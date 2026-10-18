# 開発

## 必要なもの

- Xcode 27 以降（Swift 6.4）
- XcodeGen（`brew install xcodegen`）
- 有料の Apple Developer Program のチーム。自動入力の権限（`com.apple.developer.authentication-services.autofill-credential-provider`）は、無料の Personal Team では署名できない

## 準備

1. `project.yml` の `DEVELOPMENT_TEAM` に、チームの ID を入れる。
2. プロジェクトを生成する。

   ```sh
   xcodegen generate
   ```

3. `Rokketa.xcodeproj` を開く。初回は swift-protobuf の build plugin を信頼するか聞かれるので、許可する。

`Rokketa.xcodeproj` は生成物なので、Git には入れず、手で直しません。ターゲットや設定を変えるときは `project.yml` を直して、生成し直します。

## ビルド

コマンドラインでは、swift-protobuf の build plugin を信頼する `-skipPackagePluginValidation` が要ります。

```sh
# Mac
xcb build -project Rokketa.xcodeproj -scheme Rokketa \
  -destination 'platform=macOS,arch=arm64' -skipPackagePluginValidation

# iPhone のシミュレータ
xcb build -project Rokketa.xcodeproj -scheme Rokketa \
  -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation
```

swift-protobuf の build plugin は、`protoc` を C++ のソースからビルドします。そのため、まっさらな状態からの初回のビルドだけ数分かかります。

## テスト

```sh
# RokketaCore（TOTP の計算や QR コードの解析）
cd RokketaKit && swift test

# アプリの ViewModel
xcb test -project Rokketa.xcodeproj -scheme Rokketa \
  -destination 'platform=iOS Simulator,name=iPhone 17' -skipPackagePluginValidation
```

## 実機で確かめること

キーチェーンと自動入力は、シミュレータや単体テストでは確かめきれません。実機で次を見ます。

- iPhone で追加したアカウントが、Mac にも出る（iCloud キーチェーンの同期）
- 設定の「一般 > 自動入力とパスワード」（Mac はシステム設定の同じ項目）で Rokketa をオンにすると、ドメインを設定したサイトでコードの候補が出る
- Mac の「画面から読み取る」で、初回に画面収録の許可を求められ、許可すると読み取れる

## 新しいファイル

- 画面は `Rokketa/Features/<画面名>/` に View と ViewModel を置く。
- iPhone か Mac だけで使うものは `Rokketa/Platform/iOS/` か `Rokketa/Platform/macOS/` に置き、ファイル全体を `#if os(...)` で囲む。
- 副作用のない計算は `RokketaKit/Sources/RokketaCore/` に置き、`RokketaKit/Tests/RokketaCoreTests/` にテストを書く。
- 色、文字、余白は `Rokketa/DesignSystem/` のトークンを使う。
