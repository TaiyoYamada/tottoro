//
//  MenuBarView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

#if os(macOS)
import SwiftUI

/// メニューバーから開く小さな画面。検索して、クリックでコードをコピーする。
struct MenuBarView: View {
    @State private var viewModel: MenuBarViewModel
    @Environment(AppLock.self) private var lock
    @Environment(\.openWindow) private var openWindow
    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
        _viewModel = State(initialValue: MenuBarViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            switch lock.state {
            case .locked, .authenticating, .failed:
                LockView()
                    .frame(height: 260)
            case .unlocked:
                accountList
            }
            Divider()
            HStack {
                Button("Open Tottoro") {
                    openWindow(id: SceneID.main, value: SceneID.main)
                    NSApp.activate()
                }
                Spacer()
                // Dock に出さない設定では、アプリのメニューも ⌘, も使えないので、ここから設定を開けるようにする
                SettingsLink {
                    Text("Settings")
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
            .buttonStyle(.borderless)
            .padding(Spacing.small)
        }
        .frame(width: 320)
        .onAppear {
            viewModel.reload()
            Task { await lock.unlock() }
        }
        .failureAlert(store: store)
    }

    private var accountList: some View {
        VStack(spacing: 0) {
            TextField("Search", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .padding(Spacing.small)
            if viewModel.accounts.isEmpty {
                ContentUnavailableView.search
                    .frame(height: 200)
            } else {
                ScrollView {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.accounts) { account in
                                MenuBarRow(
                                    account: account,
                                    code: viewModel.code(for: account, at: context.date),
                                    secondsRemaining: viewModel.secondsRemaining(for: account, at: context.date),
                                    isCopied: viewModel.copiedAccountID == account.id,
                                ) {
                                    Task { await viewModel.copyCode(of: account) }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 400)
            }
        }
    }
}
#endif
