//
//  TOTPGeneratorTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import TottoroCore

struct TOTPGeneratorTests {
    /// RFC 6238 の付録 B にある検証用の値。秘密鍵はアルゴリズムごとに長さが違う
    private static let secrets: [HashAlgorithm: Data] = [
        .sha1: Data("12345678901234567890".utf8),
        .sha256: Data("12345678901234567890123456789012".utf8),
        .sha512: Data("1234567890123456789012345678901234567890123456789012345678901234".utf8),
    ]

    @Test(arguments: [
        (59, HashAlgorithm.sha1, "94287082"),
        (59, .sha256, "46119246"),
        (59, .sha512, "90693936"),
        (1_111_111_109, .sha1, "07081804"),
        (1_111_111_109, .sha256, "68084774"),
        (1_111_111_109, .sha512, "25091201"),
        (1_111_111_111, .sha1, "14050471"),
        (1_111_111_111, .sha256, "67062674"),
        (1_111_111_111, .sha512, "99943326"),
        (1_234_567_890, .sha1, "89005924"),
        (1_234_567_890, .sha256, "91819424"),
        (1_234_567_890, .sha512, "93441116"),
        (2_000_000_000, .sha1, "69279037"),
        (2_000_000_000, .sha256, "90698825"),
        (2_000_000_000, .sha512, "38618901"),
        (20_000_000_000, .sha1, "65353130"),
        (20_000_000_000, .sha256, "77737706"),
        (20_000_000_000, .sha512, "47863826"),
    ])
    func `matches RFC vectors`(time: Int, algorithm: HashAlgorithm, expected: String) throws {
        let secret = try #require(Self.secrets[algorithm])
        let account = Account(issuer: "RFC", name: "test", secret: secret, algorithm: algorithm, digits: 8)
        let date = Date(timeIntervalSince1970: TimeInterval(time))
        #expect(TOTPGenerator.code(for: account, at: date) == expected)
    }

    @Test func `keeps leading zeros for six digits`() throws {
        // 1111111109 秒の SHA1 は 8 桁で 07081804。6 桁ではその下 6 桁になる
        let secret = try #require(Self.secrets[.sha1])
        let account = Account(issuer: "RFC", name: "test", secret: secret)
        #expect(TOTPGenerator.code(for: account, at: Date(timeIntervalSince1970: 1_111_111_109)) == "081804")
    }

    @Test func `counts down within the period`() {
        #expect(TOTPGenerator.secondsRemaining(period: 30, at: Date(timeIntervalSince1970: 60)) == 30)
        #expect(TOTPGenerator.secondsRemaining(period: 30, at: Date(timeIntervalSince1970: 89)) == 1)
    }
}
