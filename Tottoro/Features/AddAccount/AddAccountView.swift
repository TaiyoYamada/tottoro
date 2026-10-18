//
//  AddAccountView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import PhotosUI
import SwiftUI

struct AddAccountView: View {
    @State private var viewModel: AddAccountViewModel
    @State private var photoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss

    init(store: AccountStore) {
        _viewModel = State(initialValue: AddAccountViewModel(store: store))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("アカウントを追加")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル", role: .cancel) {
                            dismiss()
                        }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task { await viewModel.readQRCode(from: item) }
        }
        .alert(
            "追加できませんでした",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: {
                    if !$0 {
                        viewModel.errorMessage = nil
                    }
                },
            ),
        ) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .choosing:
            choices
        case .scanningCamera:
            #if os(iOS)
            QRScannerView { payload in
                viewModel.handleScannedPayloads([payload])
            } onFailure: { error in
                viewModel.errorMessage = error.localizedDescription
                viewModel.phase = .choosing
            }
            .ignoresSafeArea(edges: .bottom)
            #else
            choices
            #endif
        case .enteringManually:
            ManualEntryForm(viewModel: viewModel)
        case .reading:
            ProgressView("読み取っています")
        case let .finished(added, skipped):
            ContentUnavailableView {
                Label("\(added) 件のアカウントを追加しました", systemImage: "checkmark.circle.fill")
            } description: {
                if skipped > 0 {
                    Text("回数で変わるコード（HOTP）など、対応していない \(skipped) 件は追加していません。")
                }
            } actions: {
                Button("完了") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var choices: some View {
        Form {
            Section {
                #if os(iOS)
                Button("カメラで読み取る", systemImage: "qrcode.viewfinder") {
                    viewModel.phase = .scanningCamera
                }
                .disabled(!QRScannerView.isAvailable)
                #elseif os(macOS)
                Button("画面から読み取る", systemImage: "rectangle.dashed") {
                    Task { await viewModel.readQRCodeFromScreen() }
                }
                #endif
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("写真から読み取る", systemImage: "photo")
                }
                Button("手入力する", systemImage: "keyboard") {
                    viewModel.phase = .enteringManually
                }
            } footer: {
                Text("Google Authenticator の「アカウントを移行」で表示される QR コードも、そのまま読み取れます。")
            }
        }
        .formStyle(.grouped)
    }
}
