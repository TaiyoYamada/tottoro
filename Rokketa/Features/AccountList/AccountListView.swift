//
//  AccountListView.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

/// Authy と同じく、上に選んだアカウントの大きなコード、下にアカウントの丸を並べる。
struct AccountListView: View {
    @State private var viewModel: AccountListViewModel
    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
        _viewModel = State(initialValue: AccountListViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Rokketa")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("追加", systemImage: "plus") {
                            viewModel.sheet = .add
                        }
                    }
                }
        }
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .add:
                AddAccountView(store: store)
            case .edit(let account):
                EditAccountView(account: account, store: store)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let selected = viewModel.selectedAccount {
            VStack(spacing: 0) {
                CodeHeaderView(account: selected, viewModel: viewModel)
                ScrollView {
                    AccountGridView(viewModel: viewModel, selectedID: selected.id)
                        .padding(Spacing.medium)
                }
            }
        } else {
            ContentUnavailableView {
                Label("アカウントがありません", systemImage: "key.viewfinder")
            } description: {
                Text("二要素認証の QR コードを読み取って追加します")
            } actions: {
                Button("アカウントを追加") {
                    viewModel.sheet = .add
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
