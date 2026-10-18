//
//  Base32.swift
//  RokketaCore
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation

/// RFC 4648 の Base32。二要素認証の秘密鍵はこの形式で配られる。
public enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let values: [Character: UInt32] = Dictionary(
        uniqueKeysWithValues: alphabet.enumerated().map { ($1, UInt32($0)) }
    )

    /// 大文字小文字、空白、パディングの = は無視する。アルファベット以外の文字があれば nil。
    public static func decode(_ string: String) -> Data? {
        var output = Data()
        var buffer: UInt32 = 0
        var bitCount = 0
        for character in string.uppercased() where character != "=" && !character.isWhitespace {
            guard let value = values[character] else { return nil }
            buffer = (buffer << 5) | value
            bitCount += 5
            if bitCount >= 8 {
                bitCount -= 8
                output.append(UInt8((buffer >> UInt32(bitCount)) & 0xFF))
                buffer &= (1 << UInt32(bitCount)) - 1
            }
        }
        return output
    }
}
