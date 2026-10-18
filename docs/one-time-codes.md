# コードの仕組み

## TOTP

二要素認証の 6 桁のコードは、ほとんどが TOTP（RFC 6238）です。サイトと Rokketa が同じ秘密鍵を持ち、同じ時刻から同じコードを計算します。通信はしません。

計算は `TOTPGenerator` にあります。

1. 1970 年からの秒数を、間隔（ふつうは 30 秒）で割って、カウンタにする。カウンタは 30 秒ごとに 1 増える。
2. カウンタを 8 バイトのビッグエンディアンにして、秘密鍵で HMAC を取る。ハッシュはふつう SHA-1 で、SHA-256 と SHA-512 もある。計算には CryptoKit の `HMAC` を使う。
3. 動的切り詰め（dynamic truncation）をする。HMAC の最後のバイトの下位 4 ビットを位置にして、そこから 4 バイトを取り出し、先頭の 1 ビットを落として 31 ビットの数にする。
4. その数を 10 の桁数乗で割った余りを、先頭を 0 で埋めて桁数にそろえる。

手順 2〜4 は HOTP（RFC 4226）そのものです。TOTP は、HOTP のカウンタに時刻を使ったものです。

テストは、RFC 6238 の付録 B にある検証用の値を使っています（`TOTPGeneratorTests`）。

## 秘密鍵の形式

サイトは秘密鍵を Base32（RFC 4648）で配ります。A〜Z と 2〜7 の 32 文字だけを使うので、人が読み上げたり打ち込んだりしやすい形式です。`Base32` は、大文字小文字、空白、パディングの `=` を無視して読みます。

## 取り込める QR コード

### otpauth://

サイトの二要素認証の設定画面に出る QR コードです。Google Authenticator の Key Uri Format が、事実上の標準になっています。

```text
otpauth://totp/GitHub:octocat?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&algorithm=SHA1&digits=6&period=30
```

| 部分 | 意味 | 省略したとき |
|---|---|---|
| `totp` | 種類。`hotp`（回数で変わるコード）には対応していない | 省略できない |
| `GitHub:octocat` | ラベル。「発行元:アカウント名」か「アカウント名」だけ | 省略できない |
| `secret` | Base32 の秘密鍵 | 省略できない |
| `issuer` | 発行元。ラベルの発行元より優先する | ラベルの発行元 |
| `algorithm` | `SHA1` / `SHA256` / `SHA512` | `SHA1` |
| `digits` | 桁数。6〜8 | 6 |
| `period` | 間隔（秒） | 30 |

解析は `OTPAuthURI` にあります。

### otpauth-migration://（Google Authenticator）

Google Authenticator の「アカウントを移行」で出る QR コードです。

```text
otpauth-migration://offline?data=<Base64>
```

`data` の中身は protobuf です。Google は形式を公開していないので、利用者が解析して広く使われている定義（`google_auth_migration.proto`）を使っています。Swift のコードは swift-protobuf の build plugin がビルドのたびに生成するので、リポジトリには入っていません。

- アカウントが多いと、QR コードが複数枚に分かれます。1 枚ずつ独立して読めるので、順に読み取れば全部入ります。
- HOTP と MD5 のアカウントは飛ばし、飛ばした件数を画面に出します。

解析は `GoogleMigrationParser` にあります。

### Authy

Authy には公式の書き出し機能がありません。Authy から移るときは、各サイトの二要素認証の設定画面で QR コードを出し直して、Rokketa で読み取ります。
