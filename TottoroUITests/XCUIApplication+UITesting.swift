//
//  XCUIApplication+UITesting.swift
//  TottoroUITests
//
//  Created by 山田大陽 on 2026/10/18.
//

import XCTest

@MainActor
extension XCUIApplication {
    /// 本物のキーチェーンに触らず、架空のアカウントが入ってロックの外れた状態で開く。
    /// 引数は Tottoro/Debug/UITesting.swift の launchArgument と歩調を合わせる。
    /// 言語を指定しないときは、テストプランの言語の設定に従う。
    static func launchForUITesting(language: String? = "en") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        if let language {
            app.launchArguments += ["-AppleLanguages", "(\(language))"]
        }
        app.launch()
        return app
    }
}
