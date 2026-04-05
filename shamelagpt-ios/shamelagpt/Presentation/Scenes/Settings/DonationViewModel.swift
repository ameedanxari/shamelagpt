//
//  DonationViewModel.swift
//  ShamelaGPT
//

import StoreKit
import SwiftUI

@MainActor
final class DonationViewModel: NSObject, ObservableObject {

    // MARK: - Product IDs (must match App Store Connect exactly)

    static let productIDs: [String] = [
        "com.shamelagpt.ios.donation.1monthly",
        "com.shamelagpt.ios.donation.5monthly",
        "com.shamelagpt.ios.donation.10monthly",
        "com.shamelagpt.ios.donation.100yearly"
    ]

    // MARK: - Published State

    @Published var products: [SKProduct] = []
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var purchaseSuccess = false
    @Published var errorMessage: String?

    // MARK: - Request Tracking

    private var productsRequest: SKProductsRequest?
    private var requestedProductIDs: Set<String> = []

    // MARK: - Init

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Load Products

    func loadProducts() {
        guard products.isEmpty else {
            AppLogger.app.logDebug("Skipping IAP load; products already loaded count=\(products.count)")
            return
        }

        requestedProductIDs = Set(Self.productIDs)
        let requestedIDsList = requestedProductIDs.sorted().joined(separator: ", ")
        AppLogger.app.logInfo("Starting IAP products request for IDs: [\(requestedIDsList)]")

        isLoading = true
        let request = SKProductsRequest(productIdentifiers: requestedProductIDs)
        request.delegate = self
        productsRequest = request
        request.start()
    }

    // MARK: - Purchase

    func purchase(_ product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            errorMessage = LanguageManager.shared.localizedString(forKey: LocalizationKeys.donatePaymentsDisabled)
            return
        }
        isPurchasing = true
        errorMessage = nil
        SKPaymentQueue.default().add(SKPayment(product: product))
    }

    // MARK: - Restore

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

extension DonationViewModel: SKProductsRequestDelegate {
    nonisolated func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let sorted = response.products.sorted { $0.price.doubleValue < $1.price.doubleValue }
        let returnedIDs = Set(response.products.map(\.productIdentifier))
        let invalidIDs = Set(response.invalidProductIdentifiers)
        let storefront = SKPaymentQueue.default().storefront?.countryCode ?? "unknown"
        let receiptURL = Bundle.main.appStoreReceiptURL?.path ?? "missing"

        Task { @MainActor in
            let missingIDs = self.requestedProductIDs.subtracting(returnedIDs).subtracting(invalidIDs)
            AppLogger.app.logInfo(
                """
                IAP response received: requested=\(self.requestedProductIDs.count) valid=\(response.products.count) invalid=\(response.invalidProductIdentifiers.count) missing=\(missingIDs.count) storefront=\(storefront) receiptURL=\(receiptURL)
                """
            )

            if !returnedIDs.isEmpty {
                AppLogger.app.logInfo("Valid IAP product IDs: [\(returnedIDs.sorted().joined(separator: ", "))]")
                response.products.forEach { product in
                    AppLogger.app.logDebug(
                        """
                        IAP product detail id=\(product.productIdentifier) title="\(product.localizedTitle)" price=\(product.price) locale=\(product.priceLocale.identifier) subscriptionPeriod=\(product.subscriptionPeriod?.unit.rawValue.description ?? "none")
                        """
                    )
                }
            }

            if !invalidIDs.isEmpty {
                AppLogger.app.logWarning("Invalid IAP product IDs: \(invalidIDs.sorted())")
            }

            if !missingIDs.isEmpty {
                AppLogger.app.logWarning("Missing IAP product IDs (neither valid nor invalid): \(missingIDs.sorted())")
            }

            self.products = sorted
            self.isLoading = false
            self.productsRequest = nil
        }
    }

    nonisolated func request(_ request: SKRequest, didFailWithError error: Error) {
        let nsError = error as NSError
        AppLogger.app.logError(
            "IAP products request failed domain=\(nsError.domain) code=\(nsError.code) userInfo=\(nsError.userInfo)",
            error: error
        )
        Task { @MainActor in
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.productsRequest = nil
        }
    }

    nonisolated func requestDidFinish(_ request: SKRequest) {
        AppLogger.app.logInfo("IAP products request finished successfully")
    }
}

// MARK: - SKPaymentTransactionObserver

extension DonationViewModel: SKPaymentTransactionObserver {
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            AppLogger.app.logDebug(
                "IAP transaction update state=\(transaction.transactionState.rawValue) productID=\(transaction.payment.productIdentifier)"
            )
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                Task { @MainActor in
                    self.isPurchasing = false
                    self.purchaseSuccess = true
                }
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                let msg = transaction.error?.localizedDescription
                if let skError = transaction.error as? SKError {
                    AppLogger.app.logWarning(
                        "IAP purchase failed productID=\(transaction.payment.productIdentifier) code=\(skError.code.rawValue) message=\(skError.localizedDescription)"
                    )
                }
                Task { @MainActor in
                    self.isPurchasing = false
                    // SKErrorPaymentCancelled = 2 — don't show error for user cancellation
                    if (transaction.error as? SKError)?.code != .paymentCancelled {
                        self.errorMessage = msg
                    }
                }
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
}
