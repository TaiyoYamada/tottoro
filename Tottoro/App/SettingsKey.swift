//
//  SettingsKey.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

/// 設定を UserDefaults に保存するときのキー。秘密に関わるものは置かない。
enum SettingsKey {
    static let lockDelay = "lockDelay"
    static let hidesCodes = "hidesCodes"
    static let showsInDock = "showsInDock"
}
