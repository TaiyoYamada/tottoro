//
//  EditAccountView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI
import TottoroCore

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
                    TextField("Issuer", text: $viewModel.issuer)
                    TextField("Account Name", text: $viewModel.name)
                }
                Section {
                    TextField("Domain (e.g. github.com)", text: $viewModel.domain)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        #endif
                } header: {
                    Text("AutoFill")
                } footer: {
                    Text("Safari and other apps suggest the code on sites with this domain.")
                }
                Section("Color") {
                    colorPicker
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
