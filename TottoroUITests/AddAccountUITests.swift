//
//  AddAccountUITests.swift
//  TottoroUITests
//
//  Created by 山田大陽 on 2026/10/18.
//

#if os(iOS)
import XCTest

final class AddAccountUITests: XCTestCase {
    @MainActor
    func testAddsAnAccountWithASetupKey() {
        let app = XCUIApplication.launchForUITesting()

        app.buttons["addAccount"].tap()
        app.buttons["Enter Manually"].tap()
        let issuer = app.textFields["Issuer (e.g. GitHub)"]
        issuer.tap()
        issuer.typeText("Example")
        let setupKey = app.textFields["Setup Key"]
        setupKey.tap()
        setupKey.typeText("MZXW6YTBOI")
        // 一覧の画面のツールバーにも「Add」があるので、フォームの中のボタンに絞る
        app.collectionViews.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts["Added 1 account"].waitForExistence(timeout: 2))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Example"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testShowsAnErrorForASetupKeyOutsideTheBase32Alphabet() {
        let app = XCUIApplication.launchForUITesting()

        app.buttons["addAccount"].tap()
        app.buttons["Enter Manually"].tap()
        let setupKey = app.textFields["Setup Key"]
        setupKey.tap()
        setupKey.typeText("1111")
        let issuer = app.textFields["Issuer (e.g. GitHub)"]
        issuer.tap()
        issuer.typeText("Example")
        app.collectionViews.buttons["Add"].tap()

        XCTAssertTrue(app.alerts["Couldn’t Add the Account"].waitForExistence(timeout: 2))
    }
}
#endif
