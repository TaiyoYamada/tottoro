//
//  AppLock.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import Observation
import TottoroStorage
#if os(macOS)
import AppKit
#endif

/// Face ID / Touch ID のロック。秘密鍵の暗号化は iCloud キーチェーンが受け持ち、
/// これはロック解除された端末を他人が触ったときにコードを見せないための関門になる。
@Observable
final class AppLock {
    enum State: Equatable {
        case locked
        case authenticating
        case unlocked
        /// 直前の解除がうまくいかなかった。理由を画面に出し、もう一度試せるようにする。
        case failed(DeviceOwnerAuthentication.Failure)
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
        switch state {
        case .locked, .failed:
            break
        case .authenticating, .unlocked:
            return
        }
        state = .authenticating
        do throws(DeviceOwnerAuthentication.Failure) {
            try await DeviceOwnerAuthentication.authenticate(reason: String(localized: "Unlock to show your codes"))
            state = .unlocked
        } catch {
            state = .failed(error)
        }
    }

    func lock() {
        state = .locked
    }

    #if DEBUG
    func unlockForUITesting() {
        state = .unlocked
    }
    #endif
}
