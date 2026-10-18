//
//  QRCodeImageReader.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import CoreGraphics
import Foundation
import Vision

/// 画像の中の QR コードを、すべて文字列にして返す。
enum QRCodeImageReader {
    static func payloads(inImageData data: Data) async throws -> [String] {
        try await request().perform(on: data, orientation: nil).compactMap(\.payloadString)
    }

    static func payloads(in image: CGImage) async throws -> [String] {
        try await request().perform(on: image, orientation: nil).compactMap(\.payloadString)
    }

    private static func request() -> DetectBarcodesRequest {
        var request = DetectBarcodesRequest()
        request.symbologies = [.qr]
        return request
    }
}
