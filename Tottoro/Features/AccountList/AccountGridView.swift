//
//  AccountGridView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import TottoroCore
import SwiftUI

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
                    Button("編集", systemImage: "pencil") {
                        viewModel.sheet = .edit(account)
                    }
                    Button("削除", systemImage: "trash", role: .destructive) {
                        accountToDelete = account
                    }
                }
            }
        }
        .confirmationDialog(
            "このアカウントを削除しますか？",
            isPresented: Binding(get: { accountToDelete != nil }, set: { if !$0 { accountToDelete = nil } }),
            presenting: accountToDelete
        ) { account in
            Button("削除", role: .destructive) {
                viewModel.delete(account)
            }
        } message: { _ in
            Text("サイト側で二要素認証を外していないと、そのサイトにログインできなくなります。iCloud でつながったすべての端末から消えます。")
        }
    }
}
