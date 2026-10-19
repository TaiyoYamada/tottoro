//
//  AppStoreScreenshots.swift
//  TottoroUITests
//
//  Created by 山田大陽 on 2026/10/18.
//

import XCTest

/// App Store に載せるスクリーンショットを撮る。Screenshots のテストプランが英語と日本語で 1 回ずつ流す。
/// 画像は scripts/screenshots.sh が結果から取り出す。
final class AppStoreScreenshots: XCTestCase {
    @MainActor
    func testTakeScreenshots() {
        let app = XCUIApplication.launchForUITesting(language: nil)
        XCTAssertTrue(app.buttons["Mail"].waitForExistence(timeout: 5))
        attachScreenshot(of: app, named: "1-codes")

        #if os(iOS)
        app.buttons["Bank"].tap()
        attachScreenshot(of: app, named: "2-another-account")

        app.buttons["addAccount"].tap()
        XCTAssertTrue(app.navigationBars.element.waitForExistence(timeout: 2))
        attachScreenshot(of: app, named: "3-add-account")
        #endif
    }

    @MainActor
    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        #if os(iOS)
        let screenshot = app.screenshot()
        #else
        let screenshot = app.windows.firstMatch.screenshot()
        #endif
        let attachment = XCTAttachment(screenshot: screenshot)
        let language = Locale.current.language.languageCode?.identifier ?? "unknown"
        attachment.name = "\(language)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
