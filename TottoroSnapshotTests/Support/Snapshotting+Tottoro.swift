//
//  Snapshotting+Tottoro.swift
//  TottoroSnapshotTests
//
//  Created by 山田大陽 on 2026/10/18.
//

import SnapshotTesting
import SwiftUI
import UIKit

extension Snapshotting where Value: SwiftUI.View, Format == UIImage {
    /// 画面全体を、決まった iPhone の大きさで撮る。
    static func screen(_ style: UIUserInterfaceStyle) -> Snapshotting {
        .image(
            perceptualPrecision: perceptualPrecision,
            layout: .device(config: .iPhone13Pro),
            traits: UITraitCollection(userInterfaceStyle: style),
        )
    }

    /// 部品を、中身に合った大きさで撮る。
    static func component(_ style: UIUserInterfaceStyle) -> Snapshotting {
        .image(
            perceptualPrecision: perceptualPrecision,
            layout: .sizeThatFits,
            traits: UITraitCollection(userInterfaceStyle: style),
        )
    }

    /// 文字のにじみなど、Mac の GPU の違いで出る目に見えない差を許す
    private static var perceptualPrecision: Float {
        0.98
    }
}

extension UIUserInterfaceStyle {
    var snapshotName: String {
        self == .dark ? "dark" : "light"
    }
}
