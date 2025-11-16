//
//  LanguageManagerTests.swift
//  shamelagptTests
//
//  Covers language selection, persistence, and localized display names.
//

import XCTest
@testable import ShamelaGPT

final class LanguageManagerTests: XCTestCase {

    private var languageManager: LanguageManager!
    private let selectedLanguageKey = "selectedLanguage"
    private let languages: [Language] = [.english, .arabic, .urdu]

    override func setUpWithError() throws {
        continueAfterFailure = false
        resetUserDefaults()
        languageManager = LanguageManager.shared
        languageManager.setLanguage(.english)
    }

    override func tearDownWithError() throws {
        resetUserDefaults()
        languageManager = nil
    }

    private func resetUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: selectedLanguageKey)
        defaults.removeObject(forKey: "AppleLanguages") // ensure clean locale state between tests
        defaults.synchronize()
    }

    // MARK: - Core behavior

    func testSetLanguageUpdatesStateAndPersists() throws {
        languageManager.setLanguage(.arabic)
        XCTAssertEqual(languageManager.currentLanguage, .arabic)
        XCTAssertEqual(UserDefaults.standard.string(forKey: selectedLanguageKey), "ar")
    }

    func testCurrentLanguageDisplayNameUsesLocalization() throws {
        languages.forEach { lang in
            languageManager.setLanguage(lang)
            XCTAssertEqual(languageManager.currentLanguageDisplayName, LocalizationKeys.currentLanguage.localized)
        }
    }

    func testLanguageChangeNotificationPosted() throws {
        let expectation = XCTestExpectation(description: "Language change notification")
        let observer = NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: nil
        ) { _ in expectation.fulfill() }

        languageManager.setLanguage(.urdu)
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }

    // MARK: - Language enum mapping

    func testLanguageMapping() throws {
        XCTAssertEqual(Language.english.displayName, "English")
        XCTAssertEqual(Language.arabic.displayName, "العربية")
        XCTAssertEqual(Language.urdu.displayName, "اردو")

        XCTAssertEqual(Language.english.localeIdentifier, "en")
        XCTAssertEqual(Language.arabic.localeIdentifier, "ar")
        XCTAssertEqual(Language.urdu.localeIdentifier, "ur_PK")

        XCTAssertEqual(Language.english.rawValue, "en")
        XCTAssertEqual(Language.arabic.rawValue, "ar")
        XCTAssertEqual(Language.urdu.rawValue, "ur")

        XCTAssertEqual(Language.english.appStorageValue, "en")
        XCTAssertEqual(Language.arabic.appStorageValue, "ar")
        XCTAssertEqual(Language.urdu.appStorageValue, "ur")
    }

    func testLanguageAppStorageInit() throws {
        XCTAssertEqual(Language(appStorageValue: "en"), .english)
        XCTAssertEqual(Language(appStorageValue: "ar"), .arabic)
        XCTAssertEqual(Language(appStorageValue: "ur"), .urdu)
        XCTAssertNil(Language(appStorageValue: "invalid"))
    }

    func testLanguageAllCases() throws {
        XCTAssertEqual(Language.allCases.count, 3)
        XCTAssertTrue(Language.allCases.contains(.english))
        XCTAssertTrue(Language.allCases.contains(.arabic))
        XCTAssertTrue(Language.allCases.contains(.urdu))
    }
}
