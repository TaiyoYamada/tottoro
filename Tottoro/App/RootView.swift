//
//  RootView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

struct RootView: View {
    @Environment(AccountStore.self) private var store
    @Environment(AppLock.self) private var lock
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch lock.state {
            case .locked, .authenticating:
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
        .failureAlert(store: store)
    }
}
