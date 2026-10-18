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
    @State private var store = AccountStore(repository: KeychainAccountRepository())
    @State private var lock = AppLock()

    var body: some Scene {
        // 値を決めて開くと、同じ値のウィンドウが開いていればそれを前に出す。
        // メニューバーから開くたびにウィンドウが増えないよう、値を 1 つに固定している
        WindowGroup(id: SceneID.main, for: String.self) { _ in
            RootView()
                .environment(store)
                .environment(lock)
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
