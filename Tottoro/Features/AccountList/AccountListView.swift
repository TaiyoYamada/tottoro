//
//  AccountListView.swift
//  Tottoro
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
                .navigationTitle("Tottoro")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    #if os(iOS)
                    // Mac は標準の設定ウインドウ（⌘,）から開く
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Settings", systemImage: "gearshape") {
                            viewModel.sheet = .settings
                        }
                    }
                    #endif
                    ToolbarItem(placement: .primaryAction) {
                        Button("Add", systemImage: "plus") {
                            viewModel.sheet = .add
                        }
                        // スクリーンショットは言語ごとに撮るので、ラベルではなくこれで探す
                        .accessibilityIdentifier("addAccount")
                    }
                }
        }
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .add:
                AddAccountView(store: store)
            case let .edit(account):
                EditAccountView(account: account, store: store)
            case .settings:
                SettingsView(store: store)
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
                Label("No Accounts", systemImage: "key.viewfinder")
            } description: {
                Text("Scan a two-factor authentication QR code to add an account.")
            } actions: {
                Button("Add Account") {
                    viewModel.sheet = .add
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
