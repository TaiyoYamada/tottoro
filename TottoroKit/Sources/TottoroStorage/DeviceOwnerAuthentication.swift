//
//  DeviceOwnerAuthentication.swift
//  TottoroStorage
//
//  Created by 山田大陽 on 2026/10/19.
//

import LocalAuthentication

/// Face ID / Touch ID か、端末のパスコードで本人を確かめる。アプリと自動入力の拡張の両方が使う。
public enum DeviceOwnerAuthentication {
    public enum Failure: Error, Equatable, Sendable {
        /// 本人や OS が確認を取りやめた。
        case canceled
        /// 本人だと確かめられなかった。
        case failed
        /// 端末にパスコードがない。パスコードがなければ端末の中身は誰でも見られるので、開かせない。
        case passcodeNotSet
    }

    /// 生体認証に失敗したときに端末のパスコードで解除できるよう、deviceOwnerAuthentication を使う。
    public static func authenticate(reason: String) async throws(Failure) {
        let context = LAContext()
        var error: NSError?
        // パスコードのない端末では評価が始まらないので、先に理由を確かめる
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw failure(for: error)
        }
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            throw failure(for: error)
        }
    }

    static func failure(for error: any Error?) -> Failure {
        switch (error as? LAError)?.code {
        case .passcodeNotSet:
            .passcodeNotSet
        case .userCancel, .appCancel, .systemCancel:
            .canceled
        default:
            .failed
        }
    }
}
