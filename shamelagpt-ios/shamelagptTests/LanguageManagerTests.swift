//
//  LanguageManagerTests.swift
//  shamelagptTests
//
//  Created by Ameed Khalid on 05/11/2025.
//

import XCTest
@testable import ShamelaGPT

final class LanguageManagerTests: XCTestCase {

    var languageManager: LanguageManager!

    override func setUpWithError() throws {
        languageManager = LanguageManager.shared
        // Reset to default
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
        languageManager = nil
    }

    func testDefaultLanguageIsEnglish() throws {
        // Given - fresh install
        UserDefaults.standard.removeObject(forKey: "selectedLanguage")

        // When
        let language = LanguageManager.shared.currentLanguage

        // Then
        XCTAssertEqual(language, .english)
    }

    func testSetLanguageToArabic() throws {
        // When
        languageManager.setLanguage(.arabic)

        // Then
        XCTAssertEqual(languageManager.currentLanguage, .arabic)
    }

    func testLanguagePersistence() throws {
        // Given
        languageManager.setLanguage(.arabic)

        // When - create new instance
        let newManager = LanguageManager.shared

        // Then - should load saved language
        XCTAssertEqual(newManager.currentLanguage, .arabic)
    }

    func testLanguageDisplayNames() throws {
        // Then
        XCTAssertEqual(Language.english.displayName, "English")
        XCTAssertEqual(Language.arabic.displayName, "العربية")
    }

    func testLanguageLocaleIdentifiers() throws {
        // Then
        XCTAssertEqual(Language.english.localeIdentifier, "en")
        XCTAssertEqual(Language.arabic.localeIdentifier, "ar")
    }

    func testSetLanguageToEnglish() throws {
        // Given - Start with Arabic
        languageManager.setLanguage(.arabic)

        // When
        languageManager.setLanguage(.english)

        // Then
        XCTAssertEqual(languageManager.currentLanguage, .english)
    }

    func testCurrentLanguageDisplayName() throws {
        // Given
        languageManager.setLanguage(.english)

        // When/Then
        XCTAssertEqual(languageManager.currentLanguageDisplayName, "English")

        // When
        languageManager.setLanguage(.arabic)

        // Then
        XCTAssertEqual(languageManager.currentLanguageDisplayName, "العربية")
    }

    func testLanguageChangeNotification() throws {
        // Given
        let expectation = XCTestExpectation(description: "Language change notification")

        let observer = NotificationCenter.default.addObserver(
            forName: .languageDidChange,
            object: nil,
            queue: nil
        ) { _ in
            expectation.fulfill()
        }

        // When
        languageManager.setLanguage(.arabic)

        // Then
        wait(for: [expectation], timeout: 1.0)

        NotificationCenter.default.removeObserver(observer)
    }

    func testLanguageRawValues() throws {
        // Then
        XCTAssertEqual(Language.english.rawValue, "en")
        XCTAssertEqual(Language.arabic.rawValue, "ar")
    }

    func testLanguageIdentifiable() throws {
        // Then
        XCTAssertEqual(Language.english.id, "en")
        XCTAssertEqual(Language.arabic.id, "ar")
    }

    func testLanguageAppStorageValue() throws {
        // When/Then
        XCTAssertEqual(Language.english.appStorageValue, "en")
        XCTAssertEqual(Language.arabic.appStorageValue, "ar")
    }

    func testLanguageAppStorageInit() throws {
        // When
        let english = Language(appStorageValue: "en")
        let arabic = Language(appStorageValue: "ar")
        let invalid = Language(appStorageValue: "invalid")

        // Then
        XCTAssertEqual(english, .english)
        XCTAssertEqual(arabic, .arabic)
        XCTAssertNil(invalid)
    }

    func testLanguageAllCases() throws {
        // When
        let allLanguages = Language.allCases

        // Then
        XCTAssertEqual(allLanguages.count, 2)
        XCTAssertTrue(allLanguages.contains(.english))
        XCTAssertTrue(allLanguages.contains(.arabic))
    }
}
