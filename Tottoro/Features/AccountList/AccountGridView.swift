//
//  AccountGridView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI
import TottoroCore

/// アカウントの丸を格子に並べる。タップで上の大きな表示を切り替え、長押しで編集や削除をする。
struct AccountGridView: View {
    let viewModel: AccountListViewModel
    let selectedID: Account.ID

    @State private var accountToDelete: Account?

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: Spacing.medium)], spacing: Spacing.large) {
            ForEach(viewModel.accounts) { account in
                Button {
                    viewModel.select(account)
                } label: {
                    VStack(spacing: Spacing.small) {
                        AccountAvatar(account: account)
                            .padding(Spacing.xSmall)
                            .overlay {
                                if account.id == selectedID {
                                    Circle().stroke(account.color.color, lineWidth: 3)
                                }
                            }
                        Text(account.displayName)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(account.id == selectedID ? .isSelected : [])
                .contextMenu {
                    Button("Edit", systemImage: "pencil") {
                        viewModel.sheet = .edit(account)
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        accountToDelete = account
                    }
                }
            }
        }
        .confirmationDialog(
            "Delete this account?",
            isPresented: Binding(get: { accountToDelete != nil }, set: {
                if !$0 {
                    accountToDelete = nil
                }
            }),
            presenting: accountToDelete,
        ) { account in
            Button("Delete", role: .destructive) {
                viewModel.delete(account)
            }
        } message: { _ in
            Text("""
            If two-factor authentication is still on for the site, you will no longer be able to sign in to it. \
            The account is removed from all your devices connected through iCloud.
            """)
        }
    }
}
