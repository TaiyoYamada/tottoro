//
//  Typography.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

enum Typography {
    /// 数字の幅をそろえないと、コードが変わるたびに横に揺れる。
    static let headerCode = Font.system(size: 56, weight: .semibold, design: .rounded).monospacedDigit()
    static let headerIssuer = Font.title2.weight(.semibold)
    static let headerName = Font.subheadline
    static let rowCode = Font.system(.title3, design: .rounded).weight(.semibold).monospacedDigit()
    static let avatarInitial = Font.system(.title2, design: .rounded).weight(.bold)
    static let smallAvatarInitial = Font.system(.headline, design: .rounded).weight(.bold)
    static let countdown = Font.caption.weight(.semibold).monospacedDigit()
}
