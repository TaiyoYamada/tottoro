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
        case finished(added: Int, skipped: Int)
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
        store.add(accounts)
        phase = .finished(added: accounts.count, skipped: skipped)
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
        store.add([account])
        phase = .finished(added: 1, skipped: 0)
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
