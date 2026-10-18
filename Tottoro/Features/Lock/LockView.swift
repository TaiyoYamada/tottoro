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
            Label("Locked", systemImage: "lock.fill")
        } description: {
            Text("Unlock to see your codes.")
        } actions: {
            Button("Unlock") {
                Task { await lock.unlock() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(lock.state == .authenticating)
        }
    }
}
