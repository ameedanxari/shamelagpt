package com.shamelagpt.android.domain.model

data class DonationProduct(
    val productId: String,
    val title: String,
    val description: String,
    val formattedPrice: String,
    val priceAmountMicros: Long,
    val billingPeriod: DonationBillingPeriod
)

enum class DonationBillingPeriod {
    Monthly,
    Yearly
}
