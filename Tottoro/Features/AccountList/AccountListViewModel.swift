//
//  AccountListViewModel.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Observation
import TottoroCore

@Observable
final class AccountListViewModel {
    enum Sheet: Identifiable {
        case add
        case edit(Account)
        case settings

        var id: String {
            switch self {
            case .add: "add"
            case let .edit(account): account.id.uuidString
            case .settings: "settings"
            }
        }
    }

    var sheet: Sheet?
    /// コピーした直後だけ「コピーしました」を出すために持つ。
    private(set) var copiedAccountID: Account.ID?
    /// コードを隠す設定のときに、タップして見せているアカウント。別のアカウントを選ぶと隠し直す。
    private(set) var revealedAccountID: Account.ID?
    private var selectedID: Account.ID?

    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
    }

    var accounts: [Account] {
        store.accounts
    }

    /// 選んだアカウントが消えたときや、まだ選んでいないときは先頭を出す。
    var selectedAccount: Account? {
        accounts.first { $0.id == selectedID } ?? accounts.first
    }

    func select(_ account: Account) {
        selectedID = account.id
        revealedAccountID = nil
    }

    /// 隠しているコードは、1 回目のタップで見せ、2 回目でコピーする。
    func tapCode(of account: Account, hidesCodes: Bool) async {
        if hidesCodes, revealedAccountID != account.id {
            revealedAccountID = account.id
            return
        }
        await copyCode(of: account)
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

    func delete(_ account: Account) {
        store.delete(id: account.id)
    }
}
