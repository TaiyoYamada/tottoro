//
//  AccountListViewModelTests.swift
//  TottoroTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import TottoroCore
import Testing
@testable import Tottoro

struct AccountListViewModelTests {
    private let first = Account(issuer: "GitHub", name: "octocat", secret: Data([1]), createdAt: Date(timeIntervalSince1970: 1))
    private let second = Account(issuer: "Google", name: "me", secret: Data([2]), createdAt: Date(timeIntervalSince1970: 2))

    @Test func showsTheFirstAccountBeforeAnythingIsSelected() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        store.add([second, first])
        let viewModel = AccountListViewModel(store: store)

        #expect(viewModel.selectedAccount?.id == first.id)
    }

    @Test func showsTheSelectedAccount() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        store.add([first, second])
        let viewModel = AccountListViewModel(store: store)

        viewModel.select(second)

        #expect(viewModel.selectedAccount?.id == second.id)
    }

    @Test func fallsBackToTheFirstAccountWhenTheSelectedOneIsDeleted() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        store.add([first, second])
        let viewModel = AccountListViewModel(store: store)

        viewModel.select(second)
        viewModel.delete(second)

        #expect(viewModel.selectedAccount?.id == first.id)
    }
}
