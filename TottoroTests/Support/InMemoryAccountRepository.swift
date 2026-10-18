//
//  InMemoryAccountRepository.swift
//  TottoroTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import TottoroCore

/// キーチェーンの代わりに、メモリにだけ保存する。
final class InMemoryAccountRepository: AccountRepository {
    private var accounts: [Account.ID: Account] = [:]

    func loadAll() throws -> [Account] {
        Array(accounts.values)
    }

    func save(_ account: Account) throws {
        accounts[account.id] = account
    }

    func delete(id: Account.ID) throws {
        accounts[id] = nil
    }
}
