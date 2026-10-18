//
//  ServiceIcons.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation
import TottoroCore

/// アプリに同梱したサービスのロゴ。画像は ServiceIcons.xcassets の ServiceIcons/<slug>。
enum ServiceIcons {
    static let catalog: ServiceIconCatalog = {
        // どちらもアプリに同梱したファイルなので、読めないのはビルドの誤り。ここで落ちてよい
        // swiftlint:disable:next force_unwrapping
        let url = Bundle.main.url(forResource: "ServiceIcons", withExtension: "json")!
        // swiftlint:disable:next force_try
        return try! ServiceIconCatalog(json: Data(contentsOf: url))
    }()

    static func imageName(for entry: ServiceIconCatalog.Entry) -> String {
        "ServiceIcons/\(entry.slug)"
    }
}
