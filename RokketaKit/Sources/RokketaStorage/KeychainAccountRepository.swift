//
//  KeychainAccountRepository.swift
//  RokketaStorage
//
//  Created by 山田大陽 on 2026/10/18.
//

import Foundation
import RokketaCore
import Security

/// アカウント 1 件を、iCloud キーチェーンで同期する項目 1 つとして保存する。
/// 1 件ずつ分けているのは、別の端末で別のアカウントを同時に編集しても上書きし合わないようにするため。
public struct KeychainAccountRepository: AccountRepository, Sendable {
    public struct KeychainError: LocalizedError {
        public let status: OSStatus

        public var errorDescription: String? {
            SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        }
    }

    private static let service = "com.taiyo.rokketa.account"

    public init() {}

    public func loadAll() throws -> [Account] {
        var query = Self.baseQuery()
        query[kSecMatchLimit] = kSecMatchLimitAll
        query[kSecReturnData] = true

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            let items = result as? [Data] ?? []
            return try items.map { try JSONDecoder().decode(Account.self, from: $0) }
        case errSecItemNotFound:
            return []
        default:
            throw KeychainError(status: status)
        }
    }

    public func save(_ account: Account) throws {
        let data = try JSONEncoder().encode(account)
        var query = Self.baseQuery()
        query[kSecAttrAccount] = account.id.uuidString

        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData: data] as CFDictionary)
        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            query[kSecValueData] = data
            // 同期する項目には ThisDeviceOnly の付く値を使えない。その中で一番強いのが WhenUnlocked で、
            // アプリも自動入力の拡張も端末のロック解除中にしか読まないので、これで足りる
            query[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlocked
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError(status: addStatus) }
        default:
            throw KeychainError(status: updateStatus)
        }
    }

    public func delete(id: Account.ID) throws {
        var query = Self.baseQuery()
        query[kSecAttrAccount] = id.uuidString
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status: status) }
    }

    // kSecAttrAccessGroup は指定しない。指定しなければ entitlements の keychain-access-groups の
    // 先頭のグループが使われ、アプリと自動入力の拡張の両方がそこを読める。
    private static func baseQuery() -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrSynchronizable: true,
            // macOS で古いファイル型のキーチェーンではなく、iOS と同じ仕組みのキーチェーンを使う
            kSecUseDataProtectionKeychain: true,
        ]
    }
}
