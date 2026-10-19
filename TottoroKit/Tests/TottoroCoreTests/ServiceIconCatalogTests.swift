//
//  ServiceIconCatalogTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation
import Testing
@testable import TottoroCore

struct ServiceIconCatalogTests {
    private let catalog = try! ServiceIconCatalog(json: Data("""
    {"icons": [
      {"slug": "github", "title": "GitHub", "names": ["GitHub"], "domains": ["github.com"]},
      {"slug": "x", "title": "X", "names": ["X", "Twitter"], "domains": ["x.com"]}
    ]}
    """.utf8))

    @Test(arguments: [
        ("GitHub", nil, "github"),
        ("git-hub", nil, "github"),
        ("Twitter", nil, "x"),
        ("Work", "login.github.com", "github"),
        ("Unknown", nil, nil),
    ] as [(String, String?, String?)])
    func `picks an icon from the domain or the issuer`(issuer: String, domain: String?, slug: String?) {
        let account = Account(issuer: issuer, name: "", secret: Data([1]), domain: domain)
        #expect(catalog.entry(for: account)?.slug == slug)
    }

    @Test func `uses the icon the person chose over the automatic one`() {
        let chosen = Account(issuer: "GitHub", name: "", secret: Data([1]), icon: .service("x"))
        let initial = Account(issuer: "GitHub", name: "", secret: Data([1]), icon: .initial)

        #expect(catalog.entry(for: chosen)?.slug == "x")
        #expect(catalog.entry(for: initial) == nil)
    }
}
