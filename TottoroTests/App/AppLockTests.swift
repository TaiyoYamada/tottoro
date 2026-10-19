//
//  AppLockTests.swift
//  TottoroTests
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation
import Testing
@testable import Tottoro

/// 設定を UserDefaults に書くので、並べて走らせない。
@Suite(.serialized)
struct AppLockTests {
    @Test func `locks right away when the app goes to the background`() {
        UserDefaults.standard.removeObject(forKey: SettingsKey.lockDelay)
        let lock = AppLock()
        lock.unlockForUITesting()

        lock.didEnterBackground()

        #expect(lock.state == .locked)
    }

    @Test func `stays unlocked in the background until the delay passes`() {
        UserDefaults.standard.set(LockDelay.oneMinute.rawValue, forKey: SettingsKey.lockDelay)
        defer { UserDefaults.standard.removeObject(forKey: SettingsKey.lockDelay) }
        let lock = AppLock()
        lock.unlockForUITesting()

        lock.didEnterBackground()

        #expect(lock.state == .unlocked)
    }
}
