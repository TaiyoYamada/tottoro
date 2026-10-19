//
//  ServiceIconCatalog.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

/// アプリに同梱したサービスのロゴの一覧。scripts/generate-service-icons.py が作る ServiceIcons.json を読む。
/// 通信して探すと、どのサービスを使っているかが外に漏れるので、同梱したものだけから選ぶ。
public struct ServiceIconCatalog: Sendable {
    public struct Entry: Decodable, Hashable, Identifiable, Sendable {
        public let slug: String
        public let title: String
        public let names: [String]
        public let domains: [String]

        public var id: String {
            slug
        }
    }

    private struct File: Decodable {
        let icons: [Entry]
    }

    public let entries: [Entry]
    private let entriesBySlug: [String: Entry]
    private let entriesByName: [String: Entry]

    public init(json: Data) throws {
        entries = try JSONDecoder().decode(File.self, from: json).icons
        entriesBySlug = Dictionary(entries.map { ($0.slug, $0) }, uniquingKeysWith: { first, _ in first })
        entriesByName = Dictionary(
            entries.flatMap { entry in entry.names.map { (Self.normalized($0), entry) } },
            uniquingKeysWith: { first, _ in first },
        )
    }

    public func entry(slug: String) -> Entry? {
        entriesBySlug[slug]
    }

    /// 選んだロゴがあればそれを、なければドメインか発行元の名前から合うロゴを返す。
    public func entry(for account: Account) -> Entry? {
        switch account.icon {
        case let .service(slug):
            return entry(slug: slug)
        case .initial:
            return nil
        case nil:
            // ドメインの方が確かなので先に見る。login.github.com のようなサブドメインも github.com に合わせる
            let domainMatch = account.domain.flatMap { domain in
                entries.first { entry in entry.domains.contains { domain == $0 || domain.hasSuffix("." + $0) } }
            }
            return domainMatch ?? entriesByName[Self.normalized(account.issuer)]
        }
    }

    /// scripts/generate-service-icons.py の normalized と同じ。大文字小文字と記号の違いを無視して比べる
    static func normalized(_ name: String) -> String {
        String(name.lowercased().unicodeScalars.filter { ("a" ... "z").contains($0) || ("0" ... "9").contains($0) })
    }
}
