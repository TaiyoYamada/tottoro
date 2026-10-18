//
//  AccountListViewModelTests.swift
//  TottoroTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import Tottoro
import TottoroCore

struct AccountListViewModelTests {
    private let first = Account(
        issuer: "GitHub",
        name: "octocat",
        secret: Data([1]),
        createdAt: Date(timeIntervalSince1970: 1),
    )
    private let second = Account(
        issuer: "Google",
        name: "me",
        secret: Data([2]),
        createdAt: Date(timeIntervalSince1970: 2),
    )

    @Test func `shows the first account before anything is selected`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        store.add([second, first])
        let viewModel = AccountListViewModel(store: store)

        #expect(viewModel.selectedAccount?.id == first.id)
    }

    @Test func `shows the selected account`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        store.add([first, second])
        let viewModel = AccountListViewModel(store: store)

        viewModel.select(second)

        #expect(viewModel.selectedAccount?.id == second.id)
    }

    @Test func `falls back to the first account when the selected one is deleted`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        store.add([first, second])
        let viewModel = AccountListViewModel(store: store)

        viewModel.select(second)
        viewModel.delete(second)

        #expect(viewModel.selectedAccount?.id == first.id)
    }
}
