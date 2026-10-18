# 構成

## ターゲット

| ターゲット | 種類 | 中身 |
|---|---|---|
| `Rokketa` | アプリ（iPhone と Mac） | 画面のすべて。Mac Catalyst は使わず、1 つのターゲットで両方をビルドする |
| `RokketaAutoFill` | 自動入力の拡張（iPhone と Mac） | Safari やアプリの入力欄にコードを渡す |
| `RokketaKit` | ローカルの Swift Package | アプリと拡張の両方が使う処理 |
| `RokketaTests` | 単体テスト | アプリの ViewModel のテスト |

`RokketaKit` は 2 つのライブラリに分かれています。

| ライブラリ | 中身 | 副作用 |
|---|---|---|
| `RokketaCore` | アカウントの型、TOTP の計算、Base32、otpauth の URL と Google の書き出し形式の解析、保存のプロトコル | なし |
| `RokketaStorage` | キーチェーンへの保存、自動入力の候補の OS への登録 | あり |

副作用のない計算を `RokketaCore` に集めているのは、`swift test` だけでテストを回せるようにするためです。キーチェーンは entitlements がないと動かないので、`RokketaStorage` のテストはありません。実機で確かめます。

## 層

MVVM です。

```text
View（SwiftUI）
  ↓ 触るのは ViewModel だけ
ViewModel（@Observable）
  ↓
AccountStore（アプリ全体で 1 つ）
  ↓ AccountRepository のプロトコル越し
KeychainAccountRepository（RokketaStorage）
```

- View は ViewModel だけを触り、ドメインの型や保存の仕組みに直接触りません。
- `AccountStore` はアカウント一覧の唯一の持ち主です。Mac では、メインのウィンドウとメニューバーが同じものを共有します。片方で追加したアカウントは、すぐにもう片方にも出ます。
- `AccountStore` は一覧が変わるたびに、自動入力の候補も登録し直します（`CredentialIdentityRegistrar`）。他の端末で追加されたアカウントも、読み直したときに候補に加わります。
- テストでは、`AccountRepository` をメモリに保存する偽物（`InMemoryAccountRepository`）に差し替えます。
- アプリと拡張のターゲットは、既定の actor を `MainActor` にしています（`SWIFT_DEFAULT_ACTOR_ISOLATION`）。`RokketaKit` は画面に依存しないので、既定のままです。

## フォルダ

```text
project.yml                 XcodeGen の設定。.xcodeproj はここから生成する
Rokketa/
  App/                      アプリの入口、AccountStore、AppLock、RootView
  Features/                 画面ごとに View と ViewModel を置く
    AccountList/            Authy と同じメインの画面
    AddAccount/             QR の読み取り、手入力、Google からの取り込み
    EditAccount/            名前、ドメイン、色の編集
    Lock/                   ロック中の画面
  Platform/
    Clipboard.swift         コードのコピー（iPhone と Mac で中身が違う）
    iOS/                    VisionKit のカメラ画面
    macOS/                  メニューバー、画面からの QR の読み取り
  DesignSystem/             余白、文字、色のトークンと、共通の部品
  Resources/                Assets.xcassets、Localizable.xcstrings
RokketaAutoFill/            自動入力の拡張
RokketaKit/                 ローカルの Swift Package
RokketaTests/               ViewModel のテスト。Features と同じ並び
docs/                       このドキュメント
```

`Platform/iOS` と `Platform/macOS` のファイルは、ファイル全体を `#if os(iOS)` / `#if os(macOS)` で囲んでいます。

## 画面

Authy の画面を SwiftUI で作り直しています。

- メインの画面は、上に選んだアカウントの大きなコード、下にアカウントの丸を格子状に並べます。上の背景は、選んだアカウントの色です。タップでコードをコピーし、長押し（Mac では右クリック）で編集や削除をします。
- 残り時間の円は、`TimelineView(.animation)` で、画面の描き直しに合わせて滑らかに減らします。
- Mac のメニューバーは、`MenuBarExtra` の `.window` スタイルで、検索欄とリストを出します。クリックでコピーします。
- OS 標準の部品（`NavigationStack`、`Form`、`List`、`ContentUnavailableView`）をそのまま使っています。iOS 26 / macOS 26 の Liquid Glass は、それだけで付きます。

## データの流れ

### 追加

```text
QR コード（カメラ / 写真 / Mac の画面）
  → 文字列（otpauth:// か otpauth-migration://）
  → AddAccountViewModel.handleScannedPayloads
  → OTPAuthURI / GoogleMigrationParser で Account にする
  → AccountStore.add
  → キーチェーンに保存し、自動入力の候補を登録し直す
```

### 同期

キーチェーンの項目に `kSecAttrSynchronizable` を付けているので、iCloud キーチェーンが iPhone と Mac の間で同期します。キーチェーンには「他の端末で変わった」という通知がありません。そのため、アプリが前面に来たときと、メニューバーを開いたときに読み直します。

### 自動入力

1. アプリが、ドメインを設定したアカウントを `ASCredentialIdentityStore` に登録する。
2. Safari などでコードの入力欄に入ると、OS がドメインの合う候補を出す。
3. 候補が選ばれると、拡張がロックの解除を求めてから、キーチェーンを読んでコードを計算して返す。

入力欄の「パスコード」ボタンから一覧を開いたときは、いま開いているサイトに合うアカウントを先頭にして、すべてを並べます。
