//
//  AccountTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import TottoroCore

struct AccountTests {
    @Test(arguments: [
        ("github.com", true),
        ("GitHub.com", true),
        ("gist.github.com", true),
        ("notgithub.com", false),
        ("github.com.evil.example", false),
    ])
    func `matches the domain and its subdomains`(host: String, expected: Bool) {
        let account = Account(issuer: "GitHub", name: "octocat", secret: Data([1]), domain: "github.com")
        #expect(account.matchesService(host: host) == expected)
    }

    @Test func `matches nothing without A domain`() {
        let account = Account(issuer: "GitHub", name: "octocat", secret: Data([1]))
        #expect(!account.matchesService(host: "github.com"))
    }

    @Test func `falls back to the name when the issuer is empty`() {
        let account = Account(issuer: "", name: "octocat", secret: Data([1]))
        #expect(account.displayName == "octocat")
    }

    @Test func `treats accounts with the same secret and settings as the same, whatever their names`() {
        let account = Account(issuer: "GitHub", name: "octocat", secret: Data([1]))
        let renamed = Account(issuer: "GitHub (work)", name: "me", secret: Data([1]))
        let otherDigits = Account(issuer: "GitHub", name: "octocat", secret: Data([1]), digits: 8)

        #expect(account.generatesSameCodes(as: renamed))
        #expect(!account.generatesSameCodes(as: otherDigits))
    }
}
