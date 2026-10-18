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
    public struct Result: Equatable, Sendable {
        public let accounts: [Account]
        /// HOTP や MD5 など、Tottoro が扱えずに飛ばした件数。
        public let skippedCount: Int
    }

    public enum ParseError: Error, Equatable {
        case invalidURL
        case invalidPayload
    }

    public static func parse(_ string: String) throws(ParseError) -> Result {
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
        return Result(accounts: accounts, skippedCount: payload.otpParameters.count - accounts.count)
    }

    private static func account(from parameters: MigrationPayload.OtpParameters) -> Account? {
        guard parameters.type == .totp, !parameters.secret.isEmpty else { return nil }

        let algorithm: HashAlgorithm
        switch parameters.algorithm {
        case .unspecified, .sha1: algorithm = .sha1
        case .sha256: algorithm = .sha256
        case .sha512: algorithm = .sha512
        case .md5, .UNRECOGNIZED: return nil
        }

        let digits: Int
        switch parameters.digits {
        case .unspecified, .six: digits = 6
        case .eight: digits = 8
        case .UNRECOGNIZED: return nil
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
            algorithm: algorithm,
            digits: digits,
        )
    }
}
