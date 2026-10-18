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
            errorMessage = lastError ?? String(localized: "二要素認証の QR コードが見つかりませんでした")
            phase = .choosing
            return
        }
        store.add(accounts)
        phase = .finished(added: accounts.count, skipped: skipped)
    }

    func addManualEntry() {
        guard let secret = Base32.decode(manualSecret), !secret.isEmpty else {
            errorMessage = String(localized: "秘密鍵は A〜Z と 2〜7 の文字で入力してください")
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
                errorMessage = String(localized: "写真を読み込めませんでした")
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
            errorMessage = String(localized: "画面を読み取れませんでした。システム設定の「プライバシーとセキュリティ」で、Tottoro に画面収録を許可してください。")
            phase = .choosing
        }
    }
    #endif

    private static func message(for error: OTPAuthURI.ParseError) -> String {
        switch error {
        case .invalidURL: String(localized: "QR コードの形式が正しくありません")
        case .unsupportedType: String(localized: "回数で変わるコード（HOTP）にはまだ対応していません")
        case .missingSecret, .invalidSecret: String(localized: "QR コードに正しい秘密鍵が入っていません")
        case .unsupportedAlgorithm: String(localized: "対応していない計算方式です")
        case .invalidDigits: String(localized: "コードの桁数は 6〜8 桁にだけ対応しています")
        case .invalidPeriod: String(localized: "コードの切り替わる間隔が正しくありません")
        }
    }

    private static func message(for error: GoogleMigrationParser.ParseError) -> String {
        switch error {
        case .invalidURL, .invalidPayload: String(localized: "Google Authenticator の QR コードを読み取れませんでした")
        }
    }
}
