//
//  MalformedInputTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import TottoroCore

/// QR コードの中身は信頼できない入力なので、壊れた入力を大量に流しても落ちないことを確かめる。
/// 乱数の種を固定しているので、毎回同じ入力になる。
struct MalformedInputTests {
    private static let iterations = 2000

    @Test func `otpauth URIs never crash the parser`() {
        var random = SeededRandom(seed: 1)
        for _ in 0 ..< Self.iterations {
            let uri = "otpauth://totp/" + random.string(length: Int.random(in: 0 ... 80, using: &random))
            _ = try? OTPAuthURI.account(from: uri)
        }
    }

    @Test func `migration payloads never crash the parser`() {
        var random = SeededRandom(seed: 2)
        for _ in 0 ..< Self.iterations {
            var bytes = [UInt8](repeating: 0, count: Int.random(in: 0 ... 200, using: &random))
            for index in bytes.indices {
                bytes[index] = UInt8.random(in: .min ... .max, using: &random)
            }
            let data = Data(bytes).base64EncodedString()
            let query = data.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
            let uri = "otpauth-migration://offline?data=" + query
            _ = try? GoogleMigrationParser.parse(uri)
        }
    }

    @Test func `setup keys never crash the decoder`() {
        var random = SeededRandom(seed: 3)
        for _ in 0 ..< Self.iterations {
            _ = Base32.decode(random.string(length: Int.random(in: 0 ... 64, using: &random)))
        }
    }
}

/// SplitMix64。テストの入力を毎回同じにするための、種を決められる乱数。
private struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }

    /// otpauth の URL に出てくる記号や、日本語、絵文字を混ぜた文字列。
    mutating func string(length: Int) -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
            + Array(":/?&=%#@+-_.~ 発行元🔑\u{0}\n")
        return String((0 ..< length).map { _ in characters[Int.random(in: 0 ..< characters.count, using: &self)] })
    }
}
