//
//  HashAlgorithm.swift
//  RokketaCore
//
//  Created by 山田大陽 on 2026/10/18.
//

public enum HashAlgorithm: String, Codable, CaseIterable, Sendable {
    case sha1
    case sha256
    case sha512

    /// otpauth の URL の algorithm パラメータ（SHA1 など）から作る。
    public init?(otpauthName: String) {
        switch otpauthName.uppercased() {
        case "SHA1": self = .sha1
        case "SHA256": self = .sha256
        case "SHA512": self = .sha512
        default: return nil
        }
    }
}
