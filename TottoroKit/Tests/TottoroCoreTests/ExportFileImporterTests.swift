//
//  ExportFileImporterTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/19.
//

import Foundation
import Testing
@testable import TottoroCore

/// 各アプリの書き出しの形は、それぞれのアプリのソースコードで確かめた。テストのデータはここで作ったもの。
struct ExportFileImporterTests {
    @Test func `imports TOTP services from a 2FAS backup and skips the others`() throws {
        let json = """
        {"schemaVersion": 4, "appOrigin": "ios", "groups": [], "services": [
          {"name": "Example", "secret": "MZXW-6YTB-OI", "otp": {"account": "you", "issuer": "Example",
           "digits": 8, "period": 60, "algorithm": "SHA256", "tokenType": "TOTP"}},
          {"name": "Counter", "secret": "MZXW6YTBOI", "otp": {"tokenType": "HOTP", "counter": 1}},
          {"name": "Steam", "secret": "MZXW6YTBOI", "otp": {"tokenType": "STEAM", "digits": 5}}
        ]}
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(json.utf8), password: nil)

        #expect(imported.skippedCount == 2)
        let account = try #require(imported.accounts.first)
        #expect(account.issuer == "Example")
        #expect(account.name == "you")
        #expect(account.secret == Data("foobar".utf8))
        #expect(account.algorithm == .sha256)
        #expect(account.digits == 8)
        #expect(account.period == 60)
    }

    @Test func `uses the service name when a 2FAS backup has no issuer`() throws {
        let json = """
        {"schemaVersion": 1, "services": [{"name": "Example", "secret": "MZXW6YTBOI"}]}
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(json.utf8), password: nil)

        #expect(imported.accounts.map(\.issuer) == ["Example"])
        #expect(imported.accounts.first?.digits == 6)
    }

    @Test func `refuses a 2FAS backup from a newer version`() {
        let json = """
        {"schemaVersion": 5, "services": []}
        """

        #expect(throws: ExportFileImporter.ImportError.unsupportedFile) {
            try ExportFileImporter.importAccounts(from: Data(json.utf8), password: nil)
        }
    }

    @Test func `imports TOTP entries from a plain Aegis vault`() throws {
        let json = """
        {"version": 1, "header": {"slots": null, "params": null}, "db": {"version": 3, "entries": [
          {"type": "totp", "uuid": "1", "name": "you", "issuer": "Example",
           "info": {"secret": "MZXW6YTBOI", "algo": "SHA512", "digits": 7, "period": 20}},
          {"type": "hotp", "uuid": "2", "name": "you", "issuer": "Counter",
           "info": {"secret": "MZXW6YTBOI", "algo": "SHA1", "digits": 6, "counter": 3}},
          {"type": "steam", "uuid": "3", "name": "you", "issuer": "Steam",
           "info": {"secret": "MZXW6YTBOI", "algo": "SHA1", "digits": 5, "period": 30}}
        ]}}
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(json.utf8), password: nil)

        #expect(imported.skippedCount == 2)
        let account = try #require(imported.accounts.first)
        #expect(account.issuer == "Example")
        #expect(account.algorithm == .sha512)
        #expect(account.digits == 7)
        #expect(account.period == 20)
    }

    @Test func `reads every form of the TOTP field in a Bitwarden Authenticator export`() throws {
        let json = """
        {"encrypted": false, "items": [
          {"name": "Example", "type": 1,
           "login": {"totp": "otpauth://totp/Example:you?secret=MZXW6YTBOI&issuer=Example"}},
          {"name": "Bare", "type": 1, "login": {"totp": "MZXW6YTBOI", "username": "me"}},
          {"name": "Steam", "type": 1, "login": {"totp": "steam://MZXW6YTBOI"}},
          {"name": "Note", "type": 2}
        ]}
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(json.utf8), password: nil)

        #expect(imported.accounts.map(\.issuer) == ["Example", "Bare"])
        #expect(imported.accounts.map(\.name) == ["you", "me"])
        #expect(imported.skippedCount == 1)
    }

    @Test func `decodes HTML entities in labels written by Bitwarden Authenticator for Android`() throws {
        let json = """
        {"encrypted": false, "items": [
          {"name": "A&amp;B", "type": 1,
           "login": {"totp": "otpauth://totp/A%26amp%3BB:me%26amp%3Byou?secret=MZXW6YTBOI"}}
        ]}
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(json.utf8), password: nil)

        #expect(imported.accounts.first?.issuer == "A&B")
        #expect(imported.accounts.first?.name == "me&you")
    }

    @Test func `reads the CSV from Bitwarden Authenticator for iOS, with blank lines between rows`() throws {
        let csv = """
        folder,favorite,type,name,notes,fields,reprompt,login_uri,login_username,login_password,login_totp

        ,,1,Example,,,0,,you,,otpauth://totp/Example:you?secret=MZXW6YTBOI&issuer=Example

        ,,1,Steam,,,0,,you,,steam://MZXW6YTBOI
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(csv.utf8), password: nil)

        #expect(imported.accounts.map(\.issuer) == ["Example"])
        #expect(imported.skippedCount == 1)
    }

    @Test func `reads the CSV from Bitwarden Authenticator for Android, with rows longer than the header`() throws {
        let csv = """
        folder,favorite,type,name,login_uri,login_totp
        ,,1,Example,,otpauth://totp/Example:you?secret=MZXW6YTBOI&issuer=Example,Example,30,6
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(csv.utf8), password: nil)

        #expect(imported.accounts.map(\.issuer) == ["Example"])
    }

    @Test func `reads codes and domains from an Apple Passwords CSV and ignores rows without a code`() throws {
        // 引用符の中の , と "" が、列の区切りにならないことも確かめる
        let uri = "otpauth://totp/Example:you?secret=MZXW6YTBOI&issuer=Example"
        let csv = #"""
        Title,URL,Username,Password,Notes,OTPAuth
        "Example, Inc.",https://login.example.com/,you,secret,"a note, with ""quotes""",\#(uri)
        Other,https://other.example.com/,you,secret,,
        """#

        let imported = try ExportFileImporter.importAccounts(from: Data(csv.utf8), password: nil)

        #expect(imported.skippedCount == 0)
        let account = try #require(imported.accounts.first)
        #expect(imported.accounts.count == 1)
        #expect(account.issuer == "Example")
        #expect(account.domain == "login.example.com")
    }

    @Test func `reads a list of otpauth URLs and leaves out codes trashed in Ente Auth`() throws {
        let trashed = "%7B%22trashed%22%3Atrue%7D"
        let text = """
        otpauth://totp/Example:you?secret=MZXW6YTBOI&issuer=Example&algorithm=sha256
        otpauth://totp/Spaced Name:you?secret=MZXW6YTBOI
        otpauth://totp/Gone:you?secret=MZXW6YTBOI&codeDisplay=\(trashed)
        otpauth://hotp/Counter:you?secret=MZXW6YTBOI&counter=1
        """

        let imported = try ExportFileImporter.importAccounts(from: Data(text.utf8), password: nil)

        #expect(imported.accounts.map(\.issuer) == ["Example", "Spaced Name"])
        #expect(imported.accounts.first?.algorithm == .sha256)
        #expect(imported.skippedCount == 1)
    }

    @Test(arguments: [
        #"{"hello": "world"}"#,
        "just some text",
        "a,b,c\n1,2,3",
    ])
    func `refuses files from other apps`(text: String) {
        #expect(throws: ExportFileImporter.ImportError.unsupportedFile) {
            try ExportFileImporter.importAccounts(from: Data(text.utf8), password: nil)
        }
    }

    @Test func `refuses files too large to be an export`() {
        let data = Data(count: ExportFileImporter.maximumFileSize + 1)

        #expect(throws: ExportFileImporter.ImportError.unsupportedFile) {
            try ExportFileImporter.importAccounts(from: data, password: nil)
        }
    }
}
