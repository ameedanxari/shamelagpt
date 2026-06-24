package com.shamelagpt.android.domain.billing

import android.app.Activity
import com.shamelagpt.android.domain.model.DonationProduct
import kotlinx.coroutines.flow.SharedFlow

interface DonationBillingService {
    val purchaseEvents: SharedFlow<DonationPurchaseEvent>

    suspend fun loadProducts(productIds: List<String>): Result<List<DonationProduct>>

    suspend fun queryActiveDonation(productIds: Set<String>): Result<String?>

    fun launchPurchase(activity: Activity, productId: String): DonationBillingResult
}

sealed interface DonationPurchaseEvent {
    data class Completed(val productId: String) : DonationPurchaseEvent
    data class Pending(val productId: String) : DonationPurchaseEvent
    data class Failed(val message: String?) : DonationPurchaseEvent
}

sealed interface DonationBillingResult {
    data object Started : DonationBillingResult
    data object ProductUnavailable : DonationBillingResult
    data class Failed(val message: String?) : DonationBillingResult
}
