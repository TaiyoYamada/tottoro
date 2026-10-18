//
//  LockDelay.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation

/// アプリが裏に回ってから、ロックするまでの時間。ロックをしない選択肢は、わざと用意していない。
enum LockDelay: Int, CaseIterable, Identifiable {
    case immediately = 0
    case oneMinute = 60
    case fiveMinutes = 300

    var id: Int {
        rawValue
    }

    var duration: Duration {
        .seconds(rawValue)
    }

    var title: LocalizedStringResource {
        switch self {
        case .immediately: "Immediately"
        case .oneMinute: "After 1 Minute"
        case .fiveMinutes: "After 5 Minutes"
        }
    }
}
