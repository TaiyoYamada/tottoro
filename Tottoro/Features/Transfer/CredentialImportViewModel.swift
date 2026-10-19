//
//  CredentialImportViewModel.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import AuthenticationServices
import Foundation
import Observation
import TottoroCore

/// 他のアプリが Credential Exchange で書き出したアカウントを受け取る。
/// OS がアプリを開いて引き換えの番号を渡してくるので、ロックが外れてから取り込む。
@Observable
final class CredentialImportViewModel {
    enum Phase: Equatable {
        case idle
        case waitingForUnlock(UUID)
        case importing
        case finished(AddResult)
        case failed(String)
    }

    var phase: Phase = .idle

    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
    }

    func receive(_ activity: NSUserActivity) {
        guard let token = activity.userInfo?[ASCredentialImportToken] as? UUID else { return }
        phase = .waitingForUnlock(token)
    }

    func importCredentials() async {
        guard case let .waitingForUnlock(token) = phase else { return }
        phase = .importing
        do {
            let data = try await ASCredentialImportManager().importCredentials(token: token)
            let imported = CredentialExchange.accounts(from: data)
            let added = store.add(imported.accounts)
            phase = .finished(AddResult(
                added: added,
                alreadyAdded: imported.accounts.count - added,
                unsupported: imported.skippedCount,
            ))
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
