//
//  ImportedAccounts.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

/// 他のアプリから取り込んだアカウント。どの形式から読んでも、この形で返す。
public struct ImportedAccounts: Equatable, Sendable {
    public let accounts: [Account]
    /// HOTP など、Tottoro が扱えずに飛ばした件数。
    public let skippedCount: Int

    public init(accounts: [Account], skippedCount: Int) {
        self.accounts = accounts
        self.skippedCount = skippedCount
    }
}
