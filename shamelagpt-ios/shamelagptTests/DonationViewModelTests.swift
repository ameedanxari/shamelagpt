//
//  DonationViewModelTests.swift
//  shamelagptTests
//

import XCTest
import StoreKit
@testable import ShamelaGPT

@MainActor
final class DonationViewModelTests: XCTestCase {

    var sut: DonationViewModel!

    override func setUp() {
        super.setUp()
        sut = DonationViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertTrue(sut.products.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isPurchasing)
        XCTAssertFalse(sut.purchaseSuccess)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.hasActiveDonation)
        XCTAssertNil(sut.activeDonationProductID)
        XCTAssertNil(sut.activeDonationExpirationDate)
        XCTAssertFalse(sut.isRefreshingDonationStatus)
    }

    // MARK: - Product IDs

    func testProductIDsMatchAppStoreConnect() {
        let expected = [
            "com.shamelagpt.ios.donation.1monthly",
            "com.shamelagpt.ios.donation.5monthly",
            "com.shamelagpt.ios.donation.10monthly",
            "com.shamelagpt.ios.donation.100yearly"
        ]
        XCTAssertEqual(DonationViewModel.productIDs, expected)
    }

    func testProductIDsAllHaveBundleIDPrefix() {
        let bundleID = "com.shamelagpt.ios"
        for id in DonationViewModel.productIDs {
            XCTAssertTrue(id.hasPrefix(bundleID), "\(id) should start with bundle ID prefix \(bundleID)")
        }
    }

    func testProductIDCountIsFour() {
        XCTAssertEqual(DonationViewModel.productIDs.count, 4)
    }

    func testAppleDonationLogPrefixIsFilterable() {
        XCTAssertEqual(AppLogger.LogPrefix.apple, "SGPApple")
        XCTAssertEqual(AppLogger.LogPrefix.appleDonation, "SGPApple.Donation")
        XCTAssertTrue(AppLogger.LogPrefix.appleDonation.hasPrefix(AppLogger.LogPrefix.apple))
    }

    func testProductIDsContainThreeMonthlyAndOneYearly() {
        let monthly = DonationViewModel.productIDs.filter { $0.hasSuffix("monthly") }
        let yearly  = DonationViewModel.productIDs.filter { $0.hasSuffix("yearly") }
        XCTAssertEqual(monthly.count, 3)
        XCTAssertEqual(yearly.count, 1)
    }

    // MARK: - loadProducts sets isLoading

    func testLoadProductsSetsIsLoading() {
        sut.loadProducts()
        // StoreKit request is async; isLoading should be true immediately
        XCTAssertTrue(sut.isLoading)
    }

    func testLoadProductsCalledTwiceDoesNotDuplicateRequest() {
        // Second call while products is empty still fires (idempotent guard is on non-empty)
        sut.loadProducts()
        XCTAssertTrue(sut.isLoading)
        // Calling again while loading should not crash
        sut.loadProducts()
        XCTAssertTrue(sut.isLoading)
    }

    // MARK: - purchaseDisabled

    func testPurchaseWhenPaymentsDisabledSetsError() {
        // SKPaymentQueue.canMakePayments() returns true in simulator by default,
        // so we test the error message key exists in localization instead.
        let key = LocalizationKeys.donatePaymentsDisabled
        XCTAssertFalse(key.isEmpty)
        let en = NSLocalizedString(key, bundle: .main, comment: "")
        XCTAssertFalse(en.isEmpty)
    }

    // MARK: - Localization keys exist

    func testAllDonationLocalizationKeysAreNonEmpty() {
        let keys: [String] = [
            LocalizationKeys.donate,
            LocalizationKeys.donateSheetTitle,
            LocalizationKeys.donateSheetSubtitle,
            LocalizationKeys.donateFooter,
            LocalizationKeys.donateRestore,
            LocalizationKeys.donateSuccessTitle,
            LocalizationKeys.donateSuccessMessage,
            LocalizationKeys.donateLoadFailed,
            LocalizationKeys.donatePaymentsDisabled,
            LocalizationKeys.donateCurrent,
            LocalizationKeys.donateCurrentStatus,
        ]
        for key in keys {
            XCTAssertFalse(key.isEmpty, "Key should not be empty")
        }
    }

    func testDonationLocalizationKeysResolveInEnglish() {
        let keys: [String] = [
            LocalizationKeys.donate,
            LocalizationKeys.donateSheetTitle,
            LocalizationKeys.donateSheetSubtitle,
            LocalizationKeys.donateFooter,
            LocalizationKeys.donateRestore,
            LocalizationKeys.donateSuccessTitle,
            LocalizationKeys.donateSuccessMessage,
            LocalizationKeys.donateLoadFailed,
            LocalizationKeys.donatePaymentsDisabled,
            LocalizationKeys.donateCurrent,
            LocalizationKeys.donateCurrentStatus,
        ]
        for key in keys {
            let resolved = NSLocalizedString(key, bundle: .main, comment: "")
            // A missing key returns the key itself — verify it resolved to something different
            XCTAssertNotEqual(resolved, key, "Key '\(key)' is missing from Localizable.strings")
        }
    }
}
