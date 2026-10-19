//
//  CountdownRing.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import SwiftUI

/// コードが切り替わるまでの残り時間を、減っていく円で表す。
struct CountdownRing: View {
    let secondsRemaining: TimeInterval
    let period: Int
    var lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            Circle()
                .stroke(.tertiary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: secondsRemaining / TimeInterval(period))
                .stroke(.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(verbatim: "\(Int(secondsRemaining.rounded(.up)))")
                .font(Typography.countdown)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(Int(secondsRemaining.rounded(.up))) seconds left"))
    }
}
