//
//  AccountColor.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/18.
//

/// アカウントごとの背景色。白い文字が読める色だけを並べている。
public enum AccountColor: String, Codable, CaseIterable, Sendable {
    case red
    case orange
    case green
    case teal
    case blue
    case indigo
    case purple
    case pink
    case brown
    case gray

    /// 取り込んだアカウントの色がばらけるように、発行元の名前から決まった色を選ぶ。
    /// String の hashValue は起動ごとに変わるので使わない。
    public static func suggested(for issuer: String) -> AccountColor {
        let sum = issuer.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return allCases[sum % allCases.count]
    }
}
