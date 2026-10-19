//
//  AegisExport.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import CryptoExtras
import CryptoKit
import Foundation

/// Aegis Authenticator の書き出し。暗号化したものは、パスワードから scrypt で作った鍵で
/// 本当の鍵（マスターキー）を開き、その鍵で中身を開く。
enum AegisExport {
    private struct File: Decodable {
        let version: Int
        let header: Header
    }

    private struct Header: Decodable {
        let slots: [AegisSlot]?
        let params: AegisCipherParams?
    }

    /// 暗号化していない書き出しでは、db がそのまま JSON で入っている。
    private struct PlainFile: Decodable {
        let db: Database // swiftlint:disable:this identifier_name
    }

    private struct EncryptedFile: Decodable {
        let db: String // swiftlint:disable:this identifier_name
    }

    struct Database: Decodable {
        let entries: [Entry]
    }

    struct Entry: Decodable {
        let type: String
        let name: String
        let issuer: String
        let info: Info
    }

    struct Info: Decodable {
        let secret: String
        let algo: String
        let digits: Int
        let period: Int?
    }

    /// パスワードのスロット。生体認証のスロットは、その端末の外では開けない
    private static let passwordSlotType = 1

    /// 悪意のあるファイルが巨大な値を書いて、scrypt にメモリを使い尽くさせるのを防ぐ。
    /// Aegis の既定は n = 32768、r = 8、p = 1 で、これは 32 MB ほど使う
    private static let maximumScryptMemory = 256 * 1024 * 1024

    static func importAccounts(
        from data: Data,
        password: String?,
    ) throws(ExportFileImporter.ImportError) -> ImportedAccounts {
        let file = try decode(File.self, from: data)
        guard file.version == 1 else { throw .unsupportedFile }

        let database: Database
        if let slots = file.header.slots, let params = file.header.params {
            guard let password else { throw .passwordRequired }
            let vaultKey = try vaultKey(from: slots, password: password)
            let encrypted = try decode(EncryptedFile.self, from: data)
            guard let sealed = Data(base64Encoded: encrypted.db) else { throw .invalidFile }
            let plaintext = try open(sealed, params: params, using: vaultKey, failure: .invalidFile)
            database = try decode(Database.self, from: plaintext)
        } else {
            database = try decode(PlainFile.self, from: data).db
        }

        var accounts: [Account] = []
        for entry in database.entries {
            guard entry.type == "totp",
                  let period = entry.info.period,
                  let account = ExportFileImporter.account(
                      issuer: entry.issuer,
                      name: entry.name,
                      base32Secret: entry.info.secret,
                      algorithm: entry.info.algo,
                      digits: entry.info.digits,
                      period: period,
                  )
            else {
                continue
            }
            accounts.append(account)
        }
        return ImportedAccounts(accounts: accounts, skippedCount: database.entries.count - accounts.count)
    }

    /// パスワードのスロットを順に試し、開けたものから中身の鍵（Aegis の言うマスターキー）を取り出す。
    private static func vaultKey(
        from slots: [AegisSlot],
        password: String,
    ) throws(ExportFileImporter.ImportError) -> SymmetricKey {
        let passwordSlots = slots.filter { $0.type == passwordSlotType }
        guard !passwordSlots.isEmpty else { throw .unsupportedFile }
        for slot in passwordSlots {
            guard let cost = slot.cost, let blockSize = slot.blockSize, let parallelism = slot.parallelism,
                  let salt = slot.salt.flatMap(Data.init(hex:)), let sealedKey = Data(hex: slot.key),
                  // 掛け算が Int を溢れないよう、先にそれぞれの値を上限で切る
                  (2 ... 1 << 20).contains(cost), cost.nonzeroBitCount == 1,
                  (1 ... 64).contains(blockSize), (1 ... 64).contains(parallelism),
                  128 * blockSize * cost * parallelism <= maximumScryptMemory
            else {
                throw .invalidFile
            }
            let keyEncryptionKey: SymmetricKey
            do {
                keyEncryptionKey = try KDF.Scrypt.deriveKey(
                    from: Data(password.utf8),
                    salt: salt,
                    outputByteCount: 32,
                    rounds: cost,
                    blockSize: blockSize,
                    parallelism: parallelism,
                )
            } catch {
                throw .invalidFile
            }
            // スロットの認証タグが合わなければ、このスロットのパスワードではない
            let key = try? open(sealedKey, params: slot.keyParams, using: keyEncryptionKey, failure: .wrongPassword)
            if let key {
                return SymmetricKey(data: key)
            }
        }
        throw .wrongPassword
    }

    private static func open(
        _ ciphertext: Data,
        params: AegisCipherParams,
        using key: SymmetricKey,
        failure: ExportFileImporter.ImportError,
    ) throws(ExportFileImporter.ImportError) -> Data {
        guard let nonce = Data(hex: params.nonce), let tag = Data(hex: params.tag) else { throw .invalidFile }
        do {
            let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: nonce), ciphertext: ciphertext, tag: tag)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw failure
        }
    }

    private static func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
    ) throws(ExportFileImporter.ImportError) -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw .invalidFile
        }
    }
}

/// Aegis のスロット。scrypt の値は、ファイルでは n、r、p という名前で入っている。
private struct AegisSlot: Decodable {
    let type: Int
    let key: String
    let keyParams: AegisCipherParams
    let cost: Int?
    let blockSize: Int?
    let parallelism: Int?
    let salt: String?

    enum CodingKeys: String, CodingKey {
        case type, key, salt
        case keyParams = "key_params"
        case cost = "n"
        case blockSize = "r"
        case parallelism = "p"
    }
}

private struct AegisCipherParams: Decodable {
    let nonce: String
    let tag: String
}
