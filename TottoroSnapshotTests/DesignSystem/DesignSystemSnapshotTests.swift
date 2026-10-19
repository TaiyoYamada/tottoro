//
//  DesignSystemSnapshotTests.swift
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

@Suite(.snapshots(record: .missing))
struct DesignSystemSnapshotTests {
    private let account = Account(issuer: "Mail", name: "you@example.com", secret: Data([1]), color: .blue)

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func `account avatar`(style: UIUserInterfaceStyle) {
        let view = HStack {
            AccountAvatar(account: account)
            AccountAvatar(account: account, size: .small)
        }
        .padding()
        .background(.background)

        assertSnapshot(of: view, as: .component(style), named: style.snapshotName)
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func `countdown ring`(style: UIUserInterfaceStyle) {
        let view = CountdownRing(secondsRemaining: 12, period: 30)
            .frame(width: 32, height: 32)
            .padding()
            .background(.background)

        assertSnapshot(of: view, as: .component(style), named: style.snapshotName)
    }

    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func `one-time code`(style: UIUserInterfaceStyle) {
        let view = OneTimeCodeText(code: "123456", font: Typography.headerCode)
            .padding()
            .background(.background)

        assertSnapshot(of: view, as: .component(style), named: style.snapshotName)
    }
}
