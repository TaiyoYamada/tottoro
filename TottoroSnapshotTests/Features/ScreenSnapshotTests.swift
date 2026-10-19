//
//  ScreenSnapshotTests.swift
//  TottoroSnapshotTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import SnapshotTesting
import SwiftUI
import Testing
@testable import Tottoro
import TottoroCore
import UIKit

/// 英語と日本語で、文字のはみ出しや崩れがないかを見る。コードは時刻で変わるので、コードの出る画面は撮らない。
@Suite(.snapshots(record: .missing))
struct ScreenSnapshotTests {
    private nonisolated static let languages = ["en", "ja"]
    private nonisolated static let styles = [UIUserInterfaceStyle.light, .dark]

    @Test(arguments: languages, styles)
    func `lock screen`(language: String, style: UIUserInterfaceStyle) {
        let view = LockView()
            .environment(AppLock())
            .environment(\.locale, Locale(identifier: language))

        assertSnapshot(of: view, as: .screen(style), named: "\(language)-\(style.snapshotName)")
    }

    @Test(arguments: languages, styles)
    func `empty account list`(language: String, style: UIUserInterfaceStyle) {
        let view = AccountListView(store: AccountStore(repository: InMemoryAccountRepository()))
            .environment(\.locale, Locale(identifier: language))

        assertSnapshot(of: view, as: .screen(style), named: "\(language)-\(style.snapshotName)")
    }

    @Test(arguments: languages, styles)
    func `add account`(language: String, style: UIUserInterfaceStyle) {
        let view = AddAccountView(store: AccountStore(repository: InMemoryAccountRepository()))
            .environment(\.locale, Locale(identifier: language))
            // テストの中では画面が前面にないので、App スイッチャー用の覆いが出ないようにする
            .environment(\.scenePhase, .active)

        assertSnapshot(of: view, as: .screen(style), named: "\(language)-\(style.snapshotName)")
    }

    @Test(arguments: languages, styles)
    func `manual entry`(language: String, style: UIUserInterfaceStyle) {
        let viewModel = AddAccountViewModel(store: AccountStore(repository: InMemoryAccountRepository()))
        let view = ManualEntryForm(viewModel: viewModel)
            .environment(\.locale, Locale(identifier: language))

        assertSnapshot(of: view, as: .screen(style), named: "\(language)-\(style.snapshotName)")
    }

    @Test(arguments: languages, styles)
    func `edit account`(language: String, style: UIUserInterfaceStyle) {
        let account = Account(
            issuer: "Mail",
            name: "you@example.com",
            secret: Data([1]),
            domain: "mail.example.com",
            color: .blue,
        )
        let view = EditAccountView(account: account, store: AccountStore(repository: InMemoryAccountRepository()))
            .environment(\.locale, Locale(identifier: language))
            .environment(\.scenePhase, .active)

        assertSnapshot(of: view, as: .screen(style), named: "\(language)-\(style.snapshotName)")
    }
}
