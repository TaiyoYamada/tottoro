//
//  OneTimeCodePickerViewModel.swift
//  TottoroAutoFill
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import LocalAuthentication
import Observation
import TottoroCore
import TottoroStorage

@Observable
final class OneTimeCodePickerViewModel {
    enum Mode {
        /// 一覧から選んでもらう。渡すのはいま開いているサイトの識別子（ドメインや URL）。
        case pick([String])
        /// OS の候補で選ばれたアカウントのコードを、ロック解除のあとすぐに返す。
        case provide(Account.ID)
    }

    enum State {
        case locked
        case authenticating
        case unlocked([Account])
    }

    enum Result {
        case code(String)
        case canceled
        case notFound
        case failed(Error)
    }

    private(set) var state: State = .locked

    private let mode: Mode
    private let finish: (Result) -> Void
    private let repository = KeychainAccountRepository()

    init(mode: Mode, finish: @escaping (Result) -> Void) {
        self.mode = mode
        self.finish = finish
    }

    func unlock() async {
        guard case .locked = state else { return }
        state = .authenticating
        do {
            try await LAContext().evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "コードを入力するためにロックを解除します"),
            )
        } catch {
            state = .locked
            return
        }

        let accounts: [Account]
        do {
            accounts = try repository.loadAll()
        } catch {
            finish(.failed(error))
            return
        }

        switch mode {
        case let .pick(serviceIdentifiers):
            state = .unlocked(Self.sorted(accounts, for: serviceIdentifiers))
        case let .provide(id):
            guard let account = accounts.first(where: { $0.id == id }) else {
                finish(.notFound)
                return
            }
            finish(.code(TOTPGenerator.code(for: account, at: Date())))
        }
    }

    func select(_ account: Account) {
        finish(.code(TOTPGenerator.code(for: account, at: Date())))
    }

    func cancel() {
        finish(.canceled)
    }

    func code(for account: Account, at date: Date) -> String {
        TOTPGenerator.code(for: account, at: date)
    }

    /// いま開いているサイトに合うアカウントを先頭にし、残りは名前の順に並べる。
    static func sorted(_ accounts: [Account], for serviceIdentifiers: [String]) -> [Account] {
        let hosts = serviceIdentifiers.map { URL(string: $0)?.host() ?? $0 }
        func matches(_ account: Account) -> Bool {
            hosts.contains { account.matchesService(host: $0) }
        }
        return accounts.sorted { lhs, rhs in
            if matches(lhs) != matches(rhs) {
                return matches(lhs)
            }
            return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        }
    }
}
