//
//  AccountAvatar.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import TottoroCore
import SwiftUI

/// アカウントの色の丸に、発行元の頭文字を載せたもの。
struct AccountAvatar: View {
    enum Size {
        case regular
        case small

        var diameter: CGFloat {
            switch self {
            case .regular: 60
            case .small: 32
            }
        }

        var font: Font {
            switch self {
            case .regular: Typography.avatarInitial
            case .small: Typography.smallAvatarInitial
            }
        }
    }

    let account: Account
    var size: Size = .regular

    var body: some View {
        Text(account.displayName.first.map { String($0).uppercased() } ?? "?")
            .font(size.font)
            .foregroundStyle(.white)
            .frame(width: size.diameter, height: size.diameter)
            .background(account.color.color, in: .circle)
            .accessibilityHidden(true)
    }
}
