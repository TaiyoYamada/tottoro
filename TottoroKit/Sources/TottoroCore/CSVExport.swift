//
//  CSVExport.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

/// CSV の書き出し。Bitwarden Authenticator と、Apple の「パスワード」アプリの形を読む。
/// パスワード管理のアプリの書き出しには、コードのない行（パスワードだけの行）が多いので、それは数えない。
enum CSVExport {
    /// Bitwarden は login_totp、Apple の「パスワード」は OTPAuth という見出しにコードを入れる
    private static let codeColumns = ["login_totp", "otpauth", "totp"]
    private static let issuerColumns = ["name", "title"]
    private static let nameColumns = ["login_username", "username"]
    private static let urlColumns = ["login_uri", "url"]

    /// コードの列がなければ、この形式ではないので nil。
    static func importAccounts(from text: String) -> ImportedAccounts? {
        guard let table = CSVTable(text), let codeColumn = table.column(named: codeColumns) else { return nil }
        let issuerColumn = table.column(named: issuerColumns)
        let nameColumn = table.column(named: nameColumns)
        let urlColumn = table.column(named: urlColumns)

        var accounts: [Account] = []
        var skipped = 0
        for row in table.rows {
            let code = value(in: row, at: codeColumn)
            guard !code.isEmpty else { continue }
            guard var account = BitwardenAuthenticatorExport.account(
                fromTOTPField: code,
                issuer: value(in: row, at: issuerColumn),
                name: value(in: row, at: nameColumn),
            ) else {
                skipped += 1
                continue
            }
            // サイトの URL があれば、自動入力の候補を出すドメインにする
            account.domain = URL(string: value(in: row, at: urlColumn))?.host()?.lowercased()
            accounts.append(account)
        }
        return ImportedAccounts(accounts: accounts, skippedCount: skipped)
    }

    private static func value(in row: [String], at column: Int?) -> String {
        guard let column, row.indices.contains(column) else { return "" }
        return row[column].trimmingCharacters(in: .whitespaces)
    }
}
