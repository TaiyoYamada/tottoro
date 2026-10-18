//
//  LockView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

struct LockView: View {
    @Environment(AppLock.self) private var lock

    var body: some View {
        ContentUnavailableView {
            Label("ロック中", systemImage: "lock.fill")
        } description: {
            Text("コードを表示するにはロックを解除してください")
        } actions: {
            Button("ロックを解除") {
                Task { await lock.unlock() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(lock.state == .authenticating)
        }
    }
}
