//
//  ProjectLink.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

/// 設定の「このアプリについて」から開くページ。リリースした版の内容を指すよう、main を見せる。
enum ProjectLink: String {
    case sourceCode = "https://github.com/TaiyoYamada/tottoro"
    case license = "https://github.com/TaiyoYamada/tottoro/blob/main/LICENSE"
    case privacyPolicy = "https://github.com/TaiyoYamada/tottoro/blob/main/docs/privacy.md"
    case reportVulnerability = "https://github.com/TaiyoYamada/tottoro/security/advisories/new"

    var url: URL {
        // 固定の文字列なので、URL にできなければここで落ちてよい
        // swiftlint:disable:next force_unwrapping
        URL(string: rawValue)!
    }
}
