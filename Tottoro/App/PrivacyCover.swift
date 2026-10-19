//
//  PrivacyCover.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import SwiftUI

/// App スイッチャーに写る画面を隠す。スナップショットは裏に回る前に撮られるので、ロックより先に inactive の時点で隠す。
/// シートは RootView の上に別に重なるので、シートの画面にもそれぞれ付ける。
struct PrivacyCover: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        #if os(iOS)
        content.overlay {
            if scenePhase != .active {
                Rectangle()
                    .fill(.background)
                    .ignoresSafeArea()
            }
        }
        #else
        content
        #endif
    }
}

extension View {
    func privacyCover() -> some View {
        modifier(PrivacyCover())
    }
}
