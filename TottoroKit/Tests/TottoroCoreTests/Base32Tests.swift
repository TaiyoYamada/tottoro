//
//  Base32Tests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import TottoroCore

struct Base32Tests {
    // RFC 4648 の 10 章にある検証用の値
    @Test(arguments: [
        ("", ""),
        ("MY======", "f"),
        ("MZXQ====", "fo"),
        ("MZXW6===", "foo"),
        ("MZXW6YQ=", "foob"),
        ("MZXW6YTB", "fooba"),
        ("MZXW6YTBOI======", "foobar"),
    ])
    func decodesRFCVectors(encoded: String, expected: String) {
        #expect(Base32.decode(encoded) == Data(expected.utf8))
    }

    @Test func ignoresCaseSpacesAndMissingPadding() {
        #expect(Base32.decode("mzxw 6ytb oi") == Data("foobar".utf8))
    }

    @Test func rejectsCharactersOutsideTheAlphabet() {
        #expect(Base32.decode("MZXW1") == nil)
    }
}
