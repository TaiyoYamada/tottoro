//
//  AccountListUITests.swift
//  TottoroUITests
//
//  Created by 山田大陽 on 2026/10/18.
//

#if os(iOS)
import XCTest

final class AccountListUITests: XCTestCase {
    @MainActor
    func testCopiesTheCodeOfTheSelectedAccount() {
        let app = XCUIApplication.launchForUITesting()

        // コードの上の文字は、それぞれがコピーのボタンとして読み上げられる
        app.buttons["Tap to Copy"].tap()

        XCTAssertTrue(app.buttons["Copied"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testShowsTheCodeOfTheTappedAccount() {
        let app = XCUIApplication.launchForUITesting()

        app.buttons["Bank"].tap()

        XCTAssertTrue(app.buttons["1234-5678"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testDeletesAnAccountAfterConfirming() {
        let app = XCUIApplication.launchForUITesting()

        app.buttons["Chat"].press(forDuration: 1)
        app.buttons["Delete"].tap()
        app.buttons["Delete"].tap()

        XCTAssertTrue(app.buttons["Chat"].waitForNonExistence(timeout: 2))
    }
}
#endif
