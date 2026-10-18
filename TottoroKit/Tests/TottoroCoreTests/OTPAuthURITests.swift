//
//  OTPAuthURITests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import TottoroCore

struct OTPAuthURITests {
    @Test func parsesAllParameters() throws {
        let account = try OTPAuthURI.account(
            from: "otpauth://totp/ACME%20Co:john@example.com?secret=MZXW6YTBOI&issuer=ACME%20Co&algorithm=SHA256&digits=8&period=60"
        )
        #expect(account.issuer == "ACME Co")
        #expect(account.name == "john@example.com")
        #expect(account.secret == Data("foobar".utf8))
        #expect(account.algorithm == .sha256)
        #expect(account.digits == 8)
        #expect(account.period == 60)
    }

    @Test func usesDefaultsWhenParametersAreMissing() throws {
        let account = try OTPAuthURI.account(from: "otpauth://totp/john@example.com?secret=MZXW6YTBOI")
        #expect(account.issuer == "")
        #expect(account.name == "john@example.com")
        #expect(account.algorithm == .sha1)
        #expect(account.digits == 6)
        #expect(account.period == 30)
    }

    @Test func takesIssuerFromTheLabelWhenTheParameterIsMissing() throws {
        let account = try OTPAuthURI.account(from: "otpauth://totp/GitHub:%20octocat?secret=MZXW6YTBOI")
        #expect(account.issuer == "GitHub")
        #expect(account.name == "octocat")
    }

    @Test func keepsTheNameEmptyWhenTheLabelHasOnlyTheIssuer() throws {
        let account = try OTPAuthURI.account(from: "otpauth://totp/GitHub:?secret=MZXW6YTBOI&issuer=GitHub")
        #expect(account.issuer == "GitHub")
        #expect(account.name == "")
    }

    @Test(arguments: [
        ("https://example.com", OTPAuthURI.ParseError.invalidURL),
        ("otpauth://hotp/a?secret=MZXW6YTBOI&counter=1", .unsupportedType),
        ("otpauth://totp/a", .missingSecret),
        ("otpauth://totp/a?secret=1111", .invalidSecret),
        ("otpauth://totp/a?secret=MZXW6YTBOI&algorithm=MD5", .unsupportedAlgorithm),
        ("otpauth://totp/a?secret=MZXW6YTBOI&digits=4", .invalidDigits),
        ("otpauth://totp/a?secret=MZXW6YTBOI&period=0", .invalidPeriod),
    ])
    func rejectsInvalidURIs(uri: String, expected: OTPAuthURI.ParseError) {
        #expect(throws: expected) {
            try OTPAuthURI.account(from: uri)
        }
    }
}
