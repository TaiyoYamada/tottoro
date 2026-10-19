//
//  EncryptedExportTests.swift
//  TottoroCoreTests
//
//  Created by 山田大陽 on 2026/10/19.
//

import CryptoExtras
import CryptoKit
import Foundation
import Testing
@testable import TottoroCore

/// 暗号化した書き出しを、各アプリと同じ手順でここで作り、Tottoro が開けるかを確かめる。
/// 手順が実物と合っていることは、各アプリのリポジトリの見本のファイルで一度確かめている。
struct EncryptedExportTests {
    private let services = """
    [{"name": "Example", "secret": "MZXW6YTBOI", "otp": {"account": "you", "tokenType": "TOTP"}}]
    """
    private let aegisDatabase = """
    {"version": 3, "entries": [{"type": "totp", "uuid": "1", "name": "you", "issuer": "Example",
     "info": {"secret": "MZXW6YTBOI", "algo": "SHA1", "digits": 6, "period": 30}}]}
    """

    @Test func `opens an encrypted 2FAS backup with the right password`() throws {
        let file = try twoFASBackup(password: "correct horse")

        let imported = try ExportFileImporter.importAccounts(from: file, password: "correct horse")

        #expect(imported.accounts.map(\.issuer) == ["Example"])
    }

    @Test func `asks for the password of an encrypted 2FAS backup`() throws {
        let file = try twoFASBackup(password: "correct horse")

        #expect(throws: ExportFileImporter.ImportError.passwordRequired) {
            try ExportFileImporter.importAccounts(from: file, password: nil)
        }
        #expect(throws: ExportFileImporter.ImportError.wrongPassword) {
            try ExportFileImporter.importAccounts(from: file, password: "wrong")
        }
    }

    @Test func `opens an encrypted Aegis vault with the right password`() throws {
        let file = try aegisVault(password: "correct horse", cost: 1024)

        let imported = try ExportFileImporter.importAccounts(from: file, password: "correct horse")

        #expect(imported.accounts.map(\.issuer) == ["Example"])
    }

    @Test func `asks for the password of an encrypted Aegis vault`() throws {
        let file = try aegisVault(password: "correct horse", cost: 1024)

        #expect(throws: ExportFileImporter.ImportError.passwordRequired) {
            try ExportFileImporter.importAccounts(from: file, password: nil)
        }
        #expect(throws: ExportFileImporter.ImportError.wrongPassword) {
            try ExportFileImporter.importAccounts(from: file, password: "wrong")
        }
    }

    /// 巨大な scrypt の値を書いたファイルで、メモリを使い尽くさない。
    @Test(arguments: [1 << 30, 1 << 62])
    func `refuses an Aegis vault whose scrypt parameters would use too much memory`(declaredCost: Int) throws {
        let file = try aegisVault(password: "correct horse", cost: 1024, declaredCost: declaredCost)

        #expect(throws: ExportFileImporter.ImportError.invalidFile) {
            try ExportFileImporter.importAccounts(from: file, password: "correct horse")
        }
    }

    /// 2FAS は「暗号文と認証タグ:salt:IV」を base64 でつなぐ。
    private func twoFASBackup(password: String) throws -> Data {
        let salt = Data((0 ..< 32).map { UInt8($0) })
        let nonce = AES.GCM.Nonce()
        let key = try KDF.Insecure.PBKDF2.deriveKey(
            from: Data(password.utf8),
            salt: salt,
            using: .sha256,
            outputByteCount: 32,
            unsafeUncheckedRounds: 10000,
        )
        let box = try AES.GCM.seal(Data(services.utf8), using: key, nonce: nonce)
        let encrypted = [box.ciphertext + box.tag, salt, Data(nonce)]
            .map { $0.base64EncodedString() }
            .joined(separator: ":")
        let file: [String: Any] = ["schemaVersion": 4, "services": [], "groups": [], "servicesEncrypted": encrypted]
        return try JSONSerialization.data(withJSONObject: file)
    }

    /// Aegis は、パスワードから scrypt で作った鍵でマスターキーを包み、マスターキーで中身を包む。
    private func aegisVault(password: String, cost: Int, declaredCost: Int? = nil) throws -> Data {
        let vaultKey = SymmetricKey(size: .bits256)
        let salt = Data((0 ..< 32).map { UInt8($0) })
        let keyEncryptionKey = try KDF.Scrypt.deriveKey(
            from: Data(password.utf8),
            salt: salt,
            outputByteCount: 32,
            rounds: cost,
            blockSize: 8,
            parallelism: 1,
        )
        let wrappedKey = try AES.GCM.seal(vaultKey.withUnsafeBytes { Data($0) }, using: keyEncryptionKey)
        let database = try AES.GCM.seal(Data(aegisDatabase.utf8), using: vaultKey)
        let file: [String: Any] = [
            "version": 1,
            "header": [
                "slots": [[
                    "type": 1,
                    "uuid": "1",
                    "key": hex(wrappedKey.ciphertext),
                    "key_params": ["nonce": hex(Data(wrappedKey.nonce)), "tag": hex(wrappedKey.tag)],
                    "n": declaredCost ?? cost,
                    "r": 8,
                    "p": 1,
                    "salt": hex(salt),
                ]],
                "params": ["nonce": hex(Data(database.nonce)), "tag": hex(database.tag)],
            ],
            "db": database.ciphertext.base64EncodedString(),
        ]
        return try JSONSerialization.data(withJSONObject: file)
    }

    private func hex(_ data: Data) -> String {
        data.map { String(format: "%02x", $0) }.joined()
    }
}
