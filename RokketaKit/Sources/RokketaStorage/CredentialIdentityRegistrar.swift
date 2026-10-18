//
//  CredentialIdentityRegistrar.swift
//  RokketaStorage
//
//  Created by 山田大陽 on 2026/10/18.
//

import AuthenticationServices
import RokketaCore

/// 自動入力の候補を OS に登録する。OS はここに登録したドメインで、どのサイトに候補を出すかを決める。
public enum CredentialIdentityRegistrar {
    /// 登録済みの候補を、渡したアカウントの分だけに置き換える。ドメインのないアカウントは登録しない。
    public static func register(_ accounts: [Account]) async throws {
        let store = ASCredentialIdentityStore.shared
        // 設定で Rokketa の自動入力がオフなら、OS は登録を受け付けない
        guard await store.state().isEnabled else { return }

        let identities = accounts.compactMap { account -> ASOneTimeCodeCredentialIdentity? in
            guard let domain = account.domain else { return nil }
            return ASOneTimeCodeCredentialIdentity(
                serviceIdentifier: ASCredentialServiceIdentifier(identifier: domain, type: .domain),
                label: account.name.isEmpty || account.name == account.displayName
                    ? account.displayName
                    : "\(account.displayName)（\(account.name)）",
                recordIdentifier: account.id.uuidString
            )
        }
        _ = try await store.replaceCredentialIdentities(identities)
    }
}
