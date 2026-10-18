//
//  RootView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import AuthenticationServices
import SwiftUI

struct RootView: View {
    @Environment(AccountStore.self) private var store
    @Environment(AppLock.self) private var lock
    @Environment(CredentialImportViewModel.self) private var credentialImport
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch lock.state {
            case .locked, .authenticating, .failed:
                LockView()
            case .unlocked:
                AccountListView(store: store)
            }
        }
        .onChange(of: scenePhase, initial: true) { oldPhase, phase in
            switch phase {
            case .active:
                store.reload()
                // Face ID を閉じたときも inactive から active に戻る。そこで自動で求め直すと、
                // キャンセルしても認証が出続けるので、起動時と裏から戻ったときだけにする
                if oldPhase == phase || oldPhase == .background {
                    Task { await lock.unlock() }
                }
            case .background:
                lock.lock()
            case .inactive:
                // Face ID の確認中にも inactive になるので、ここではロックしない
                break
            @unknown default:
                break
            }
        }
        // 他のアプリが Credential Exchange で書き出したとき、OS がこの活動でアプリを開く
        .onContinueUserActivity(ASCredentialExchangeActivity) { activity in
            credentialImport.receive(activity)
            if lock.state == .unlocked {
                Task { await credentialImport.importCredentials() }
            }
        }
        // ロック中に受け取ったときは、ロックが外れてから取り込む。
        // 取り込みの状態を id に入れると、取り込みを始めた途端に id が変わって作業が取り消される
        .task(id: lock.state == .unlocked) {
            guard lock.state == .unlocked else { return }
            await credentialImport.importCredentials()
        }
        .credentialImportAlerts(credentialImport)
        .privacyCover()
        .failureAlert(store: store)
    }
}
