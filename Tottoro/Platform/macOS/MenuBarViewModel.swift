//
//  MenuBarViewModel.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

#if os(macOS)
import Foundation
import Observation
import TottoroCore

@Observable
final class MenuBarViewModel {
    var searchText = ""
    private(set) var copiedAccountID: Account.ID?

    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
    }

    var accounts: [Account] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return store.accounts }
        return store.accounts.filter {
            $0.issuer.localizedStandardContains(query) || $0.name.localizedStandardContains(query)
        }
    }

    func reload() {
        store.reload()
    }

    func code(for account: Account, at date: Date) -> String {
        TOTPGenerator.code(for: account, at: date)
    }

    func secondsRemaining(for account: Account, at date: Date) -> TimeInterval {
        TOTPGenerator.secondsRemaining(period: account.period, at: date)
    }

    func copyCode(of account: Account) async {
        Clipboard.copyOneTimeCode(TOTPGenerator.code(for: account, at: Date()))
        copiedAccountID = account.id
        try? await Task.sleep(for: .seconds(1.5))
        if copiedAccountID == account.id {
            copiedAccountID = nil
        }
    }
}
#endif
