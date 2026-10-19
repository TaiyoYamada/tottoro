//
//  FailureAlert.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

/// AccountStore の保存や読み込みの失敗を出す。メインの画面とメニューバーの両方で使う。
struct FailureAlert: ViewModifier {
    let store: AccountStore

    func body(content: Content) -> some View {
        content.alert(
            "Error",
            isPresented: Binding(
                get: { store.failure != nil },
                set: {
                    if !$0 {
                        store.failure = nil
                    }
                },
            ),
            presenting: store.failure,
        ) { _ in
            Button("OK") {}
        } message: { failure in
            Text(failure.message)
        }
    }
}

extension View {
    func failureAlert(store: AccountStore) -> some View {
        modifier(FailureAlert(store: store))
    }
}
