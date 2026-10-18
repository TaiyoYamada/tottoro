//
//  Account.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation

public struct Account: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var issuer: String
    public var name: String
    public var secret: Data
    public var algorithm: HashAlgorithm
    public var digits: Int
    public var period: Int
    /// 自動入力の候補を出すサイトのドメイン。otpauth の URL には含まれないので、ユーザーが設定する。
    public var domain: String?
    public var color: AccountColor
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        issuer: String,
        name: String,
        secret: Data,
        algorithm: HashAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        domain: String? = nil,
        color: AccountColor? = nil,
        createdAt: Date = Date(),
    ) {
        self.id = id
        self.issuer = issuer
        self.name = name
        self.secret = secret
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.domain = domain
        self.color = color ?? AccountColor.suggested(for: issuer)
        self.createdAt = createdAt
    }

    public var displayName: String {
        issuer.isEmpty ? name : issuer
    }

    /// 秘密鍵と計算の設定が同じなら、名前が違っても同じコードを出すので、同じアカウントとみなす。
    public func generatesSameCodes(as other: Account) -> Bool {
        secret == other.secret && algorithm == other.algorithm && digits == other.digits && period == other.period
    }

    /// サイトのホスト名がこのアカウントのドメインか、そのサブドメインなら true。
    public func matchesService(host: String) -> Bool {
        guard let domain else { return false }
        let host = host.lowercased()
        return host == domain || host.hasSuffix("." + domain)
    }
}
