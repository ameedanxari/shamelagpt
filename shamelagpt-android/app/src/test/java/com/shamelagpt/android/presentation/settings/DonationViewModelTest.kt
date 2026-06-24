package com.shamelagpt.android.presentation.settings

import android.app.Activity
import com.shamelagpt.android.R
import com.shamelagpt.android.domain.billing.DonationBillingResult
import com.shamelagpt.android.domain.billing.DonationBillingService
import com.shamelagpt.android.domain.billing.DonationPurchaseEvent
import com.shamelagpt.android.domain.model.DonationBillingPeriod
import com.shamelagpt.android.domain.model.DonationProduct
import io.mockk.mockk
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class DonationViewModelTest {

    private val testDispatcher = UnconfinedTestDispatcher()
    private lateinit var billingService: FakeDonationBillingService
    private lateinit var viewModel: DonationViewModel

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        billingService = FakeDonationBillingService()
        viewModel = DonationViewModel(billingService)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `product ids match Google Play donation subscriptions`() {
        assertEquals(
            listOf(
                "com.shamelagpt.android.donation.1monthly",
                "com.shamelagpt.android.donation.5monthly",
                "com.shamelagpt.android.donation.10monthly",
                "com.shamelagpt.android.donation.100yearly"
            ),
            DonationViewModel.productIds
        )
    }

    @Test
    fun `loadProducts exposes products and active donation`() = runTest {
        billingService.productsResult = Result.success(listOf(monthlyProduct))
        billingService.activeDonationResult = Result.success(monthlyProduct.productId)

        viewModel.loadProducts()
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(listOf(monthlyProduct), state.products)
        assertEquals(monthlyProduct.productId, state.activeDonationProductId)
        assertFalse(state.isLoading)
        assertEquals(null, state.errorMessageResId)
    }

    @Test
    fun `loadProducts failure shows localized load failure`() = runTest {
        billingService.productsResult = Result.failure(IllegalStateException("Billing unavailable"))

        viewModel.loadProducts()
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertTrue(state.products.isEmpty())
        assertFalse(state.isLoading)
        assertEquals(R.string.donate_load_failed, state.errorMessageResId)
    }

    @Test
    fun `purchase unavailable clears loading state and shows localized error`() {
        billingService.launchResult = DonationBillingResult.ProductUnavailable

        viewModel.purchase(mockk<Activity>(relaxed = true), monthlyProduct.productId)

        val state = viewModel.uiState.value
        assertFalse(state.isPurchasing)
        assertEquals(R.string.donate_product_unavailable, state.errorMessageResId)
    }

    @Test
    fun `completed purchase marks success and active product`() = runTest {
        billingService.activeDonationResult = Result.success(monthlyProduct.productId)
        advanceUntilIdle()

        billingService.events.emit(DonationPurchaseEvent.Completed(monthlyProduct.productId))
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertTrue(state.purchaseSuccess)
        assertEquals(monthlyProduct.productId, state.activeDonationProductId)
        assertFalse(state.isPurchasing)
    }

    private companion object {
        val monthlyProduct = DonationProduct(
            productId = "com.shamelagpt.android.donation.1monthly",
            title = "$1 Monthly",
            description = "Coffee for our researchers",
            formattedPrice = "$1.00",
            priceAmountMicros = 1_000_000,
            billingPeriod = DonationBillingPeriod.Monthly
        )
    }
}

private class FakeDonationBillingService : DonationBillingService {
    val events = MutableSharedFlow<DonationPurchaseEvent>(extraBufferCapacity = 8)
    override val purchaseEvents: SharedFlow<DonationPurchaseEvent> = events

    var productsResult: Result<List<DonationProduct>> = Result.success(emptyList())
    var activeDonationResult: Result<String?> = Result.success(null)
    var launchResult: DonationBillingResult = DonationBillingResult.Started

    override suspend fun loadProducts(productIds: List<String>): Result<List<DonationProduct>> {
        return productsResult
    }

    override suspend fun queryActiveDonation(productIds: Set<String>): Result<String?> {
        return activeDonationResult
    }

    override fun launchPurchase(activity: Activity, productId: String): DonationBillingResult {
        return launchResult
    }
}
