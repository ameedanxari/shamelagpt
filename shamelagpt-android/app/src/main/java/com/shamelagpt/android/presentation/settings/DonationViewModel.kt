package com.shamelagpt.android.presentation.settings

import android.app.Activity
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shamelagpt.android.R
import com.shamelagpt.android.core.util.Logger
import com.shamelagpt.android.domain.billing.DonationBillingResult
import com.shamelagpt.android.domain.billing.DonationBillingService
import com.shamelagpt.android.domain.billing.DonationPurchaseEvent
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

private const val TAG = "DonationVM"

class DonationViewModel(
    private val billingService: DonationBillingService
) : ViewModel() {

    private val _uiState = MutableStateFlow(DonationUiState())
    val uiState: StateFlow<DonationUiState> = _uiState.asStateFlow()

    init {
        observePurchaseEvents()
    }

    fun loadProducts(forceRefresh: Boolean = false) {
        val currentState = _uiState.value
        if (!forceRefresh && currentState.products.isNotEmpty()) {
            refreshDonationStatus()
            return
        }

        viewModelScope.launch {
            _uiState.update {
                it.copy(
                    isLoading = true,
                    errorMessage = null,
                    errorMessageResId = null
                )
            }

            val result = billingService.loadProducts(productIds)
            result.fold(
                onSuccess = { products ->
                    Logger.i(TAG, "event=products.loaded count=${products.size}")
                    _uiState.update {
                        it.copy(
                            products = products,
                            isLoading = false,
                            errorMessageResId = if (products.isEmpty()) R.string.donate_load_failed else null
                        )
                    }
                    refreshDonationStatus()
                },
                onFailure = { error ->
                    Logger.w(TAG, "event=products.failure message=${error.message}")
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            errorMessageResId = R.string.donate_load_failed
                        )
                    }
                }
            )
        }
    }

    fun purchase(activity: Activity, productId: String) {
        _uiState.update {
            it.copy(
                isPurchasing = true,
                errorMessage = null,
                errorMessageResId = null
            )
        }

        when (val result = billingService.launchPurchase(activity, productId)) {
            DonationBillingResult.Started -> Unit
            DonationBillingResult.ProductUnavailable -> {
                _uiState.update {
                    it.copy(
                        isPurchasing = false,
                        errorMessageResId = R.string.donate_product_unavailable
                    )
                }
            }
            is DonationBillingResult.Failed -> {
                _uiState.update {
                    it.copy(
                        isPurchasing = false,
                        errorMessage = result.message,
                        errorMessageResId = if (result.message.isNullOrBlank()) R.string.donate_purchase_failed else null
                    )
                }
            }
        }
    }

    fun refreshDonationStatus() {
        viewModelScope.launch {
            val result = billingService.queryActiveDonation(productIds.toSet())
            result.onSuccess { productId ->
                _uiState.update { it.copy(activeDonationProductId = productId) }
            }
        }
    }

    fun clearPurchaseSuccess() {
        _uiState.update { it.copy(purchaseSuccess = false) }
    }

    fun dismissError() {
        _uiState.update { it.copy(errorMessage = null, errorMessageResId = null) }
    }

    private fun observePurchaseEvents() {
        viewModelScope.launch {
            billingService.purchaseEvents.collect { event ->
                when (event) {
                    is DonationPurchaseEvent.Completed -> {
                        _uiState.update {
                            it.copy(
                                isPurchasing = false,
                                purchaseSuccess = true,
                                activeDonationProductId = event.productId,
                                pendingDonationProductId = null,
                                errorMessage = null,
                                errorMessageResId = null
                            )
                        }
                        refreshDonationStatus()
                    }
                    is DonationPurchaseEvent.Pending -> {
                        _uiState.update {
                            it.copy(
                                isPurchasing = false,
                                pendingDonationProductId = event.productId,
                                errorMessageResId = R.string.donate_purchase_pending
                            )
                        }
                    }
                    is DonationPurchaseEvent.Failed -> {
                        _uiState.update {
                            it.copy(
                                isPurchasing = false,
                                errorMessage = event.message,
                                errorMessageResId = if (event.message.isNullOrBlank()) R.string.donate_purchase_failed else null
                            )
                        }
                    }
                }
            }
        }
    }

    companion object {
        val productIds = listOf(
            "com.shamelagpt.android.donation.1monthly",
            "com.shamelagpt.android.donation.5monthly",
            "com.shamelagpt.android.donation.10month",
            "com.shamelagpt.android.donation.100year"
        )
    }
}
