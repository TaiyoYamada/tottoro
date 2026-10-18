//
//  ScreenQRReader.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

#if os(macOS)
import ScreenCaptureKit

/// Mac のブラウザに表示した二要素認証の QR コードを、iPhone を使わずに読み取る。
/// 初回は OS が画面収録の許可を求める。
enum ScreenQRReader {
    static func payloads() async throws -> [String] {
        let content = try await SCShareableContent.current
        var payloads: [String] = []
        for display in content.displays {
            let image = try await SCScreenshotManager.captureImage(in: display.frame)
            payloads += try await QRCodeImageReader.payloads(in: image)
        }
        return payloads
    }
}
#endif
