//
//  AppLock.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
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

    /// 裏に回った時刻。端末のスリープ中も進み、時計の設定を変えても戻らない時計で測る。
    private var backgroundedAt: ContinuousClock.Instant?

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

    /// ロックが外れたままでも、裏に回ってから「ロックまでの時間」が過ぎていれば、先にロックしてから解除を求める。
    /// Mac はメインのウインドウを閉じたあとも、メニューバーや設定のウインドウからここを通る。
    func unlock() async {
        if state == .unlocked, let backgroundedAt, backgroundedAt.duration(to: .now) >= lockDelay.duration {
            lock()
        }
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
        backgroundedAt = nil
        state = .locked
    }

    /// 設定の「ロックまでの時間」が過ぎるまでは、ロックしない。
    func didEnterBackground() {
        guard state == .unlocked else { return }
        if lockDelay == .immediately {
            lock()
        } else {
            backgroundedAt = .now
        }
    }

    func willEnterForeground() async {
        await unlock()
        backgroundedAt = nil
    }

    private var lockDelay: LockDelay {
        LockDelay(rawValue: UserDefaults.standard.integer(forKey: SettingsKey.lockDelay)) ?? .immediately
    }

    #if DEBUG
    func unlockForUITesting() {
        state = .unlocked
    }
    #endif
}
