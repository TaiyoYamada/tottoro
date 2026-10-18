//
//  OneTimeCodeText.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

/// 123456 を 123 456 のように真ん中で区切って読みやすくする。コピーするのは区切りのないコード。
/// 隠すときは、桁数だけが分かるよう点に置き換える。
struct OneTimeCodeText: View {
    let code: String
    let font: Font
    var isHidden = false

    var body: some View {
        let shown = isHidden ? String(repeating: "•", count: code.count) : code
        let half = shown.count / 2
        Text(verbatim: "\(shown.prefix(half)) \(shown.dropFirst(half))")
            .font(font)
            .contentTransition(.numericText())
            .accessibilityLabel(isHidden ? Text("Hidden code") : Text(verbatim: spokenCode))
    }

    /// 1 桁ずつ読み上げさせる。続けて書くと、123456 は「十二万…」と数として読まれる
    private var spokenCode: String {
        code.map(String.init).joined(separator: " ")
    }
}
