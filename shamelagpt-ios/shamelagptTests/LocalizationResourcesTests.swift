//
//  LocalizationResourcesTests.swift
//  shamelagptTests
//
//  Ensures required localization keys exist for English and Arabic and contain RTL content where expected.
//

import XCTest
@testable import ShamelaGPT

final class LocalizationResourcesTests: XCTestCase {

    func testRequiredKeysLocalizedInEnglishAndArabic() throws {
        let bundle = Bundle(for: SessionManager.self)
        let englishBundle = try XCTUnwrap(Bundle(path: try XCTUnwrap(bundle.path(forResource: "en", ofType: "lproj"))))
        let arabicBundle = try XCTUnwrap(Bundle(path: try XCTUnwrap(bundle.path(forResource: "ar", ofType: "lproj"))))

        let criticalKeys = [
            LocalizationKeys.chat,
            LocalizationKeys.history,
            LocalizationKeys.settings,
            LocalizationKeys.networkNoConnection,
            LocalizationKeys.networkTooManyRequests,
            LocalizationKeys.welcomeTitle,
            LocalizationKeys.share
        ]

        for key in criticalKeys {
            let english = englishBundle.localizedString(forKey: key, value: nil, table: "Localizable")
            let arabic = arabicBundle.localizedString(forKey: key, value: nil, table: "Localizable")

            XCTAssertFalse(english.isEmpty, "English translation missing for \(key)")
            XCTAssertFalse(arabic.isEmpty, "Arabic translation missing for \(key)")
            XCTAssertNotEqual(english, key, "English entry should not fall back to key for \(key)")
            XCTAssertNotEqual(arabic, key, "Arabic entry should not fall back to key for \(key)")
        }
    }

    func testArabicLocalizationsContainRTLScript() throws {
        let bundle = Bundle(for: SessionManager.self)
        let arabicBundle = try XCTUnwrap(Bundle(path: try XCTUnwrap(bundle.path(forResource: "ar", ofType: "lproj"))))

        let rtlSensitiveKeys = [
            LocalizationKeys.welcomeIntro,
            LocalizationKeys.historyLockedMessage,
            LocalizationKeys.networkAccessForbidden
        ]

        for key in rtlSensitiveKeys {
            let arabic = arabicBundle.localizedString(forKey: key, value: nil, table: "Localizable")
            XCTAssertTrue(arabic.range(of: "\\p{Arabic}", options: .regularExpression) != nil,
                          "Arabic translation for \(key) should include RTL script to guard against missing entries")
        }
    }
}
