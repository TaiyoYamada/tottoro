//
//  InMemoryAccountRepository.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

#if DEBUG
import TottoroCore

/// キーチェーンの代わりに、メモリにだけ保存する。単体テストと UI テストで使い、Release のビルドには入らない。
final class InMemoryAccountRepository: AccountRepository {
    private var accounts: [Account.ID: Account]

    init(accounts: [Account] = []) {
        self.accounts = Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, $0) })
    }

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
#endif
