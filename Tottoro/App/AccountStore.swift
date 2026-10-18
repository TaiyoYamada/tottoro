//
//  AccountStore.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Observation
import TottoroCore
import TottoroStorage

/// アカウント一覧の唯一の持ち主。Mac ではウィンドウとメニューバーが同じものを共有する。
@Observable
final class AccountStore {
    struct Failure: Identifiable {
        let id = UUID()
        let message: String
    }

    private(set) var accounts: [Account] = []
    var failure: Failure?

    private let repository: any AccountRepository

    init(repository: any AccountRepository) {
        self.repository = repository
    }

    /// キーチェーンには他の端末で変わったことを知らせる仕組みがないので、前面に来るたびに呼ぶ。
    func reload() {
        perform {
            accounts = try repository.loadAll().sorted { $0.createdAt < $1.createdAt }
        }
    }

    /// 同じコードを出すアカウントがすでにあれば、取り込み直しても増やさない。足した件数を返す。
    @discardableResult
    func add(_ newAccounts: [Account]) -> Int {
        var accountsToAdd: [Account] = []
        for account in newAccounts {
            let isAlreadyAdded = (accounts + accountsToAdd).contains { $0.generatesSameCodes(as: account) }
            if !isAlreadyAdded {
                accountsToAdd.append(account)
            }
        }
        perform {
            for account in accountsToAdd {
                try repository.save(account)
            }
            accounts = try repository.loadAll().sorted { $0.createdAt < $1.createdAt }
        }
        return accountsToAdd.count
    }

    func update(_ account: Account) {
        perform {
            try repository.save(account)
            accounts = try repository.loadAll().sorted { $0.createdAt < $1.createdAt }
        }
    }

    func delete(id: Account.ID) {
        perform {
            try repository.delete(id: id)
            accounts = try repository.loadAll().sorted { $0.createdAt < $1.createdAt }
        }
    }

    /// 一覧が変わったときだけ、自動入力の候補を登録し直す。
    /// 他の端末で追加されたアカウントも、前面に来て読み直したときに候補に加わる。
    private func perform(_ body: () throws -> Void) {
        let previous = accounts
        do {
            try body()
        } catch {
            failure = Failure(message: error.localizedDescription)
            return
        }
        guard accounts != previous else { return }
        let accounts = accounts
        Task {
            do {
                try await CredentialIdentityRegistrar.register(accounts)
            } catch {
                failure = Failure(message: error.localizedDescription)
            }
        }
    }
}
