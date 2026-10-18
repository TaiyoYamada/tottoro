//
//  CredentialImportAlerts.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import SwiftUI

/// Credential Exchange で取り込んだ結果を出す。
struct CredentialImportAlerts: ViewModifier {
    @Bindable var viewModel: CredentialImportViewModel

    func body(content: Content) -> some View {
        content
            .alert(
                "Imported Accounts",
                isPresented: Binding(
                    get: {
                        if case .finished = viewModel.phase {
                            true
                        } else {
                            false
                        }
                    },
                    set: {
                        if !$0 {
                            viewModel.phase = .idle
                        }
                    },
                ),
            ) {
                Button("OK") {}
            } message: {
                if case let .finished(result) = viewModel.phase {
                    Text(message(for: result))
                }
            }
            .alert(
                "Couldn’t Import",
                isPresented: Binding(
                    get: {
                        if case .failed = viewModel.phase {
                            true
                        } else {
                            false
                        }
                    },
                    set: {
                        if !$0 {
                            viewModel.phase = .idle
                        }
                    },
                ),
            ) {
                Button("OK") {}
            } message: {
                if case let .failed(message) = viewModel.phase {
                    Text(message)
                }
            }
    }

    /// 足した件数と、足さなかった件数とその理由を、行に分けて 1 つの文にする。
    private func message(for result: AddResult) -> String {
        var lines = [String(localized: "Added \(result.added) accounts")]
        if result.alreadyAdded > 0 {
            lines.append(String(localized: "\(result.alreadyAdded) accounts were already in Tottoro."))
        }
        if result.unsupported > 0 {
            lines.append(String(localized: """
            \(result.unsupported) accounts were not added because Tottoro does not support them, \
            such as counter-based codes (HOTP).
            """))
        }
        return lines.joined(separator: "\n")
    }
}

extension View {
    func credentialImportAlerts(_ viewModel: CredentialImportViewModel) -> some View {
        modifier(CredentialImportAlerts(viewModel: viewModel))
    }
}
