//
//  QRScannerView.swift
//  Rokketa
//
//  Created by 山田大陽 on 2026/10/18.
//

#if os(iOS)
import SwiftUI
import VisionKit

/// VisionKit のカメラ画面を SwiftUI で使えるようにしたもの。最初に読めた QR コードを 1 回だけ返す。
struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onFailure: (Error) -> Void

    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    // Apple の案内では、カメラ画面を表示してから読み取りを始める。make の時点ではまだ表示されていない
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        guard !uiViewController.isScanning, !context.coordinator.didScan else { return }
        do {
            try uiViewController.startScanning()
        } catch {
            // 画面の更新中に状態を変えると SwiftUI が警告を出すので、更新が終わってから知らせる
            Task { onFailure(error) }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private(set) var didScan = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            guard !didScan else { return }
            for item in addedItems {
                guard case .barcode(let barcode) = item, let payload = barcode.payloadStringValue else { continue }
                didScan = true
                dataScanner.stopScanning()
                onScan(payload)
                return
            }
        }
    }
}
#endif
