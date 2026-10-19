//
//  MenuBarRow.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/18.
//

#if os(macOS)
import SwiftUI
import TottoroCore

struct MenuBarRow: View {
    let account: Account
    let code: String
    let secondsRemaining: TimeInterval
    let isCopied: Bool
    let onCopy: () -> Void

    @State private var isHovering = false
    /// メニューバーではクリックでコピーするだけなので、隠したままでもコピーできる
    @AppStorage(SettingsKey.hidesCodes) private var hidesCodes = false

    var body: some View {
        Button(action: onCopy) {
            HStack(spacing: Spacing.small) {
                AccountAvatar(account: account, size: .small)
                VStack(alignment: .leading) {
                    Text(account.displayName)
                        .lineLimit(1)
                    if !account.name.isEmpty, account.name != account.displayName {
                        Text(account.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if isCopied {
                    Label("Copied", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.green)
                }
                OneTimeCodeText(code: code, font: Typography.rowCode, isHidden: hidesCodes)
                CountdownRing(secondsRemaining: secondsRemaining, period: account.period, lineWidth: 2)
                    .frame(width: 22, height: 22)
            }
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .contentShape(.rect)
            .background(isHovering ? Color.primary.opacity(0.08) : .clear, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.xSmall)
        .onHover { isHovering = $0 }
        .accessibilityHint(Text("Copies the code"))
    }
}
#endif
