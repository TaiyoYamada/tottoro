//
//  IconPickerView.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

import SwiftUI
import TottoroCore

/// アカウントの丸に載せるものを選ぶ。自動、頭文字、同梱したサービスのロゴのどれか。
struct IconPickerView: View {
    @Binding var selection: AccountIcon?
    @State private var searchText = ""

    var body: some View {
        List {
            Section {
                row(selected: selection == nil, action: { selection = nil }, label: {
                    Label("Automatic", systemImage: "wand.and.sparkles")
                })
                row(selected: selection == .initial, action: { selection = .initial }, label: {
                    Label("Initial Letter", systemImage: "textformat")
                })
            } footer: {
                Text("Automatic picks a logo from the domain or the issuer.")
            }
            Section("Services") {
                ForEach(entries) { entry in
                    let icon = AccountIcon.service(entry.slug)
                    row(selected: selection == icon, action: { selection = icon }, label: {
                        Label {
                            Text(verbatim: entry.title)
                        } icon: {
                            Image(ServiceIcons.imageName(for: entry))
                                .resizable()
                                .scaledToFit()
                        }
                    })
                }
            }
        }
        .navigationTitle("Icon")
        .searchable(text: $searchText)
    }

    private var entries: [ServiceIconCatalog.Entry] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return ServiceIcons.catalog.entries }
        return ServiceIcons.catalog.entries.filter { entry in
            entry.names.contains { $0.localizedStandardContains(query) }
        }
    }

    private func row(selected: Bool, action: @escaping () -> Void, @ViewBuilder label: () -> some View) -> some View {
        Button(action: action) {
            HStack {
                label()
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
