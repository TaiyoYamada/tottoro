//
//  AccountColor+Color.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI
import TottoroCore

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
        case .red: String(localized: "Red")
        case .orange: String(localized: "Orange")
        case .green: String(localized: "Green")
        case .teal: String(localized: "Teal")
        case .blue: String(localized: "Blue")
        case .indigo: String(localized: "Indigo")
        case .purple: String(localized: "Purple")
        case .pink: String(localized: "Pink")
        case .brown: String(localized: "Brown")
        case .gray: String(localized: "Gray")
        }
    }
}
