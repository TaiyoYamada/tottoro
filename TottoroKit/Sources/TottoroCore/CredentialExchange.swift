//
//  CredentialExchange.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import AuthenticationServices
import Foundation

/// OS の Credential Exchange（FIDO Alliance の Credential Exchange Format）と、アカウントを相互に変換する。
/// 受け渡し自体は OS が仲立ちするので、秘密鍵がファイルとして残ることはない。
public enum CredentialExchange {
    /// CXF の exporterRpId は書き出したアプリをドメインの形で表す。Tottoro は自分のドメインを持たないので、
    /// 公開しているリポジトリの持ち主のドメインを使う
    public static let exporterRelyingPartyIdentifier = "taiyoyamada.github.io"

    public static func exportedData(
        from accounts: [Account],
        formatVersion: ASExportedCredentialData.FormatVersion,
        exportedAt date: Date,
    ) -> ASExportedCredentialData {
        let items = accounts.map { account in
            let scope = account.domain
                .flatMap { URL(string: "https://\($0)") }
                .map { ASImportableCredentialScope(urls: [$0]) }
            return ASImportableItem(
                id: Data(account.id.uuidString.utf8),
                created: account.createdAt,
                lastModified: account.createdAt,
                title: account.displayName,
                subtitle: account.name.isEmpty || account.name == account.displayName ? nil : account.name,
                scope: scope,
                credentials: [.totp(totp(for: account))],
            )
        }
        // CXF の Account は「パスワード管理のアプリの利用者」を表す。Tottoro には利用者のアカウントがないので、空の 1 人にまとめる
        let owner = ASImportableAccount(
            id: Data(UUID().uuidString.utf8),
            userName: "",
            email: "",
            collections: [],
            items: items,
        )
        return ASExportedCredentialData(
            accounts: [owner],
            formatVersion: formatVersion,
            exporterRelyingPartyIdentifier: exporterRelyingPartyIdentifier,
            exporterDisplayName: "Tottoro",
            timestamp: date,
        )
    }

    /// 受け取ったデータのうち、TOTP だけを取り込む。パスワードやパスキーは Tottoro の扱うものではないので数えない。
    public static func accounts(from data: ASExportedCredentialData) -> ImportedAccounts {
        var accounts: [Account] = []
        var skipped = 0
        for item in data.accounts.flatMap(\.items) {
            for credential in item.credentials {
                guard case let .totp(totp) = credential else { continue }
                guard let account = account(from: totp, in: item) else {
                    skipped += 1
                    continue
                }
                accounts.append(account)
            }
        }
        return ImportedAccounts(accounts: accounts, skippedCount: skipped)
    }

    private static func totp(for account: Account) -> ASImportableCredential.TOTP {
        let algorithm: ASImportableCredential.TOTP.Algorithm = switch account.algorithm {
        case .sha1: .sha1
        case .sha256: .sha256
        case .sha512: .sha512
        }
        return ASImportableCredential.TOTP(
            secret: account.secret,
            period: UInt16(account.period),
            digits: UInt16(account.digits),
            userName: account.name.isEmpty ? nil : account.name,
            algorithm: algorithm,
            issuer: account.issuer.isEmpty ? nil : account.issuer,
        )
    }

    private static func account(from totp: ASImportableCredential.TOTP, in item: ASImportableItem) -> Account? {
        guard !totp.secret.isEmpty, (6 ... 8).contains(totp.digits), totp.period > 0 else { return nil }
        let algorithm: HashAlgorithm
        switch totp.algorithm {
        case .sha1: algorithm = .sha1
        case .sha256: algorithm = .sha256
        case .sha512: algorithm = .sha512
        @unknown default: return nil
        }
        return Account(
            issuer: totp.issuer ?? item.title,
            name: totp.userName ?? item.subtitle ?? "",
            secret: totp.secret,
            algorithm: algorithm,
            digits: Int(totp.digits),
            period: Int(totp.period),
            domain: item.scope?.urls.first?.host()?.lowercased(),
            createdAt: item.created ?? Date(),
        )
    }
}
