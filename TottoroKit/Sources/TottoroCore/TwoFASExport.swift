//
//  TwoFASExport.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

import CryptoExtras
import CryptoKit
import Foundation

/// 2FAS Authenticator のバックアップ（.2fas）。暗号化したものは、services が空で servicesEncrypted に中身が入る。
enum TwoFASExport {
    private struct File: Decodable {
        let schemaVersion: Int
        let services: [Service]
        let servicesEncrypted: String?
    }

    private struct Service: Decodable {
        let name: String
        let secret: String
        let otp: OTP?
    }

    private struct OTP: Decodable {
        let account: String?
        let label: String?
        let issuer: String?
        let digits: Int?
        let period: Int?
        let algorithm: String?
        let tokenType: String?
    }

    /// 2FAS の鍵の導出は PBKDF2-HMAC-SHA256 を 10,000 回。今の推奨よりかなり少ないが、2FAS の書き出しを開くにはこれに合わせるしかない
    private static let rounds = 10000

    static func importAccounts(
        from data: Data,
        password: String?,
    ) throws(ExportFileImporter.ImportError) -> ImportedAccounts {
        let file: File
        do {
            file = try JSONDecoder().decode(File.self, from: data)
        } catch {
            throw .invalidFile
        }
        // 2FAS 自身も、知らない新しい版は読まない
        guard file.schemaVersion <= 4 else { throw .unsupportedFile }

        var services = file.services
        if let encrypted = file.servicesEncrypted {
            guard let password else { throw .passwordRequired }
            let plaintext = try decrypt(encrypted, password: password)
            do {
                services = try JSONDecoder().decode([Service].self, from: plaintext)
            } catch {
                throw .invalidFile
            }
        }

        var accounts: [Account] = []
        for service in services {
            // 種類を書かない古い版は、すべて TOTP
            guard (service.otp?.tokenType ?? "TOTP").uppercased() == "TOTP",
                  let account = ExportFileImporter.account(
                      issuer: service.otp?.issuer.flatMap { $0.isEmpty ? nil : $0 } ?? service.name,
                      name: service.otp?.account ?? service.otp?.label ?? "",
                      base32Secret: service.secret,
                      algorithm: service.otp?.algorithm ?? "SHA1",
                      digits: service.otp?.digits ?? 6,
                      period: service.otp?.period ?? 30,
                  )
            else {
                continue
            }
            accounts.append(account)
        }
        return ImportedAccounts(accounts: accounts, skippedCount: services.count - accounts.count)
    }

    /// 「暗号文と認証タグ:salt:IV」を、それぞれ base64 にして : でつないだもの。
    /// salt の長さは iOS 版と Android 版で違うので、決め打ちせずに読んだ長さを使う。
    private static func decrypt(_ encrypted: String, password: String) throws(ExportFileImporter.ImportError) -> Data {
        let parts = encrypted.split(separator: ":").map { Data(base64Encoded: String($0)) }
        guard parts.count == 3, let sealed = parts[0], let salt = parts[1], let nonce = parts[2],
              sealed.count > 16
        else {
            throw .invalidFile
        }
        do {
            let key = try KDF.Insecure.PBKDF2.deriveKey(
                from: Data(password.utf8),
                salt: salt,
                using: .sha256,
                outputByteCount: 32,
                unsafeUncheckedRounds: rounds,
            )
            let box = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: nonce),
                ciphertext: sealed.dropLast(16),
                tag: sealed.suffix(16),
            )
            return try openSealedBox(box, using: key)
        } catch let error as ExportFileImporter.ImportError {
            throw error
        } catch {
            throw .invalidFile
        }
    }

    /// 認証タグが合わないのは、パスワードが違うとき。2FAS も同じ判定をしている。
    private static func openSealedBox(
        _ box: AES.GCM.SealedBox,
        using key: SymmetricKey,
    ) throws(ExportFileImporter.ImportError) -> Data {
        do {
            return try AES.GCM.open(box, using: key)
        } catch {
            throw .wrongPassword
        }
    }
}
