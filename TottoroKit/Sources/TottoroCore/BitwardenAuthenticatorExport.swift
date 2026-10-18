//
//  BitwardenAuthenticatorExport.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

/// Bitwarden Authenticator の JSON の書き出し。暗号化の選択肢はない。
enum BitwardenAuthenticatorExport {
    private struct File: Decodable {
        let encrypted: Bool
        let items: [Item]
    }

    private struct Item: Decodable {
        let name: String?
        let login: Login?
    }

    private struct Login: Decodable {
        let totp: String?
        let username: String?
    }

    static func importAccounts(from data: Data) throws(ExportFileImporter.ImportError) -> ImportedAccounts {
        let file: File
        do {
            file = try JSONDecoder().decode(File.self, from: data)
        } catch {
            throw .invalidFile
        }
        guard !file.encrypted else { throw .unsupportedFile }

        // コードのない項目（メモなど）は、数えずに飛ばす
        let codes = file.items.compactMap { item in item.login?.totp.map { (item, $0) } }
        let accounts = codes.compactMap { item, totp in
            account(fromTOTPField: totp, issuer: item.name ?? "", name: item.login?.username ?? "")
        }
        return ImportedAccounts(accounts: accounts, skippedCount: codes.count - accounts.count)
    }

    /// Bitwarden の TOTP の欄には、otpauth の URL、steam:// の URL、秘密鍵そのもの、のどれかが入る。
    /// CSV の書き出しでも同じ欄を使う。
    static func account(fromTOTPField field: String, issuer: String, name: String) -> Account? {
        let field = field.trimmingCharacters(in: .whitespaces)
        if field.lowercased().hasPrefix("otpauth:") {
            guard var account = try? OTPAuthURI.account(from: field) else { return nil }
            // Android 版は、ラベルを HTML の文字参照に直して書き出す
            account.issuer = decodingHTMLEntities(account.issuer.isEmpty ? issuer : account.issuer)
            account.name = decodingHTMLEntities(account.name.isEmpty ? name : account.name)
            return account
        }
        // steam:// は 5 桁のコードで、Tottoro は扱えない
        if field.contains("://") {
            return nil
        }
        return ExportFileImporter.account(
            issuer: issuer,
            name: name,
            base32Secret: field,
            algorithm: "SHA1",
            digits: 6,
            period: 30,
        )
    }

    private static func decodingHTMLEntities(_ text: String) -> String {
        // &amp; は最後に戻さないと、&amp;lt; が < になってしまう
        [("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'"), ("&#x27;", "'"), ("&amp;", "&")]
            .reduce(text) { $0.replacingOccurrences(of: $1.0, with: $1.1) }
    }
}
