//
//  OneTimeCodePickerView.swift
//  TottoroAutoFill
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

struct OneTimeCodePickerView: View {
    let viewModel: OneTimeCodePickerViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Tottoro")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
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
            lockedView(message: nil)
        case .failed(.canceled):
            lockedView(message: "Unlocking was canceled.")
        case .failed(.failed):
            lockedView(message: "Couldn’t confirm it’s you. Try again.")
        case .failed(.passcodeNotSet):
            // パスコードのない端末では、コードを渡さない。アプリの側と同じ扱い
            ContentUnavailableView(
                "Set a Passcode",
                systemImage: "lock.slash",
                description: Text("Tottoro needs a passcode on this device to protect your codes."),
            )
        case let .unlocked(accounts):
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

    private func lockedView(message: LocalizedStringResource?) -> some View {
        ContentUnavailableView {
            Label("Locked", systemImage: "lock.fill")
        } description: {
            if let message {
                Text(message)
            }
        } actions: {
            Button("Unlock") {
                Task { await viewModel.unlock() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
