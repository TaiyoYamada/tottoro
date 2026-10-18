//
//  EditAccountViewModelTests.swift
//  TottoroTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Testing
@testable import Tottoro

struct EditAccountViewModelTests {
    @Test(arguments: [
        ("github.com", "github.com"),
        ("  GitHub.com ", "github.com"),
        ("https://github.com/login", "github.com"),
        ("", nil),
    ] as [(String, String?)])
    func keepsOnlyTheHostOfTheDomain(input: String, expected: String?) {
        #expect(EditAccountViewModel.normalizedDomain(input) == expected)
    }
}
