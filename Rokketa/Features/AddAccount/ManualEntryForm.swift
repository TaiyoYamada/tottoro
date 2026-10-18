//
//  ManualEntryForm.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

import RokketaCore
import SwiftUI

/// QR コードが読めないときに、サイトに表示された「セットアップキー」を打ち込む。
struct ManualEntryForm: View {
    @Bindable var viewModel: AddAccountViewModel

    var body: some View {
        Form {
            Section {
                TextField("発行元（例: GitHub）", text: $viewModel.manualIssuer)
                TextField("アカウント名（例: メールアドレス）", text: $viewModel.manualName)
                    .textContentType(.username)
                TextField("セットアップキー", text: $viewModel.manualSecret)
                    .font(.body.monospaced())
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
            }
            Section("詳細") {
                Picker("計算方式", selection: $viewModel.manualAlgorithm) {
                    Text("SHA-1").tag(HashAlgorithm.sha1)
                    Text("SHA-256").tag(HashAlgorithm.sha256)
                    Text("SHA-512").tag(HashAlgorithm.sha512)
                }
                Picker("桁数", selection: $viewModel.manualDigits) {
                    Text("6 桁").tag(6)
                    Text("7 桁").tag(7)
                    Text("8 桁").tag(8)
                }
                Picker("間隔", selection: $viewModel.manualPeriod) {
                    Text("30 秒").tag(30)
                    Text("60 秒").tag(60)
                }
            }
            Section {
                Button("追加") {
                    viewModel.addManualEntry()
                }
                .disabled(!viewModel.canSubmitManualEntry)
            }
        }
        .formStyle(.grouped)
    }
}
