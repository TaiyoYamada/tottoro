//
//  GoogleMigrationParserTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import TottoroCore

struct GoogleMigrationParserTests {
    @Test func `parses TOTP accounts and skips unsupported ones`() throws {
        var github = MigrationPayload.OtpParameters()
        github.secret = Data("foobar".utf8)
        github.name = "GitHub:octocat"
        github.issuer = "GitHub"
        github.algorithm = .sha1
        github.digits = .six
        github.type = .totp

        var counterBased = MigrationPayload.OtpParameters()
        counterBased.secret = Data("foobar".utf8)
        counterBased.name = "counter"
        counterBased.type = .hotp

        var payload = MigrationPayload()
        payload.otpParameters = [github, counterBased]
        let uri = try Self.uri(for: payload)

        let result = try GoogleMigrationParser.parse(uri)

        #expect(result.skippedCount == 1)
        let account = try #require(result.accounts.first)
        #expect(result.accounts.count == 1)
        #expect(account.issuer == "GitHub")
        #expect(account.name == "octocat")
        #expect(account.secret == Data("foobar".utf8))
        #expect(account.digits == 6)
    }

    @Test func `ignores the written algorithm and invalid digits`() throws {
        var parameters = MigrationPayload.OtpParameters()
        parameters.secret = Data("foobar".utf8)
        parameters.name = "octocat"
        parameters.issuer = "GitHub"
        parameters.algorithm = .sha512
        parameters.digits = .UNRECOGNIZED(5)
        parameters.type = .totp

        var payload = MigrationPayload()
        payload.otpParameters = [parameters]

        let account = try #require(try GoogleMigrationParser.parse(Self.uri(for: payload)).accounts.first)
        #expect(account.algorithm == .sha1)
        #expect(account.digits == 6)
        #expect(account.period == 30)
    }

    @Test func `imports accounts marked as MD 5 as SHA 1`() throws {
        var parameters = MigrationPayload.OtpParameters()
        parameters.secret = Data("foobar".utf8)
        parameters.name = "octocat"
        parameters.algorithm = .md5
        parameters.type = .totp

        var payload = MigrationPayload()
        payload.otpParameters = [parameters]

        let result = try GoogleMigrationParser.parse(Self.uri(for: payload))
        #expect(result.skippedCount == 0)
        #expect(result.accounts.first?.algorithm == .sha1)
    }

    @Test func `keeps eight digits`() throws {
        var parameters = MigrationPayload.OtpParameters()
        parameters.secret = Data("foobar".utf8)
        parameters.name = "octocat"
        parameters.digits = .eight
        parameters.type = .totp

        var payload = MigrationPayload()
        payload.otpParameters = [parameters]

        let account = try #require(try GoogleMigrationParser.parse(Self.uri(for: payload)).accounts.first)
        #expect(account.digits == 8)
    }

    @Test func `rejects other schemes`() {
        #expect(throws: GoogleMigrationParser.ParseError.invalidURL) {
            try GoogleMigrationParser.parse("otpauth://totp/a?secret=MZXW6YTBOI")
        }
    }

    @Test func `rejects broken payload`() {
        // 有効な Base64 だが protobuf としては壊れている
        #expect(throws: GoogleMigrationParser.ParseError.invalidPayload) {
            try GoogleMigrationParser.parse("otpauth-migration://offline?data=%2F%2F%2F%2F")
        }
    }

    private static func uri(for payload: MigrationPayload) throws -> String {
        let data: Data = try payload.serializedBytes()
        var components = URLComponents()
        components.scheme = "otpauth-migration"
        components.host = "offline"
        components.queryItems = [URLQueryItem(name: "data", value: data.base64EncodedString())]
        // Google の QR コードと同じく、+ や / を %XX にしておく
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "/", with: "%2F")
        return try #require(components.string)
    }
}
