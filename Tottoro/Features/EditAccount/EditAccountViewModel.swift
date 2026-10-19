//
//  EditAccountViewModel.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Observation
import TottoroCore

@Observable
final class EditAccountViewModel {
    var issuer: String
    var name: String
    var domain: String
    var color: AccountColor
    var icon: AccountIcon?

    private let original: Account
    private let store: AccountStore

    init(account: Account, store: AccountStore) {
        original = account
        issuer = account.issuer
        name = account.name
        domain = account.domain ?? ""
        color = account.color
        icon = account.icon
        self.store = store
    }

    /// 編集中の内容で作ったアカウント。丸の見た目を、保存する前に見せるのに使う。
    var preview: Account {
        var account = original
        account.issuer = issuer
        account.domain = Self.normalizedDomain(domain)
        account.color = color
        account.icon = icon
        return account
    }

    func save() {
        var account = original
        account.issuer = issuer.trimmingCharacters(in: .whitespaces)
        account.name = name.trimmingCharacters(in: .whitespaces)
        account.domain = Self.normalizedDomain(domain)
        account.color = color
        account.icon = icon
        store.update(account)
    }

    /// 「https://github.com/login」のように URL ごと貼られても、ホスト名だけを残す。
    static func normalizedDomain(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !trimmed.isEmpty else { return nil }
        let host = URL(string: trimmed.contains("://") ? trimmed : "https://" + trimmed)?.host()
        return host ?? trimmed
    }
}
