//
//  TOTPGenerator.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/18.
//

import CryptoKit
import Foundation

/// RFC 6238（TOTP）と、その土台の RFC 4226（HOTP）の計算。
public enum TOTPGenerator {
    public static func code(for account: Account, at date: Date) -> String {
        let counter = UInt64(date.timeIntervalSince1970) / UInt64(account.period)
        return hotp(secret: account.secret, counter: counter, algorithm: account.algorithm, digits: account.digits)
    }

    /// 今のコードが切り替わるまでの秒数。0 より大きく period 以下。
    public static func secondsRemaining(period: Int, at date: Date) -> TimeInterval {
        let period = TimeInterval(period)
        return period - date.timeIntervalSince1970.truncatingRemainder(dividingBy: period)
    }

    static func hotp(secret: Data, counter: UInt64, algorithm: HashAlgorithm, digits: Int) -> String {
        let message = withUnsafeBytes(of: counter.bigEndian) { Data($0) }
        let key = SymmetricKey(data: secret)
        let mac: [UInt8] = switch algorithm {
        case .sha1: Array(HMAC<Insecure.SHA1>.authenticationCode(for: message, using: key))
        case .sha256: Array(HMAC<SHA256>.authenticationCode(for: message, using: key))
        case .sha512: Array(HMAC<SHA512>.authenticationCode(for: message, using: key))
        }

        // 動的切り詰め: 最後のバイトの下位 4 ビットが、31 ビットを取り出す位置になる
        let offset = Int(mac[mac.count - 1] & 0x0F)
        let truncated = UInt32(mac[offset] & 0x7F) << 24
            | UInt32(mac[offset + 1]) << 16
            | UInt32(mac[offset + 2]) << 8
            | UInt32(mac[offset + 3])

        var modulus: UInt32 = 1
        for _ in 0 ..< digits {
            modulus *= 10
        }
        let value = String(truncated % modulus)
        return String(repeating: "0", count: digits - value.count) + value
    }
}
