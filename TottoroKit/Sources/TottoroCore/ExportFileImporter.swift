//
//  ExportFileImporter.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

/// 他の認証アプリが書き出したファイルを読む。中身を見て、どのアプリの形式かを決める。
/// 形式ごとの細かい違いは docs/import-formats.md にまとめている。
public enum ExportFileImporter {
    public enum ImportError: Error, Equatable, Sendable {
        /// どのアプリの書き出しでもない。
        case unsupportedFile
        /// 書き出しのときのパスワードで暗号化されている。
        case passwordRequired
        case wrongPassword
        /// 形式は分かったが、中身が壊れている。
        case invalidFile
    }

    /// 書き出しは数百件でも数百 KB に収まる。これより大きいファイルは、読み込む前に断る
    static let maximumFileSize = 10 * 1024 * 1024

    /// 暗号化されたファイルなら password が要る。nil を渡すと .passwordRequired を投げるので、聞いてから呼び直す。
    public static func importAccounts(from data: Data, password: String?) throws(ImportError) -> ImportedAccounts {
        guard data.count <= maximumFileSize else { throw .unsupportedFile }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if object["schemaVersion"] != nil, object["services"] != nil {
                return try TwoFASExport.importAccounts(from: data, password: password)
            }
            if object["header"] != nil, object["db"] != nil {
                return try AegisExport.importAccounts(from: data, password: password)
            }
            if object["items"] != nil, object["encrypted"] != nil {
                return try BitwardenAuthenticatorExport.importAccounts(from: data)
            }
            throw .unsupportedFile
        }

        guard let text = String(data: data, encoding: .utf8) else { throw .unsupportedFile }
        if let imported = CSVExport.importAccounts(from: text) {
            return imported
        }
        if let imported = OTPAuthURIList.importAccounts(from: text) {
            return imported
        }
        throw .unsupportedFile
    }

    /// 各形式から取り出した値を、Tottoro が扱えるアカウントにする。扱えなければ nil。
    /// 呼ぶ側で形式の項目をそのまま並べて渡せるよう、引数は分けたままにしている。
    static func account( // swiftlint:disable:this function_parameter_count
        issuer: String,
        name: String,
        base32Secret: String,
        algorithm: String,
        digits: Int,
        period: Int,
    ) -> Account? {
        // 2FAS は区切りに - を入れた秘密鍵を書き出すことがある
        let cleaned = base32Secret.replacingOccurrences(of: "-", with: "")
        guard let secret = Base32.decode(cleaned), !secret.isEmpty,
              let algorithm = HashAlgorithm(otpauthName: algorithm),
              (6 ... 8).contains(digits), period > 0
        else {
            return nil
        }
        return Account(
            issuer: issuer.trimmingCharacters(in: .whitespaces),
            name: name.trimmingCharacters(in: .whitespaces),
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            period: period,
        )
    }
}
