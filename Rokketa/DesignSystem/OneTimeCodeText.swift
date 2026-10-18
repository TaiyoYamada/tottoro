//
//  OneTimeCodeText.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

/// 123456 を 123 456 のように真ん中で区切って読みやすくする。コピーするのは区切りのないコード。
struct OneTimeCodeText: View {
    let code: String
    let font: Font

    var body: some View {
        let half = code.count / 2
        Text("\(code.prefix(half)) \(code.dropFirst(half))")
            .font(font)
            .contentTransition(.numericText())
            .accessibilityLabel(Text(code.map(String.init).joined(separator: " ")))
    }
}
