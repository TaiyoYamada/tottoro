//
//  AppLock.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import LocalAuthentication
import Observation
#if os(macOS)
import AppKit
#endif

/// Face ID / Touch ID のロック。秘密鍵の暗号化は iCloud キーチェーンが受け持ち、
/// これはロック解除された端末を他人が触ったときにコードを見せないための関門になる。
@Observable
final class AppLock {
    enum State {
        case locked
        case authenticating
        case unlocked
    }

    private(set) var state: State = .locked

    init() {
        #if os(macOS)
        // Mac はアプリが裏に回っても使い続けるので、画面のスリープとユーザーの切り替えでロックする。
        // AppLock はアプリと同じだけ生きるので、監視を外す処理は持たない
        let center = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.screensDidSleepNotification, NSWorkspace.sessionDidResignActiveNotification] {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { self.lock() }
            }
        }
        #endif
    }

    func unlock() async {
        guard state == .locked else { return }
        state = .authenticating
        do {
            // 生体認証に失敗したときに端末のパスコードで解除できるよう、deviceOwnerAuthentication を使う
            try await LAContext().evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: String(localized: "コードを表示するためにロックを解除します"),
            )
            state = .unlocked
        } catch {
            state = .locked
        }
    }

    func lock() {
        state = .locked
    }
}
