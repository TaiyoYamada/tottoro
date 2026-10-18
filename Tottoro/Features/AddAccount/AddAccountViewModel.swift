//
//  AddAccountViewModel.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Observation
import PhotosUI
import SwiftUI
import TottoroCore

@Observable
final class AddAccountViewModel {
    enum Phase: Equatable {
        case choosing
        case scanningCamera
        case enteringManually
        case reading
        /// 暗号化された書き出しを開くパスワードを聞いている。
        case enteringPassword(Data)
        case finished(AddResult)
    }

    var phase: Phase = .choosing
    var errorMessage: String?

    var manualIssuer = ""
    var manualName = ""
    var manualSecret = ""
    var manualAlgorithm: HashAlgorithm = .sha1
    var manualDigits = 6
    var manualPeriod = 30

    private let store: AccountStore

    init(store: AccountStore) {
        self.store = store
    }

    var canSubmitManualEntry: Bool {
        !manualSecret.trimmingCharacters(in: .whitespaces).isEmpty
            && !(manualIssuer.isEmpty && manualName.isEmpty)
    }

    /// QR コードから読み取った文字列を受け取る。カメラ、写真、画面のどれから読んでもここに来る。
    func handleScannedPayloads(_ payloads: [String]) {
        var accounts: [Account] = []
        var skipped = 0
        var lastError: String?
        for payload in payloads {
            if payload.lowercased().hasPrefix("otpauth-migration:") {
                do throws(GoogleMigrationParser.ParseError) {
                    let result = try GoogleMigrationParser.parse(payload)
                    accounts += result.accounts
                    skipped += result.skippedCount
                } catch {
                    lastError = Self.message(for: error)
                }
            } else if payload.lowercased().hasPrefix("otpauth:") {
                do throws(OTPAuthURI.ParseError) {
                    try accounts.append(OTPAuthURI.account(from: payload))
                } catch {
                    lastError = Self.message(for: error)
                }
            }
        }

        guard !accounts.isEmpty else {
            errorMessage = lastError ?? String(localized: "No two-factor authentication QR code was found.")
            phase = .choosing
            return
        }
        let added = store.add(accounts)
        phase = .finished(AddResult(added: added, alreadyAdded: accounts.count - added, unsupported: skipped))
    }

    func addManualEntry() {
        guard let secret = Base32.decode(manualSecret), !secret.isEmpty else {
            errorMessage = String(localized: "Enter the setup key using only the letters A–Z and the digits 2–7.")
            return
        }
        let account = Account(
            issuer: manualIssuer.trimmingCharacters(in: .whitespaces),
            name: manualName.trimmingCharacters(in: .whitespaces),
            secret: secret,
            algorithm: manualAlgorithm,
            digits: manualDigits,
            period: manualPeriod,
        )
        let added = store.add([account])
        phase = .finished(AddResult(added: added, alreadyAdded: 1 - added, unsupported: 0))
    }

    func readQRCode(from item: PhotosPickerItem) async {
        phase = .reading
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = String(localized: "Couldn’t load the photo.")
                phase = .choosing
                return
            }
            try await handleScannedPayloads(QRCodeImageReader.payloads(inImageData: data))
        } catch {
            errorMessage = error.localizedDescription
            phase = .choosing
        }
    }

    /// 他のアプリの書き出しのファイルを読む。暗号化されていれば、パスワードを聞いてから submitPassword で開く。
    func importFile(_ result: Result<URL, any Error>) {
        let data: Data
        do {
            let url = try result.get()
            // ファイルの選択で渡された URL はアプリの外の場所なので、読む間だけ許可を得る
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            data = try Data(contentsOf: url)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        importFile(data, password: nil)
    }

    func submitPassword(_ password: String) {
        guard case let .enteringPassword(data) = phase else { return }
        importFile(data, password: password)
    }

    private func importFile(_ data: Data, password: String?) {
        do throws(ExportFileImporter.ImportError) {
            let imported = try ExportFileImporter.importAccounts(from: data, password: password)
            let added = store.add(imported.accounts)
            phase = .finished(AddResult(
                added: added,
                alreadyAdded: imported.accounts.count - added,
                unsupported: imported.skippedCount,
            ))
        } catch {
            switch error {
            case .passwordRequired:
                phase = .enteringPassword(data)
            case .wrongPassword:
                errorMessage = String(localized: "The password is incorrect.")
            case .unsupportedFile:
                errorMessage = String(localized: """
                Tottoro can’t read this file. Export from 2FAS, Aegis, Bitwarden Authenticator, \
                or the Passwords app, or choose a text file with otpauth links.
                """)
            case .invalidFile:
                errorMessage = String(localized: "The file is damaged or incomplete.")
            }
        }
    }

    #if os(macOS)
    func readQRCodeFromScreen() async {
        phase = .reading
        do {
            try await handleScannedPayloads(ScreenQRReader.payloads())
        } catch {
            errorMessage = String(localized: """
            Couldn’t read the screen. \
            Allow Tottoro to record the screen in System Settings > Privacy & Security.
            """)
            phase = .choosing
        }
    }
    #endif

    private static func message(for error: OTPAuthURI.ParseError) -> String {
        switch error {
        case .invalidURL: String(localized: "The QR code is not in a valid format.")
        case .unsupportedType: String(localized: "Counter-based codes (HOTP) are not supported yet.")
        case .missingSecret, .invalidSecret: String(localized: "The QR code does not contain a valid secret key.")
        case .unsupportedAlgorithm: String(localized: "This algorithm is not supported.")
        case .invalidDigits: String(localized: "Only codes with 6 to 8 digits are supported.")
        case .invalidPeriod: String(localized: "The code period is not valid.")
        }
    }

    private static func message(for error: GoogleMigrationParser.ParseError) -> String {
        switch error {
        case .invalidURL, .invalidPayload: String(localized: "Couldn’t read the Google Authenticator QR code.")
        }
    }
}
