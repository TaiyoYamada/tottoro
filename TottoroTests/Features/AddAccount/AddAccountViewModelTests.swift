//
//  AddAccountViewModelTests.swift
//  TottoroTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import Testing
@testable import Tottoro
import TottoroCore

struct AddAccountViewModelTests {
    @Test func `adds an account from an OTP auth QR code`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)

        viewModel.handleScannedPayloads(["otpauth://totp/GitHub:octocat?secret=MZXW6YTBOI&issuer=GitHub"])

        #expect(viewModel.phase == .finished(AddResult(added: 1, alreadyAdded: 0, unsupported: 0)))
        #expect(store.accounts.map(\.issuer) == ["GitHub"])
    }

    @Test func `ignores QR codes that are not for two factor authentication`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)

        viewModel.handleScannedPayloads(["https://example.com", "otpauth://totp/GitHub:octocat?secret=MZXW6YTBOI"])

        #expect(viewModel.phase == .finished(AddResult(added: 1, alreadyAdded: 0, unsupported: 0)))
    }

    @Test func `shows an error when no account can be read`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)

        viewModel.handleScannedPayloads(["otpauth://hotp/a?secret=MZXW6YTBOI&counter=1"])

        #expect(viewModel.phase == .choosing)
        #expect(viewModel.errorMessage != nil)
        #expect(store.accounts.isEmpty)
    }

    @Test func `adds A manual entry with spaces in the setup key`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)
        viewModel.manualIssuer = "GitHub"
        viewModel.manualSecret = "mzxw 6ytb oi"

        viewModel.addManualEntry()

        #expect(viewModel.phase == .finished(AddResult(added: 1, alreadyAdded: 0, unsupported: 0)))
        #expect(store.accounts.first?.secret == Data("foobar".utf8))
    }

    @Test func `rejects A setup key outside the base 32 alphabet`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)
        viewModel.manualIssuer = "GitHub"
        viewModel.manualSecret = "1111"

        viewModel.addManualEntry()

        #expect(viewModel.errorMessage != nil)
        #expect(store.accounts.isEmpty)
    }

    @Test func `does not add the same account twice`() {
        let store = AccountStore(repository: InMemoryAccountRepository())
        let viewModel = AddAccountViewModel(store: store)
        let uri = "otpauth://totp/GitHub:octocat?secret=MZXW6YTBOI&issuer=GitHub"

        viewModel.handleScannedPayloads([uri])
        viewModel.handleScannedPayloads([uri])

        #expect(viewModel.phase == .finished(AddResult(added: 0, alreadyAdded: 1, unsupported: 0)))
        #expect(store.accounts.count == 1)
    }
}
