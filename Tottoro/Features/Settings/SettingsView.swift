//
//  SettingsView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import AuthenticationServices
import SwiftUI

/// iPhone では一覧の画面から開くシート、Mac では標準の設定ウインドウ（⌘,）に出す。
struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @State private var isImporting = false
    @AppStorage(SettingsKey.lockDelay) private var lockDelay = LockDelay.immediately
    @AppStorage(SettingsKey.hidesCodes) private var hidesCodes = false
    #if os(macOS)
    @AppStorage(SettingsKey.showsInDock) private var showsInDock = true
    #endif
    @Environment(\.dismiss) private var dismiss
    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
        _viewModel = State(initialValue: SettingsViewModel(store: store))
    }

    var body: some View {
        #if os(iOS)
        NavigationStack {
            form
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .privacyCover()
        #else
        form
            .frame(width: 460)
            .fixedSize(horizontal: false, vertical: true)
        #endif
    }

    private var form: some View {
        Form {
            security
            autoFill
            transfer
            #if os(macOS)
            mac
            #endif
            about
        }
        .formStyle(.grouped)
        .task {
            await viewModel.refreshAutoFillStatus()
        }
        .sheet(isPresented: $isImporting) {
            AddAccountView(store: store)
        }
        .alert(
            "Exported Your Accounts",
            isPresented: Binding(
                get: {
                    if case .exported = viewModel.exportPhase {
                        true
                    } else {
                        false
                    }
                },
                set: {
                    if !$0 {
                        viewModel.exportPhase = .idle
                    }
                },
            ),
        ) {
            Button("OK") {}
        } message: {
            if case let .exported(count) = viewModel.exportPhase {
                Text("Exported \(count) accounts.")
            }
        }
        .alert(
            "Couldn’t Export",
            isPresented: Binding(
                get: {
                    if case .failed = viewModel.exportPhase {
                        true
                    } else {
                        false
                    }
                },
                set: {
                    if !$0 {
                        viewModel.exportPhase = .idle
                    }
                },
            ),
        ) {
            Button("OK") {}
        } message: {
            if case let .failed(message) = viewModel.exportPhase {
                Text(message)
            }
        }
    }

    private var security: some View {
        Section {
            Picker("Lock", selection: $lockDelay) {
                ForEach(LockDelay.allCases) { delay in
                    Text(delay.title).tag(delay)
                }
            }
            Toggle("Hide Codes", isOn: $hidesCodes)
        } header: {
            Text("Security")
        } footer: {
            Text("Hidden codes show after a tap, so people nearby can’t read them.")
        }
    }

    private var autoFill: some View {
        Section {
            switch viewModel.autoFillStatus {
            case .checking:
                LabeledContent("AutoFill") {
                    ProgressView()
                }
            case .enabled:
                LabeledContent("AutoFill", value: String(localized: "On"))
            case .disabled:
                LabeledContent("AutoFill", value: String(localized: "Off"))
                Button("Turn On AutoFill") {
                    Task { await viewModel.turnOnAutoFill() }
                }
            }
        } header: {
            Text("AutoFill")
        } footer: {
            Text("Safari and other apps suggest codes from Tottoro on sites whose domain you set for an account.")
        }
    }

    private var transfer: some View {
        Section {
            Button("Import from Another App") {
                isImporting = true
            }
            Button("Export to Another App") {
                Task { await viewModel.export() }
            }
            .disabled(!viewModel.hasAccounts || viewModel.exportPhase == .exporting)
        } header: {
            Text("Transfer")
        } footer: {
            Text("""
            Exporting sends your secret keys to the app you choose, through the system. \
            Tottoro asks you to confirm it’s you first.
            """)
        }
    }

    #if os(macOS)
    private var mac: some View {
        Section("Mac") {
            Toggle("Open at Login", isOn: Binding(
                get: { viewModel.opensAtLogin },
                set: { viewModel.setOpensAtLogin($0) },
            ))
            Toggle("Show in Dock", isOn: $showsInDock)
                .onChange(of: showsInDock) { _, shows in
                    NSApplication.shared.setActivationPolicy(shows ? .regular : .accessory)
                }
        }
        .alert(
            "Couldn’t Change the Login Item",
            isPresented: Binding(
                get: { viewModel.loginItemError != nil },
                set: {
                    if !$0 {
                        viewModel.loginItemError = nil
                    }
                },
            ),
        ) {
            Button("OK") {}
        } message: {
            Text(viewModel.loginItemError ?? "")
        }
    }
    #endif

    private var about: some View {
        Section("About") {
            LabeledContent("Version", value: viewModel.version)
            Link("Source Code", destination: ProjectLink.sourceCode.url)
            Link("License", destination: ProjectLink.license.url)
            Link("Privacy Policy", destination: ProjectLink.privacyPolicy.url)
            Link("Report a Vulnerability", destination: ProjectLink.reportVulnerability.url)
        }
    }
}
