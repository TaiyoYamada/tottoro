//
//  OTPAuthURI.swift
//  RokketaCore
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation

/// 二要素認証の QR コードに入っている otpauth://totp/発行元:アカウント名?secret=... の解析。
/// 形式は Google Authenticator の Key Uri Format が事実上の標準になっている。
public enum OTPAuthURI {
    public enum ParseError: Error, Equatable {
        case invalidURL
        case unsupportedType
        case missingSecret
        case invalidSecret
        case unsupportedAlgorithm
        case invalidDigits
        case invalidPeriod
    }

    public static func account(from string: String) throws(ParseError) -> Account {
        guard let components = URLComponents(string: string), components.scheme?.lowercased() == "otpauth" else {
            throw .invalidURL
        }
        guard components.host?.lowercased() == "totp" else { throw .unsupportedType }

        var query: [String: String] = [:]
        for item in components.queryItems ?? [] where query[item.name.lowercased()] == nil {
            query[item.name.lowercased()] = item.value ?? ""
        }

        guard let secretText = query["secret"], !secretText.isEmpty else { throw .missingSecret }
        guard let secret = Base32.decode(secretText), !secret.isEmpty else { throw .invalidSecret }
        guard let algorithm = HashAlgorithm(otpauthName: query["algorithm"] ?? "SHA1") else {
            throw .unsupportedAlgorithm
        }
        guard let digits = Int(query["digits"] ?? "6"), (6...8).contains(digits) else { throw .invalidDigits }
        guard let period = Int(query["period"] ?? "30"), period > 0 else { throw .invalidPeriod }

        // ラベルは「発行元:アカウント名」か「アカウント名」だけ。issuer パラメータがあればそちらを優先する
        let label = String(components.path.dropFirst())
        // 「GitHub:」のようにアカウント名が空でも、発行元とアカウント名を取り違えないよう空の要素を残す
        let labelParts = label.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        let labelIssuer = labelParts.count == 2 ? String(labelParts[0]) : ""
        let name = String(labelParts.last ?? "")
        let issuer = query["issuer"] ?? labelIssuer

        return Account(
            issuer: issuer.trimmingCharacters(in: .whitespaces),
            name: name.trimmingCharacters(in: .whitespaces),
            secret: secret,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
    }
}
