//
//  AccountRepository.swift
//  RokketaCore
//
//  Created by 山田大陽 on 2026/10/18.
//

public protocol AccountRepository {
    func loadAll() throws -> [Account]
    /// 同じ id のアカウントがあれば上書きする。
    func save(_ account: Account) throws
    func delete(id: Account.ID) throws
}
