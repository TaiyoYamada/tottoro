//
//  AddResult.swift
//  Tottoro
//
//  Created by 山田大陽 on 2026/10/19.
//

/// アカウントを足した結果。QR コードからでも、他のアプリからの取り込みでも、この形で出す。
struct AddResult: Equatable {
    let added: Int
    /// 同じコードを出すアカウントがもうあったので、足さなかった件数。
    let alreadyAdded: Int
    /// HOTP など、Tottoro が扱えないので足さなかった件数。
    let unsupported: Int
}
