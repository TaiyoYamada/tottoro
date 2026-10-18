//
//  ManualEntryForm.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI
import TottoroCore

/// QR コードが読めないときに、サイトに表示された「セットアップキー」を打ち込む。
struct ManualEntryForm: View {
    @Bindable var viewModel: AddAccountViewModel

    var body: some View {
        Form {
            Section {
                TextField("Issuer (e.g. GitHub)", text: $viewModel.manualIssuer)
                TextField("Account Name (e.g. email address)", text: $viewModel.manualName)
                    .textContentType(.username)
                TextField("Setup Key", text: $viewModel.manualSecret)
                    .font(.body.monospaced())
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
            }
            Section("Details") {
                Picker("Algorithm", selection: $viewModel.manualAlgorithm) {
                    Text(verbatim: "SHA-1").tag(HashAlgorithm.sha1)
                    Text(verbatim: "SHA-256").tag(HashAlgorithm.sha256)
                    Text(verbatim: "SHA-512").tag(HashAlgorithm.sha512)
                }
                Picker("Digits", selection: $viewModel.manualDigits) {
                    Text("\(6) digits").tag(6)
                    Text("\(7) digits").tag(7)
                    Text("\(8) digits").tag(8)
                }
                Picker("Period", selection: $viewModel.manualPeriod) {
                    Text("\(30) seconds").tag(30)
                    Text("\(60) seconds").tag(60)
                }
            }
            Section {
                Button("Add") {
                    viewModel.addManualEntry()
                }
                .disabled(!viewModel.canSubmitManualEntry)
            }
        }
        .formStyle(.grouped)
    }
}
