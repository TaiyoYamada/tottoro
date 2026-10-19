//
//  Data+Hex.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

extension Data {
    /// "0a1b" のような 16 進の文字列から作る。長さが奇数か、16 進でない文字があれば nil。
    init?(hex: String) {
        let digits = Array(hex.utf8)
        guard digits.count.isMultiple(of: 2) else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(digits.count / 2)
        for index in stride(from: 0, to: digits.count, by: 2) {
            guard let high = Self.nibble(digits[index]), let low = Self.nibble(digits[index + 1]) else { return nil }
            bytes.append(high << 4 | low)
        }
        self.init(bytes)
    }

    private static func nibble(_ character: UInt8) -> UInt8? {
        switch character {
        case UInt8(ascii: "0") ... UInt8(ascii: "9"): character - UInt8(ascii: "0")
        case UInt8(ascii: "a") ... UInt8(ascii: "f"): character - UInt8(ascii: "a") + 10
        case UInt8(ascii: "A") ... UInt8(ascii: "F"): character - UInt8(ascii: "A") + 10
        default: nil
        }
    }
}
