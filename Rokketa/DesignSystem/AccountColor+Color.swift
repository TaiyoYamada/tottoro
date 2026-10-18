//
//  AccountColor+Color.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

import RokketaCore
import SwiftUI

extension AccountColor {
    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .green: .green
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        case .gray: .gray
        }
    }

    var localizedName: String {
        switch self {
        case .red: String(localized: "赤")
        case .orange: String(localized: "オレンジ")
        case .green: String(localized: "緑")
        case .teal: String(localized: "青緑")
        case .blue: String(localized: "青")
        case .indigo: String(localized: "藍")
        case .purple: String(localized: "紫")
        case .pink: String(localized: "ピンク")
        case .brown: String(localized: "茶")
        case .gray: String(localized: "灰")
        }
    }
}
