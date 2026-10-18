//
//  AccountTests.swift
//  RokketaCoreTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import RokketaCore

struct AccountTests {
    @Test(arguments: [
        ("github.com", true),
        ("GitHub.com", true),
        ("gist.github.com", true),
        ("notgithub.com", false),
        ("github.com.evil.example", false),
    ])
    func matchesTheDomainAndItsSubdomains(host: String, expected: Bool) {
        let account = Account(issuer: "GitHub", name: "octocat", secret: Data([1]), domain: "github.com")
        #expect(account.matchesService(host: host) == expected)
    }

    @Test func matchesNothingWithoutADomain() {
        let account = Account(issuer: "GitHub", name: "octocat", secret: Data([1]))
        #expect(!account.matchesService(host: "github.com"))
    }

    @Test func fallsBackToTheNameWhenTheIssuerIsEmpty() {
        let account = Account(issuer: "", name: "octocat", secret: Data([1]))
        #expect(account.displayName == "octocat")
    }
}
