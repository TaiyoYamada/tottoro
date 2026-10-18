//
//  TottoroApp.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI
import TottoroStorage

@main
struct TottoroApp: App {
    @State private var store: AccountStore
    @State private var lock = AppLock()
    @State private var credentialImport: CredentialImportViewModel

    init() {
        #if DEBUG
        if UITesting.isEnabled {
            let store = AccountStore(repository: InMemoryAccountRepository(accounts: UITesting.sampleAccounts))
            _store = State(initialValue: store)
            _credentialImport = State(initialValue: CredentialImportViewModel(store: store))
            let lock = AppLock()
            lock.unlockForUITesting()
            _lock = State(initialValue: lock)
            return
        }
        #endif
        let store = AccountStore(repository: KeychainAccountRepository())
        _store = State(initialValue: store)
        _credentialImport = State(initialValue: CredentialImportViewModel(store: store))
    }

    var body: some Scene {
        // 値を決めて開くと、同じ値のウィンドウが開いていればそれを前に出す。
        // メニューバーから開くたびにウィンドウが増えないよう、値を 1 つに固定している
        WindowGroup(id: SceneID.main, for: String.self) { _ in
            RootView()
                .environment(store)
                .environment(lock)
                .environment(credentialImport)
        } defaultValue: {
            SceneID.main
        }
        #if os(macOS)
        .defaultSize(width: 420, height: 680)
        #endif

        #if os(macOS)
        MenuBarExtra("Tottoro", systemImage: "lock.rotation") {
            MenuBarView(store: store)
                .environment(lock)
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
