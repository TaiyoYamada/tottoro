//
//  CSVTable.swift
//  TottoroCore
//
//  Created by 山田大陽 on 2026/10/19.
//

/// RFC 4180 の CSV を行と列に分ける。TabularData は列の数がそろわない行で失敗するが、
/// Bitwarden の Android 版は見出しより列の多い行を書き出すので、自前で読む。
struct CSVTable {
    let header: [String]
    let rows: [[String]]

    init?(_ text: String) {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var isQuoted = false
        var iterator = text.makeIterator()
        var pending = iterator.next()
        while let character = pending {
            pending = iterator.next()
            if isQuoted {
                if character == "\"" {
                    // 引用符の中の "" は、" 1 文字を表す
                    if pending == "\"" {
                        field.append("\"")
                        pending = iterator.next()
                    } else {
                        isQuoted = false
                    }
                } else {
                    field.append(character)
                }
                continue
            }
            switch character {
            case "\"":
                isQuoted = true
            case ",":
                record.append(field)
                field = ""
            case "\n", "\r\n", "\r":
                record.append(field)
                records.append(record)
                record = []
                field = ""
            default:
                field.append(character)
            }
        }
        if !field.isEmpty || !record.isEmpty {
            record.append(field)
            records.append(record)
        }
        // 空の行は飛ばす。Bitwarden の iOS 版は行の間に空の行を挟む
        records.removeAll { $0.allSatisfy(\.isEmpty) }
        guard let header = records.first else { return nil }
        self.header = header.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
        rows = Array(records.dropFirst())
    }

    /// names のどれかと同じ見出しの列の番号。見出しは大文字と小文字を区別しない。
    func column(named names: [String]) -> Int? {
        header.firstIndex { names.contains($0) }
    }
}
