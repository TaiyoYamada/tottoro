//
//  SettingsViewModel.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import AuthenticationServices
import Foundation
import Observation
import TottoroCore
import TottoroStorage
#if os(macOS)
import ServiceManagement
#endif

@Observable
final class SettingsViewModel {
    enum AutoFillStatus {
        case checking
        case enabled
        case disabled
    }

    enum ExportPhase: Equatable {
        case idle
        case exporting
        case exported(count: Int)
        case failed(String)
    }

    private(set) var autoFillStatus: AutoFillStatus = .checking
    var exportPhase: ExportPhase = .idle
    #if os(macOS)
    private(set) var opensAtLogin = SMAppService.mainApp.status == .enabled
    var loginItemError: String?
    #endif

    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
    }

    var hasAccounts: Bool {
        !store.accounts.isEmpty
    }

    var version: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? ""
        let build = info?["CFBundleVersion"] as? String ?? ""
        return "\(version) (\(build))"
    }

    func refreshAutoFillStatus() async {
        autoFillStatus = await ASCredentialIdentityStore.shared.state().isEnabled ? .enabled : .disabled
    }

    /// オフなら、OS がオンにしてよいかを尋ねる画面を出す。
    func turnOnAutoFill() async {
        let isEnabled = await ASSettingsHelper.requestToTurnOnCredentialProviderExtension()
        autoFillStatus = isEnabled ? .enabled : .disabled
        if isEnabled {
            await store.registerAutoFillSuggestions()
        }
    }

    /// 秘密鍵を外へ出すので、ロックが外れていても、もう一度本人を確かめてから書き出す。
    func export() async {
        // ボタンを押したウインドウが前面にあるので、ここで見つからないことはない
        // swiftlint:disable:next force_unwrapping
        let window = KeyWindow.current!
        exportPhase = .exporting
        do throws(DeviceOwnerAuthentication.Failure) {
            let reason = String(localized: "Confirm it’s you to export your accounts")
            try await DeviceOwnerAuthentication.authenticate(reason: reason)
        } catch {
            exportPhase = .idle
            return
        }
        let accounts = store.accounts
        let manager = ASCredentialExportManager(presentationAnchor: window)
        do {
            let options = try await manager.requestExport()
            let data = CredentialExchange.exportedData(
                from: accounts,
                formatVersion: options.formatVersion,
                exportedAt: Date(),
            )
            try await manager.exportCredentials(data)
            exportPhase = .exported(count: accounts.count)
        } catch {
            exportPhase = .failed(error.localizedDescription)
        }
    }

    #if os(macOS)
    func setOpensAtLogin(_ opens: Bool) {
        do {
            if opens {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            loginItemError = error.localizedDescription
        }
        opensAtLogin = SMAppService.mainApp.status == .enabled
    }
    #endif
}
