//
//  KeyWindow.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import AuthenticationServices
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// OS の画面（書き出し先の選択など）を重ねる、いま前面にあるウインドウ。
enum KeyWindow {
    static var current: ASPresentationAnchor? {
        #if os(iOS)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .keyWindow
        #elseif os(macOS)
        NSApplication.shared.keyWindow
        #endif
    }
}
