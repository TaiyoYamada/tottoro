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
                .navigationTitle("Add Account")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", role: .cancel) {
                            dismiss()
                        }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 460)
        #endif
        .privacyCover()
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task { await viewModel.readQRCode(from: item) }
        }
        .alert(
            "Couldn’t Add the Account",
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
            ProgressView("Reading…")
        case let .finished(result):
            ContentUnavailableView {
                Label("Added \(result.added) accounts", systemImage: "checkmark.circle.fill")
            } description: {
                if result.alreadyAdded > 0 {
                    Text("\(result.alreadyAdded) accounts were already in Tottoro.")
                }
                if result.unsupported > 0 {
                    Text("""
                    \(result.unsupported) accounts were not added because Tottoro does not support them, \
                    such as counter-based codes (HOTP).
                    """)
                }
            } actions: {
                Button("Done") {
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
                Button("Scan with Camera", systemImage: "qrcode.viewfinder") {
                    viewModel.phase = .scanningCamera
                }
                .disabled(!QRScannerView.isAvailable)
                #elseif os(macOS)
                Button("Scan from Screen", systemImage: "rectangle.dashed") {
                    Task { await viewModel.readQRCodeFromScreen() }
                }
                #endif
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose from Photos", systemImage: "photo")
                }
                Button("Enter Manually", systemImage: "keyboard") {
                    viewModel.phase = .enteringManually
                }
            } footer: {
                Text("You can also scan the QR code from “Transfer accounts” in Google Authenticator.")
            }
        }
        .formStyle(.grouped)
    }
}
