# Changelog

## [0.2.0](https://github.com/TaiyoYamada/tottoro/compare/v0.1.0...v0.2.0) (2026-10-20)


### Features

* 2FAS、Aegis、Bitwarden、パスワードの書き出しから取り込めるようにする ([49ac122](https://github.com/TaiyoYamada/tottoro/commit/49ac1226a81a41df1b3eb25f998c01b0f92a99a4))
* Authy と同じ形のメイン画面を追加 ([0edd0f8](https://github.com/TaiyoYamada/tottoro/commit/0edd0f83ef3a988b5cf770025d4a1dcb5b4a387e))
* **core:** Google Authenticator の書き出し用 QR コードを解析できるようにする ([3e44b5a](https://github.com/TaiyoYamada/tottoro/commit/3e44b5a77571bc97857d02ee357e8ede20866ba3))
* **core:** otpauth の URL を解析できるようにする ([92673f8](https://github.com/TaiyoYamada/tottoro/commit/92673f8b5cf23e64f3cbdd478dee6964ed7fb48d))
* **core:** アカウントの型と TOTP の計算を追加 ([2fa89e9](https://github.com/TaiyoYamada/tottoro/commit/2fa89e9a0cf1c25ef2b8b6a54576374ccf58a9e8))
* Credential Exchange で他のアプリからアカウントを受け取る ([64c71f4](https://github.com/TaiyoYamada/tottoro/commit/64c71f4227b8623645ad49042dd747df623dcf65))
* **ios:** App スイッチャーに写る画面を隠す ([0619dd4](https://github.com/TaiyoYamada/tottoro/commit/0619dd4fbfa7d9cf07af24a941a53ba20bc1f4ec))
* **macos:** メニューバーからコードをコピーできるようにする ([f71cfc6](https://github.com/TaiyoYamada/tottoro/commit/f71cfc666c75f8e89416e1f54931e888e07bf12a))
* OSS として公開する準備と、他のアプリからの取り込み、設定、サービスのロゴを入れる ([#1](https://github.com/TaiyoYamada/tottoro/issues/1)) ([7b990d4](https://github.com/TaiyoYamada/tottoro/commit/7b990d4997520f34a244e8cfeaf7837a4525895a))
* QR コードと手入力でアカウントを追加できるようにする ([56cf67e](https://github.com/TaiyoYamada/tottoro/commit/56cf67e00b40b439e25faae6614afb09eacff447))
* **storage:** キーチェーンへの保存と自動入力の候補の登録を追加 ([55085fc](https://github.com/TaiyoYamada/tottoro/commit/55085fc44bfef61efdbb0aae5ebf3af019c7ec19))
* アカウントの名前、ドメイン、色を編集できるようにする ([2945348](https://github.com/TaiyoYamada/tottoro/commit/2945348621e2afb6263a2d06711522ebc4cf98a5))
* アプリと自動入力の拡張にプライバシーマニフェストを足す ([530d935](https://github.com/TaiyoYamada/tottoro/commit/530d9356ded0d94259804893e0259eefd2b18eb2))
* アプリのアイコンを足し、開発版はオレンジにする ([70c620f](https://github.com/TaiyoYamada/tottoro/commit/70c620f57311f99faf5eb2c25ed55fa343494df5))
* アプリの入口と Face ID / Touch ID のロックを追加 ([af15e83](https://github.com/TaiyoYamada/tottoro/commit/af15e83f96a13569da786d3f4f2306e2663e62d1))
* コードを自動入力する拡張を追加 ([22c1dee](https://github.com/TaiyoYamada/tottoro/commit/22c1dee00481eff742c37956eb96e4fdde2b27e0))
* サービスのロゴを同梱して、アカウントの丸に出す ([d6c441b](https://github.com/TaiyoYamada/tottoro/commit/d6c441b0aa5756cbcd8bcfb9ca3bd18f8f53ce01))
* 同じアカウントを二重に取り込まないようにする ([b9c8b21](https://github.com/TaiyoYamada/tottoro/commit/b9c8b21de0a50a5f9fa27a765c05c538e2e598e5))
* 新しい文言を日本語に訳す ([d523f0b](https://github.com/TaiyoYamada/tottoro/commit/d523f0bdf7da65c574505a907eab43f4275612c6))
* 英語を元の言語にして、日本語を翻訳として持つ ([de1e1f1](https://github.com/TaiyoYamada/tottoro/commit/de1e1f1323390a6539997824ccb09f8cfda1d5a0))
* 設定の画面を足し、ロックまでの時間、コードを隠す、書き出しを選べるようにする ([fee9e07](https://github.com/TaiyoYamada/tottoro/commit/fee9e07d08401b9fdbd3f2976ee1c6a09580144e))


### Bug Fixes

* Face ID が使えないときとパスコードのない端末の扱いを決める ([edd4c32](https://github.com/TaiyoYamada/tottoro/commit/edd4c3222ffc83a7e090dc8e7d4c24ecb61e8dc6))
* Google Authenticator から取り込むアカウントを SHA-1 に固定する ([df65ed5](https://github.com/TaiyoYamada/tottoro/commit/df65ed5cc7cbb384b9d533d8998ff1850544383c))
* iPad で画面のすべての向きに対応し、App Store の検査を通るようにする ([18ffa22](https://github.com/TaiyoYamada/tottoro/commit/18ffa220fafef9a52436be8e99683736cfac09fb))
* iPad で画面のすべての向きに対応し、App Store の検査を通るようにする ([#3](https://github.com/TaiyoYamada/tottoro/issues/3)) ([f21731c](https://github.com/TaiyoYamada/tottoro/commit/f21731c10b7aa018e472ab75f61b214e288dea0b))
* Mac で単体テストのホストのアプリが見つからない問題を直す ([7f122b0](https://github.com/TaiyoYamada/tottoro/commit/7f122b0cfc8d399ee50c232d9e7738a4fb2432a0))
* アプリの名前を String Catalog で訳さないようにする ([bf22f33](https://github.com/TaiyoYamada/tottoro/commit/bf22f33d1b58b454c264026f764764da078fd1f5))
* 長押しで浮かぶアカウントの丸が四角く切れないようにする ([f70ea3d](https://github.com/TaiyoYamada/tottoro/commit/f70ea3d3987d08900735c11a725560aef66ccddd))
