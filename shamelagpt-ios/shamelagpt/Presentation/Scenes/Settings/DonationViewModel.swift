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
    @Published private(set) var activeDonationProductID: String?
    @Published private(set) var activeDonationExpirationDate: Date?
    @Published private(set) var isRefreshingDonationStatus = false

    // MARK: - Request Tracking

    private var productsRequest: SKProductsRequest?
    private var requestedProductIDs: Set<String> = []
    private var transactionUpdatesTask: Task<Void, Never>?

    // MARK: - Init

    override init() {
        super.init()
        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=viewModel.init addTransactionObserver=true productIDs=[\(Self.productIDs.joined(separator: ", "))]"
        )
        SKPaymentQueue.default().add(self)
        observeTransactionUpdates()
    }

    deinit {
        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=viewModel.deinit removeTransactionObserver=true"
        )
        transactionUpdatesTask?.cancel()
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Load Products

    func loadProducts() {
        guard products.isEmpty else {
            AppLogger.appleDonation.logDebug(
                prefix: AppLogger.LogPrefix.appleDonation,
                "event=products.load.skip reason=alreadyLoaded loadedCount=\(products.count)"
            )
            return
        }

        requestedProductIDs = Set(Self.productIDs)
        let requestedIDsList = requestedProductIDs.sorted().joined(separator: ", ")
        let storefront = SKPaymentQueue.default().storefront?.countryCode ?? "unknown"
        let canMakePayments = SKPaymentQueue.canMakePayments()
        let receiptURL = Bundle.main.appStoreReceiptURL?.path ?? "missing"
        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=products.load.start requestedCount=\(requestedProductIDs.count) requestedIDs=[\(requestedIDsList)] canMakePayments=\(canMakePayments) storefront=\(storefront) receiptURL=\(receiptURL)"
        )

        isLoading = true
        let request = SKProductsRequest(productIdentifiers: requestedProductIDs)
        request.delegate = self
        productsRequest = request
        AppLogger.appleDonation.logDebug(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=products.request.start requestObject=\(String(describing: ObjectIdentifier(request)))"
        )
        request.start()

        Task {
            await refreshDonationStatus(source: "products.load")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: SKProduct) {
        guard SKPaymentQueue.canMakePayments() else {
            AppLogger.appleDonation.logWarning(
                prefix: AppLogger.LogPrefix.appleDonation,
                "event=purchase.blocked productID=\(product.productIdentifier) reason=paymentsDisabled"
            )
            errorMessage = LanguageManager.shared.localizedString(forKey: LocalizationKeys.donatePaymentsDisabled)
            return
        }
        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=purchase.start productID=\(product.productIdentifier) price=\(product.price) locale=\(product.priceLocale.identifier) period=\(product.debugSubscriptionPeriod)"
        )
        isPurchasing = true
        errorMessage = nil
        SKPaymentQueue.default().add(SKPayment(product: product))
        AppLogger.appleDonation.logDebug(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=purchase.paymentQueued productID=\(product.productIdentifier)"
        )
    }

    // MARK: - Restore

    func restorePurchases() {
        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=restore.start"
        )
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    // MARK: - Donation Status

    var hasActiveDonation: Bool {
        activeDonationProductID != nil
    }

    func isCurrentDonation(_ product: SKProduct) -> Bool {
        activeDonationProductID == product.productIdentifier
    }

    func activeDonationTitle() -> String? {
        guard let activeDonationProductID else { return nil }
        return products.first { $0.productIdentifier == activeDonationProductID }?.localizedTitle
    }

    func refreshDonationStatus(source: String = "manual") async {
        isRefreshingDonationStatus = true
        defer { isRefreshingDonationStatus = false }

        let knownProductIDs = Set(Self.productIDs)
        let now = Date()
        var activeTransactions: [StoreKit.Transaction] = []
        var verifiedCount = 0
        var unverifiedCount = 0

        for await result in StoreKit.Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                verifiedCount += 1
                guard knownProductIDs.contains(transaction.productID) else { continue }
                guard transaction.revocationDate == nil else { continue }
                if let expirationDate = transaction.expirationDate, expirationDate <= now {
                    continue
                }
                activeTransactions.append(transaction)
            case .unverified(let transaction, let error):
                unverifiedCount += 1
                AppLogger.appleDonation.logWarning(
                    prefix: AppLogger.LogPrefix.appleDonation,
                    "event=status.entitlement.unverified source=\(source) productID=\(transaction.productID) reason=\(type(of: error)) message=\(error.localizedDescription)"
                )
            }
        }

        let selected = activeTransactions.sorted { lhs, rhs in
            let lhsDate = lhs.expirationDate ?? lhs.purchaseDate
            let rhsDate = rhs.expirationDate ?? rhs.purchaseDate
            return lhsDate > rhsDate
        }.first

        activeDonationProductID = selected?.productID
        activeDonationExpirationDate = selected?.expirationDate

        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=status.refresh source=\(source) verified=\(verifiedCount) unverified=\(unverifiedCount) activeCount=\(activeTransactions.count) activeProductID=\(activeDonationProductID ?? "nil") expiration=\(activeDonationExpirationDate?.description ?? "nil")"
        )
    }

    private func observeTransactionUpdates() {
        transactionUpdatesTask = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard !Task.isCancelled else { return }
                switch result {
                case .verified(let transaction):
                    guard Self.productIDs.contains(transaction.productID) else { continue }
                    AppLogger.appleDonation.logInfo(
                        prefix: AppLogger.LogPrefix.appleDonation,
                        "event=status.transactionUpdate.verified productID=\(transaction.productID) expiration=\(transaction.expirationDate?.description ?? "nil") revocation=\(transaction.revocationDate?.description ?? "nil")"
                    )
                    await transaction.finish()
                    await self?.refreshDonationStatus(source: "transaction.updates")
                case .unverified(let transaction, let error):
                    guard Self.productIDs.contains(transaction.productID) else { continue }
                    AppLogger.appleDonation.logWarning(
                        prefix: AppLogger.LogPrefix.appleDonation,
                        "event=status.transactionUpdate.unverified productID=\(transaction.productID) reason=\(type(of: error)) message=\(error.localizedDescription)"
                    )
                }
            }
        }
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
            AppLogger.appleDonation.logInfo(
                prefix: AppLogger.LogPrefix.appleDonation,
                "event=products.response received=true requested=\(self.requestedProductIDs.count) valid=\(response.products.count) invalid=\(response.invalidProductIdentifiers.count) missing=\(missingIDs.count) storefront=\(storefront) receiptURL=\(receiptURL)"
            )

            if !returnedIDs.isEmpty {
                AppLogger.appleDonation.logInfo(
                    prefix: AppLogger.LogPrefix.appleDonation,
                    "event=products.response.validIDs ids=[\(returnedIDs.sorted().joined(separator: ", "))]"
                )
                response.products.forEach { product in
                    AppLogger.appleDonation.logDebug(
                        prefix: AppLogger.LogPrefix.appleDonation,
                        "event=products.response.productDetail id=\(product.productIdentifier) title=\"\(product.localizedTitle)\" descriptionLength=\(product.localizedDescription.count) price=\(product.price) locale=\(product.priceLocale.identifier) subscriptionPeriod=\(product.debugSubscriptionPeriod) introductoryPrice=\(product.debugIntroductoryPrice)"
                    )
                }
            }

            if !invalidIDs.isEmpty {
                AppLogger.appleDonation.logWarning(
                    prefix: AppLogger.LogPrefix.appleDonation,
                    "event=products.response.invalidIDs ids=[\(invalidIDs.sorted().joined(separator: ", "))]"
                )
            }

            if !missingIDs.isEmpty {
                AppLogger.appleDonation.logWarning(
                    prefix: AppLogger.LogPrefix.appleDonation,
                    "event=products.response.missingIDs ids=[\(missingIDs.sorted().joined(separator: ", "))]"
                )
            }

            self.products = sorted
            self.isLoading = false
            self.productsRequest = nil
            AppLogger.appleDonation.logDebug(
                prefix: AppLogger.LogPrefix.appleDonation,
                "event=products.response.stateUpdated loadedCount=\(self.products.count) isLoading=false requestCleared=true"
            )
        }
    }

    nonisolated func request(_ request: SKRequest, didFailWithError error: Error) {
        let nsError = error as NSError
        AppLogger.appleDonation.logError(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=products.request.failure domain=\(nsError.domain) code=\(nsError.code) errorType=\(type(of: error)) userInfo=\(nsError.userInfo)",
            error: error
        )
        Task { @MainActor in
            self.isLoading = false
            self.errorMessage = error.localizedDescription
            self.productsRequest = nil
            AppLogger.appleDonation.logDebug(
                prefix: AppLogger.LogPrefix.appleDonation,
                "event=products.request.failureStateUpdated isLoading=false errorMessageSet=true requestCleared=true"
            )
        }
    }

    nonisolated func requestDidFinish(_ request: SKRequest) {
        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=products.request.finish requestType=\(type(of: request))"
        )
    }
}

// MARK: - SKPaymentTransactionObserver

extension DonationViewModel: SKPaymentTransactionObserver {
    nonisolated func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        AppLogger.appleDonation.logDebug(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=transaction.batchUpdate count=\(transactions.count)"
        )
        for transaction in transactions {
            AppLogger.appleDonation.logDebug(
                prefix: AppLogger.LogPrefix.appleDonation,
                "event=transaction.update state=\(transaction.transactionState.debugName) rawState=\(transaction.transactionState.rawValue) productID=\(transaction.payment.productIdentifier) transactionID=\(transaction.transactionIdentifier ?? "nil") originalTransactionID=\(transaction.original?.transactionIdentifier ?? "nil") date=\(transaction.transactionDate?.description ?? "nil")"
            )
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                AppLogger.appleDonation.logInfo(
                    prefix: AppLogger.LogPrefix.appleDonation,
                    "event=transaction.finishSuccess state=\(transaction.transactionState.debugName) productID=\(transaction.payment.productIdentifier) transactionID=\(transaction.transactionIdentifier ?? "nil")"
                )
                Task { @MainActor in
                    self.isPurchasing = false
                    self.purchaseSuccess = true
                    self.activeDonationProductID = transaction.payment.productIdentifier
                    AppLogger.appleDonation.logDebug(
                        prefix: AppLogger.LogPrefix.appleDonation,
                        "event=transaction.successStateUpdated isPurchasing=false purchaseSuccess=true activeProductID=\(transaction.payment.productIdentifier)"
                    )
                    await self.refreshDonationStatus(source: "paymentQueue.\(transaction.transactionState.debugName)")
                }
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                let msg = transaction.error?.localizedDescription
                let nsError = transaction.error as NSError?
                if let skError = transaction.error as? SKError {
                    AppLogger.appleDonation.logWarning(
                        prefix: AppLogger.LogPrefix.appleDonation,
                        "event=transaction.failure productID=\(transaction.payment.productIdentifier) skErrorCode=\(skError.code.rawValue) message=\(skError.localizedDescription)"
                    )
                } else {
                    AppLogger.appleDonation.logWarning(
                        prefix: AppLogger.LogPrefix.appleDonation,
                        "event=transaction.failure productID=\(transaction.payment.productIdentifier) domain=\(nsError?.domain ?? "nil") code=\(nsError?.code.description ?? "nil") message=\(msg ?? "nil")"
                    )
                }
                Task { @MainActor in
                    self.isPurchasing = false
                    // SKErrorPaymentCancelled = 2 — don't show error for user cancellation
                    if (transaction.error as? SKError)?.code != .paymentCancelled {
                        self.errorMessage = msg
                    }
                    AppLogger.appleDonation.logDebug(
                        prefix: AppLogger.LogPrefix.appleDonation,
                        "event=transaction.failureStateUpdated isPurchasing=false errorMessageSet=\(self.errorMessage != nil)"
                    )
                }
            case .deferred, .purchasing:
                AppLogger.appleDonation.logDebug(
                    prefix: AppLogger.LogPrefix.appleDonation,
                    "event=transaction.pending state=\(transaction.transactionState.debugName) productID=\(transaction.payment.productIdentifier)"
                )
                break
            @unknown default:
                AppLogger.appleDonation.logWarning(
                    prefix: AppLogger.LogPrefix.appleDonation,
                    "event=transaction.unknownState rawState=\(transaction.transactionState.rawValue) productID=\(transaction.payment.productIdentifier)"
                )
                break
            }
        }
    }

    nonisolated func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        let productIDs = transactions.map { $0.payment.productIdentifier }.joined(separator: ", ")
        AppLogger.appleDonation.logDebug(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=transaction.removed count=\(transactions.count) productIDs=[\(productIDs)]"
        )
    }

    nonisolated func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        AppLogger.appleDonation.logInfo(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=restore.finished transactionCount=\(queue.transactions.count)"
        )
        Task { @MainActor in
            await self.refreshDonationStatus(source: "restore.finished")
        }
    }

    nonisolated func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        let nsError = error as NSError
        AppLogger.appleDonation.logError(
            prefix: AppLogger.LogPrefix.appleDonation,
            "event=restore.failure domain=\(nsError.domain) code=\(nsError.code) errorType=\(type(of: error)) message=\(error.localizedDescription)",
            error: error
        )
    }
}

private extension SKProduct {
    var debugSubscriptionPeriod: String {
        guard let subscriptionPeriod else { return "none" }
        return "\(subscriptionPeriod.numberOfUnits)-\(subscriptionPeriod.unit.debugName)"
    }

    var debugIntroductoryPrice: String {
        guard let introductoryPrice else { return "none" }
        return "price=\(introductoryPrice.price) locale=\(introductoryPrice.priceLocale.identifier) period=\(introductoryPrice.subscriptionPeriod.numberOfUnits)-\(introductoryPrice.subscriptionPeriod.unit.debugName) periods=\(introductoryPrice.numberOfPeriods) paymentMode=\(introductoryPrice.paymentMode.debugName)"
    }
}

private extension SKProduct.PeriodUnit {
    var debugName: String {
        switch self {
        case .day:
            return "day"
        case .week:
            return "week"
        case .month:
            return "month"
        case .year:
            return "year"
        @unknown default:
            return "unknown(\(rawValue))"
        }
    }
}

private extension SKProductDiscount.PaymentMode {
    var debugName: String {
        switch self {
        case .payAsYouGo:
            return "payAsYouGo"
        case .payUpFront:
            return "payUpFront"
        case .freeTrial:
            return "freeTrial"
        @unknown default:
            return "unknown(\(rawValue))"
        }
    }
}

private extension SKPaymentTransactionState {
    var debugName: String {
        switch self {
        case .purchasing:
            return "purchasing"
        case .purchased:
            return "purchased"
        case .failed:
            return "failed"
        case .restored:
            return "restored"
        case .deferred:
            return "deferred"
        @unknown default:
            return "unknown(\(rawValue))"
        }
    }
}
