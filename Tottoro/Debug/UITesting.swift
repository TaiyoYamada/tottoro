//
//  UITesting.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

#if DEBUG
import Foundation
import TottoroCore

/// UI テストとスクリーンショットのための起動の仕方。本物のキーチェーンに触らず、ロックも外した状態で始める。
/// Release のビルドには入らないので、配ったアプリをこの起動引数で開けることはない。
enum UITesting {
    /// TottoroUITests の XCUIApplication+UITesting.swift と歩調を合わせる。
    static let launchArgument = "-UITesting"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    /// スクリーンショットに出す架空のアカウント。秘密鍵も意味のない固定の値にしている。
    static let sampleAccounts: [Account] = [
        ("Mail", "you@example.com", AccountColor.blue),
        ("Cloud", "you@example.com", .indigo),
        ("Shop", "you", .orange),
        ("Bank", "1234-5678", .green),
        ("Chat", "you", .pink),
        ("Work", "you@example.org", .teal),
    ].enumerated().map { index, sample in
        Account(
            issuer: sample.0,
            name: sample.1,
            secret: Data("tottoro-sample-\(index)".utf8),
            color: sample.2,
            createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
        )
    }
}
#endif
