//
//  CredentialExchangeTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/19.
//

import AuthenticationServices
import Foundation
import Testing
@testable import TottoroCore

struct CredentialExchangeTests {
    @Test func `exports accounts that import back the same`() throws {
        let account = Account(
            issuer: "Example",
            name: "you",
            secret: Data("foobar".utf8),
            algorithm: .sha256,
            digits: 8,
            period: 60,
            domain: "login.example.com",
        )

        let data = CredentialExchange.exportedData(from: [account], formatVersion: .v1, exportedAt: Date())
        let imported = CredentialExchange.accounts(from: data)

        let result = try #require(imported.accounts.first)
        #expect(imported.skippedCount == 0)
        #expect(result.generatesSameCodes(as: account))
        #expect(result.issuer == "Example")
        #expect(result.name == "you")
        #expect(result.domain == "login.example.com")
    }

    @Test func `ignores passwords and skips codes with unsupported digits`() {
        let item = ASImportableItem(
            id: Data("1".utf8),
            created: Date(),
            lastModified: Date(),
            title: "Example",
            credentials: [
                .basicAuthentication(ASImportableCredential.BasicAuthentication(userName: nil, password: nil)),
                .totp(ASImportableCredential.TOTP(
                    secret: Data([1]),
                    period: 30,
                    digits: 5,
                    userName: nil,
                    algorithm: .sha1,
                )),
            ],
        )
        let owner = ASImportableAccount(id: Data("owner".utf8), userName: "", email: "", collections: [], items: [item])
        let data = ASExportedCredentialData(
            accounts: [owner],
            formatVersion: .v1,
            exporterRelyingPartyIdentifier: "example.com",
            exporterDisplayName: "Example",
            timestamp: Date(),
        )

        let imported = CredentialExchange.accounts(from: data)

        #expect(imported.accounts.isEmpty)
        #expect(imported.skippedCount == 1)
    }
}
