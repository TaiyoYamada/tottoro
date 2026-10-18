//
//  EditAccountViewModel.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Observation
import RokketaCore

@Observable
final class EditAccountViewModel {
    var issuer: String
    var name: String
    var domain: String
    var color: AccountColor

    private let original: Account
    private let store: AccountStore

    init(account: Account, store: AccountStore) {
        original = account
        issuer = account.issuer
        name = account.name
        domain = account.domain ?? ""
        color = account.color
        self.store = store
    }

    func save() {
        var account = original
        account.issuer = issuer.trimmingCharacters(in: .whitespaces)
        account.name = name.trimmingCharacters(in: .whitespaces)
        account.domain = Self.normalizedDomain(domain)
        account.color = color
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
