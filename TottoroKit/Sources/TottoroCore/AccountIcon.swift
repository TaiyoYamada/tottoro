//
//  AccountIcon.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

/// アカウントの丸に載せるもの。Account の icon が nil のときは、発行元とドメインから自動で選ぶ。
public enum AccountIcon: Codable, Hashable, Sendable {
    /// サービスのロゴ。値は Simple Icons の slug（github など）。
    case service(String)
    /// ロゴを使わず、発行元の頭文字を出す。
    case initial
}
