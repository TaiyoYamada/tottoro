//
//  AddAccountViewModelTests.swift
//  RokketaTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import RokketaCore
import Testing
@testable import Rokketa

struct AddAccountViewModelTests {
    @Test func addsAnAccountFromAnOTPAuthQRCode() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)

        viewModel.handleScannedPayloads(["otpauth://totp/GitHub:octocat?secret=MZXW6YTBOI&issuer=GitHub"])

        #expect(viewModel.phase == .finished(added: 1, skipped: 0))
        #expect(store.accounts.map(\.issuer) == ["GitHub"])
    }

    @Test func ignoresQRCodesThatAreNotForTwoFactorAuthentication() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)

        viewModel.handleScannedPayloads(["https://example.com", "otpauth://totp/GitHub:octocat?secret=MZXW6YTBOI"])

        #expect(viewModel.phase == .finished(added: 1, skipped: 0))
    }

    @Test func showsAnErrorWhenNoAccountCanBeRead() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)

        viewModel.handleScannedPayloads(["otpauth://hotp/a?secret=MZXW6YTBOI&counter=1"])

        #expect(viewModel.phase == .choosing)
        #expect(viewModel.errorMessage != nil)
        #expect(store.accounts.isEmpty)
    }

    @Test func addsAManualEntryWithSpacesInTheSetupKey() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)
        viewModel.manualIssuer = "GitHub"
        viewModel.manualSecret = "mzxw 6ytb oi"

        viewModel.addManualEntry()

        #expect(viewModel.phase == .finished(added: 1, skipped: 0))
        #expect(store.accounts.first?.secret == Data("foobar".utf8))
    }

    @Test func rejectsASetupKeyOutsideTheBase32Alphabet() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)
        viewModel.manualIssuer = "GitHub"
        viewModel.manualSecret = "1111"

        viewModel.addManualEntry()

        #expect(viewModel.errorMessage != nil)
        #expect(store.accounts.isEmpty)
    }
}
