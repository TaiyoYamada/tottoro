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
            if lock.state == .failed(.passcodeNotSet) {
                Label("Set a Passcode", systemImage: "lock.slash")
            } else {
                Label("Locked", systemImage: "lock.fill")
            }
        } description: {
            Text(message)
        } actions: {
            Button("Unlock") {
                Task { await lock.unlock() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(lock.state == .authenticating)
        }
    }

    private var message: LocalizedStringResource {
        switch lock.state {
        case .locked, .authenticating, .unlocked:
            "Unlock to see your codes."
        case .failed(.canceled):
            "Unlocking was canceled. Unlock to see your codes."
        case .failed(.failed):
            "Couldn’t confirm it’s you. Try again."
        case .failed(.passcodeNotSet):
            #if os(macOS)
            """
            Tottoro needs a login password to protect your codes. \
            Set one in System Settings > Users & Groups, then unlock.
            """
            #else
            "Tottoro needs a device passcode to protect your codes. Set one in the Settings app, then unlock."
            #endif
        }
    }
}
