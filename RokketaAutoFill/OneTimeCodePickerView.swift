//
//  OneTimeCodePickerView.swift
//  RokketaAutoFill
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

struct OneTimeCodePickerView: View {
    let viewModel: OneTimeCodePickerViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Rokketa")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル", role: .cancel) {
                            viewModel.cancel()
                        }
                    }
                }
        }
        .task {
            await viewModel.unlock()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .locked, .authenticating:
            ContentUnavailableView {
                Label("ロック中", systemImage: "lock.fill")
            } actions: {
                Button("ロックを解除") {
                    Task { await viewModel.unlock() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .unlocked(let accounts):
            TimelineView(.periodic(from: .now, by: 1)) { context in
                List(accounts) { account in
                    Button {
                        viewModel.select(account)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(account.displayName)
                                if !account.name.isEmpty, account.name != account.displayName {
                                    Text(account.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(viewModel.code(for: account, at: context.date))
                                .font(.body.monospacedDigit())
                        }
                    }
                }
            }
        }
    }
}
