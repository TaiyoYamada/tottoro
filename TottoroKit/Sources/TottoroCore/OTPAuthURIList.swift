//
//  OTPAuthURIList.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

/// 1 行に 1 つの otpauth の URL を並べたテキスト。Aegis と Ente Auth の書き出しがこの形。
/// Google Authenticator の移行用の URL（otpauth-migration）が混ざっていても読む。
enum OTPAuthURIList {
    /// otpauth の行が 1 つもなければ、この形式ではないので nil。
    static func importAccounts(from text: String) -> ImportedAccounts? {
        let lines = text.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.lowercased().hasPrefix("otpauth") }
        guard !lines.isEmpty else { return nil }

        var accounts: [Account] = []
        var skipped = 0
        for line in lines {
            if line.lowercased().hasPrefix("otpauth-migration:") {
                if let imported = try? GoogleMigrationParser.parse(line) {
                    accounts += imported.accounts
                    skipped += imported.skippedCount
                } else {
                    skipped += 1
                }
                continue
            }
            // Ente Auth は、ごみ箱に入れたコードも書き出す。消したつもりのものは取り込まない
            if isTrashedInEnte(line) {
                continue
            }
            // Ente Auth は、発行元やアカウント名の空白をそのまま書き出すことがある
            guard let account = try? OTPAuthURI.account(from: line.replacingOccurrences(of: " ", with: "%20")) else {
                skipped += 1
                continue
            }
            accounts.append(account)
        }
        return ImportedAccounts(accounts: accounts, skippedCount: skipped)
    }

    private static func isTrashedInEnte(_ line: String) -> Bool {
        guard let display = URLComponents(string: line.replacingOccurrences(of: " ", with: "%20"))?
            .queryItems?.first(where: { $0.name == "codeDisplay" })?.value,
            let object = try? JSONSerialization.jsonObject(with: Data(display.utf8)) as? [String: Any]
        else {
            return false
        }
        return object["trashed"] as? Bool == true
    }
}
