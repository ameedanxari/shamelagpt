package com.shamelagpt.android.presentation.settings

import com.shamelagpt.android.domain.model.DonationProduct

data class DonationUiState(
    val products: List<DonationProduct> = emptyList(),
    val isLoading: Boolean = false,
    val isPurchasing: Boolean = false,
    val purchaseSuccess: Boolean = false,
    val errorMessageResId: Int? = null,
    val errorMessage: String? = null,
    val activeDonationProductId: String? = null,
    val pendingDonationProductId: String? = null
)
