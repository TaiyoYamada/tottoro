//
//  GoogleMigrationParser.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import SwiftProtobuf

/// Google Authenticator の書き出し用 QR コード（otpauth-migration://offline?data=...）の解析。
/// アカウントが多いと QR コードが複数枚に分かれるが、1 枚ずつ独立して読める。
public enum GoogleMigrationParser {
    public enum ParseError: Error, Equatable {
        case invalidURL
        case invalidPayload
    }

    public static func parse(_ string: String) throws(ParseError) -> ImportedAccounts {
        guard let components = URLComponents(string: string),
              components.scheme?.lowercased() == "otpauth-migration",
              let dataText = components.queryItems?.first(where: { $0.name == "data" })?.value,
              let data = Data(base64Encoded: dataText)
        else {
            throw .invalidURL
        }

        let payload: MigrationPayload
        do {
            payload = try MigrationPayload(serializedBytes: data)
        } catch {
            throw .invalidPayload
        }

        var accounts: [Account] = []
        for parameters in payload.otpParameters {
            guard let account = account(from: parameters) else { continue }
            accounts.append(account)
        }
        return ImportedAccounts(accounts: accounts, skippedCount: payload.otpParameters.count - accounts.count)
    }

    private static func account(from parameters: MigrationPayload.OtpParameters) -> Account? {
        guard parameters.type == .totp, !parameters.secret.isEmpty else { return nil }

        // Google Authenticator は algorithm と digits を正しく書き出さないことがあるので、
        // Bitwarden Authenticator と同じく SHA-1 に固定し、桁数は 8 と書かれたときだけ 8 にする
        let digits = switch parameters.digits {
        case .eight: 8
        case .unspecified, .six, .UNRECOGNIZED: 6
        }

        // name には「発行元:アカウント名」の形で発行元が重ねて入っていることがある
        var name = parameters.name
        if !parameters.issuer.isEmpty, name.hasPrefix(parameters.issuer + ":") {
            name = String(name.dropFirst(parameters.issuer.count + 1))
        }

        return Account(
            issuer: parameters.issuer,
            name: name.trimmingCharacters(in: .whitespaces),
            secret: parameters.secret,
            algorithm: .sha1,
            digits: digits,
        )
    }
}
