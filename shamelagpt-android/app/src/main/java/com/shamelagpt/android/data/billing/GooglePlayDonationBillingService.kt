package com.shamelagpt.android.data.billing

import android.app.Activity
import android.content.Context
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import com.shamelagpt.android.core.util.Logger
import com.shamelagpt.android.domain.billing.DonationBillingResult
import com.shamelagpt.android.domain.billing.DonationBillingService
import com.shamelagpt.android.domain.billing.DonationPurchaseEvent
import com.shamelagpt.android.domain.model.DonationBillingPeriod
import com.shamelagpt.android.domain.model.DonationProduct
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume

private const val TAG = "DonationBilling"

class GooglePlayDonationBillingService(
    context: Context
) : DonationBillingService, PurchasesUpdatedListener {

    private val appContext = context.applicationContext
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val productDetailsById = mutableMapOf<String, ProductDetails>()

    private val _purchaseEvents = MutableSharedFlow<DonationPurchaseEvent>(extraBufferCapacity = 8)
    override val purchaseEvents: SharedFlow<DonationPurchaseEvent> = _purchaseEvents

    private val billingClient: BillingClient = BillingClient.newBuilder(appContext)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder()
                .enableOneTimeProducts()
                .build()
        )
        .enableAutoServiceReconnection()
        .build()

    override suspend fun loadProducts(productIds: List<String>): Result<List<DonationProduct>> {
        val connection = ensureConnected()
        if (connection.responseCode != BillingClient.BillingResponseCode.OK) {
            Logger.w(TAG, "event=products.connectionFailure code=${connection.responseCode} message=${connection.debugMessage}")
            return Result.failure(IllegalStateException(connection.debugMessage))
        }

        return suspendCancellableCoroutine { continuation ->
            val products = productIds.map { id ->
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(id)
                    .setProductType(BillingClient.ProductType.SUBS)
                    .build()
            }

            val params = QueryProductDetailsParams.newBuilder()
                .setProductList(products)
                .build()

            billingClient.queryProductDetailsAsync(params) { billingResult, productDetailsResult ->
                if (!continuation.isActive) return@queryProductDetailsAsync

                if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                    Logger.w(TAG, "event=products.failure code=${billingResult.responseCode} message=${billingResult.debugMessage}")
                    continuation.resume(Result.failure(IllegalStateException(billingResult.debugMessage)))
                    return@queryProductDetailsAsync
                }

                val details = productDetailsResult.productDetailsList
                val unfetchedCount = productDetailsResult.unfetchedProductList.size
                productDetailsById.clear()
                productDetailsById.putAll(details.associateBy { it.productId })
                Logger.i(TAG, "event=products.loaded valid=${details.size} unfetched=$unfetchedCount")

                val mappedProducts = details
                    .mapNotNull(::mapDonationProduct)
                    .sortedWith(
                        compareBy<DonationProduct> { productIds.indexOf(it.productId).takeIf { index -> index >= 0 } ?: Int.MAX_VALUE }
                            .thenBy { it.priceAmountMicros }
                    )
                continuation.resume(Result.success(mappedProducts))
            }
        }
    }

    override suspend fun queryActiveDonation(productIds: Set<String>): Result<String?> {
        val connection = ensureConnected()
        if (connection.responseCode != BillingClient.BillingResponseCode.OK) {
            Logger.w(TAG, "event=status.connectionFailure code=${connection.responseCode} message=${connection.debugMessage}")
            return Result.failure(IllegalStateException(connection.debugMessage))
        }

        return suspendCancellableCoroutine { continuation ->
            val params = QueryPurchasesParams.newBuilder()
                .setProductType(BillingClient.ProductType.SUBS)
                .build()

            billingClient.queryPurchasesAsync(params) { billingResult, purchases ->
                if (!continuation.isActive) return@queryPurchasesAsync

                if (billingResult.responseCode != BillingClient.BillingResponseCode.OK) {
                    Logger.w(TAG, "event=status.failure code=${billingResult.responseCode} message=${billingResult.debugMessage}")
                    continuation.resume(Result.failure(IllegalStateException(billingResult.debugMessage)))
                    return@queryPurchasesAsync
                }

                val activeProductId = purchases
                    .filter { it.purchaseState == Purchase.PurchaseState.PURCHASED && !it.isSuspended }
                    .flatMap { purchase -> purchase.products.map { productId -> purchase to productId } }
                    .firstOrNull { (_, productId) -> productIds.contains(productId) }
                    ?.second

                purchases
                    .filter { it.purchaseState == Purchase.PurchaseState.PURCHASED && !it.isAcknowledged }
                    .forEach { purchase -> acknowledgePurchase(purchase) }

                Logger.i(TAG, "event=status.loaded purchaseCount=${purchases.size} activeProductId=$activeProductId")
                continuation.resume(Result.success(activeProductId))
            }
        }
    }

    override fun launchPurchase(activity: Activity, productId: String): DonationBillingResult {
        val productDetails = productDetailsById[productId] ?: return DonationBillingResult.ProductUnavailable
        val offerToken = productDetails.subscriptionOfferDetails?.firstOrNull()?.offerToken
            ?: return DonationBillingResult.ProductUnavailable

        val productDetailsParams = BillingFlowParams.ProductDetailsParams.newBuilder()
            .setProductDetails(productDetails)
            .setOfferToken(offerToken)
            .build()

        val billingFlowParams = BillingFlowParams.newBuilder()
            .setProductDetailsParamsList(listOf(productDetailsParams))
            .build()

        val result = billingClient.launchBillingFlow(activity, billingFlowParams)
        Logger.i(TAG, "event=purchase.launch productId=$productId code=${result.responseCode} message=${result.debugMessage}")

        return when (result.responseCode) {
            BillingClient.BillingResponseCode.OK -> DonationBillingResult.Started
            BillingClient.BillingResponseCode.ITEM_UNAVAILABLE -> DonationBillingResult.ProductUnavailable
            else -> DonationBillingResult.Failed(result.debugMessage)
        }
    }

    override fun onPurchasesUpdated(billingResult: BillingResult, purchases: MutableList<Purchase>?) {
        when (billingResult.responseCode) {
            BillingClient.BillingResponseCode.OK -> {
                purchases.orEmpty().forEach { purchase ->
                    scope.launch {
                        processPurchase(purchase)
                    }
                }
            }
            BillingClient.BillingResponseCode.USER_CANCELED -> {
                Logger.i(TAG, "event=purchase.cancelled")
            }
            else -> {
                Logger.w(TAG, "event=purchase.failure code=${billingResult.responseCode} message=${billingResult.debugMessage}")
                _purchaseEvents.tryEmit(DonationPurchaseEvent.Failed(billingResult.debugMessage))
            }
        }
    }

    private suspend fun processPurchase(purchase: Purchase) {
        val productId = purchase.products.firstOrNull()
        when (purchase.purchaseState) {
            Purchase.PurchaseState.PURCHASED -> {
                acknowledgePurchase(purchase)
                if (productId != null) {
                    _purchaseEvents.emit(DonationPurchaseEvent.Completed(productId))
                }
            }
            Purchase.PurchaseState.PENDING -> {
                if (productId != null) {
                    _purchaseEvents.emit(DonationPurchaseEvent.Pending(productId))
                }
            }
            else -> Unit
        }
    }

    private fun acknowledgePurchase(purchase: Purchase) {
        if (purchase.isAcknowledged) return

        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()

        billingClient.acknowledgePurchase(params) { result ->
            Logger.i(TAG, "event=purchase.acknowledge code=${result.responseCode} message=${result.debugMessage}")
        }
    }

    private suspend fun ensureConnected(): BillingResult {
        if (billingClient.isReady) {
            return okResult()
        }

        return withContext(Dispatchers.Main.immediate) {
            suspendCancellableCoroutine { continuation ->
                billingClient.startConnection(object : BillingClientStateListener {
                    override fun onBillingSetupFinished(billingResult: BillingResult) {
                        if (continuation.isActive) {
                            continuation.resume(billingResult)
                        }
                    }

                    override fun onBillingServiceDisconnected() {
                        Logger.w(TAG, "event=service.disconnected")
                    }
                })
            }
        }
    }

    private fun mapDonationProduct(productDetails: ProductDetails): DonationProduct? {
        val offer = productDetails.subscriptionOfferDetails?.firstOrNull() ?: return null
        val phase = offer.pricingPhases.pricingPhaseList.firstOrNull() ?: return null

        return DonationProduct(
            productId = productDetails.productId,
            title = productDetails.title,
            description = productDetails.description,
            formattedPrice = phase.formattedPrice,
            priceAmountMicros = phase.priceAmountMicros,
            billingPeriod = billingPeriodFor(productDetails.productId, phase.billingPeriod)
        )
    }

    private fun billingPeriodFor(productId: String, billingPeriod: String): DonationBillingPeriod {
        return when {
            billingPeriod.contains("Y", ignoreCase = true) -> DonationBillingPeriod.Yearly
            productId.contains("year", ignoreCase = true) -> DonationBillingPeriod.Yearly
            else -> DonationBillingPeriod.Monthly
        }
    }

    private fun okResult(): BillingResult {
        return BillingResult.newBuilder()
            .setResponseCode(BillingClient.BillingResponseCode.OK)
            .build()
    }
}
