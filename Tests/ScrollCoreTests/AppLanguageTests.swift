import XCTest
@testable import ScrollCore

final class AppLanguageTests: XCTestCase {
    func testSavedChoiceOverridesSystemLanguage() {
        XCTAssertEqual(AppLanguage.resolve(savedValue: "en", preferredLanguages: ["zh-Hans-CN"]), .english)
        XCTAssertEqual(AppLanguage.resolve(savedValue: "zh-Hans", preferredLanguages: ["en-US"]), .simplifiedChinese)
    }

    func testSystemLanguageAndInvalidPreferenceFallback() {
        XCTAssertEqual(AppLanguage.resolve(savedValue: nil, preferredLanguages: ["zh-CN"]), .simplifiedChinese)
        XCTAssertEqual(AppLanguage.resolve(savedValue: "invalid", preferredLanguages: ["fr-FR", "en-US", "zh-CN"]), .english)
        XCTAssertEqual(AppLanguage.resolve(savedValue: nil, preferredLanguages: ["fr-FR"]), .english)
    }

    func testLanguageChoiceSurvivesReloadAndCanSwitchBack() {
        let suite = "SplitScroll.LanguageTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LanguagePreferences(defaults: defaults)
        store.save(.simplifiedChinese)
        let reloaded = LanguagePreferences(defaults: defaults)
        XCTAssertEqual(reloaded.load(preferredLanguages: ["en-US"]), .simplifiedChinese)
        reloaded.save(.english)
        XCTAssertEqual(store.load(preferredLanguages: ["zh-CN"]), .english)
    }

    func testControlsAndStatusUseSelectedLanguageAndKeepDeviceNames() {
        XCTAssertEqual(AppLanguage.simplifiedChinese.text("Continue"), "继续")
        XCTAssertEqual(AppLanguage.simplifiedChinese.text("Accessibility permission needed"), "需要辅助功能权限")
        XCTAssertEqual(AppLanguage.english.text("Continue"), "Continue")
        XCTAssertEqual(AppLanguage.simplifiedChinese.text("Logitech MX Master"), "Logitech MX Master")
    }
}
