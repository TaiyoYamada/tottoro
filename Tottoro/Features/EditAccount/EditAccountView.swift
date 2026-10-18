//
//  EditAccountView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import TottoroCore
import SwiftUI

struct EditAccountView: View {
    @State private var viewModel: EditAccountViewModel
    @Environment(\.dismiss) private var dismiss

    init(account: Account, store: AccountStore) {
        _viewModel = State(initialValue: EditAccountViewModel(account: account, store: store))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("発行元", text: $viewModel.issuer)
                    TextField("アカウント名", text: $viewModel.name)
                }
                Section {
                    TextField("ドメイン（例: github.com）", text: $viewModel.domain)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                } header: {
                    Text("自動入力")
                } footer: {
                    Text("ここに入れたドメインのサイトで、Safari などにコードの候補が出ます。")
                }
                Section("色") {
                    colorPicker
                }
            }
            .formStyle(.grouped)
            .navigationTitle("アカウントを編集")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.save()
                        dismiss()
                    }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 420)
        #endif
    }

    private var colorPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 36), spacing: Spacing.medium)], spacing: Spacing.medium) {
            ForEach(AccountColor.allCases, id: \.self) { color in
                Button {
                    viewModel.color = color
                } label: {
                    Circle()
                        .fill(color.color)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if color == viewModel.color {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(color.localizedName))
                .accessibilityAddTraits(color == viewModel.color ? .isSelected : [])
            }
        }
        .padding(.vertical, Spacing.small)
    }
}
