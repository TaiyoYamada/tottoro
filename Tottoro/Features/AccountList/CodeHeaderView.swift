//
//  CodeHeaderView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

import TottoroCore
import SwiftUI

/// 選んだアカウントの色を背景に、大きなコードと残り時間を出す。タップでコピーする。
struct CodeHeaderView: View {
    let account: Account
    let viewModel: AccountListViewModel

    var body: some View {
        // 円が滑らかに減るよう、1 秒ごとではなく画面の描き直しに合わせて更新する
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
            let code = viewModel.code(for: account, at: context.date)
            VStack(spacing: Spacing.medium) {
                VStack(spacing: Spacing.xSmall) {
                    Text(account.displayName)
                        .font(Typography.headerIssuer)
                    if !account.name.isEmpty, account.name != account.displayName {
                        Text(account.name)
                            .font(Typography.headerName)
                            .opacity(0.8)
                    }
                }
                OneTimeCodeText(code: code, font: Typography.headerCode)
                    .animation(.snappy, value: code)
                HStack(spacing: Spacing.small) {
                    CountdownRing(
                        secondsRemaining: viewModel.secondsRemaining(for: account, at: context.date),
                        period: account.period
                    )
                    .frame(width: 32, height: 32)
                    Text(viewModel.copiedAccountID == account.id ? "コピーしました" : "タップしてコピー")
                        .font(Typography.headerName)
                        .contentTransition(.opacity)
                }
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xLarge)
        .background(account.color.color)
        .animation(.smooth, value: account.id)
        .animation(.default, value: viewModel.copiedAccountID)
        .contentShape(.rect)
        .onTapGesture {
            Task { await viewModel.copyCode(of: account) }
        }
        .sensoryFeedback(.success, trigger: viewModel.copiedAccountID) { _, new in new != nil }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(Text("コードをコピーします"))
    }
}
