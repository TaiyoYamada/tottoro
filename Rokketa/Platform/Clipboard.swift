//
//  Clipboard.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum Clipboard {
    /// コードはすぐ使い終わるので、他の端末へ渡さず、残りっぱなしにもしない。
    static func copyOneTimeCode(_ code: String) {
        #if os(iOS)
        // ユニバーサルクリップボードで Mac へ流れないようにし、1 分で消す
        UIPasteboard.general.setItems(
            [[UTType.plainText.identifier: code]],
            options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(60)]
        )
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
        // nspasteboard.org の約束事。対応したクリップボード履歴のアプリは、この型が付いたものを記録しない
        pasteboard.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        #endif
    }
}
