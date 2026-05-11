package com.shamelagpt.android.presentation.settings

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.OpenInNew
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.AssistChip
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
import com.shamelagpt.android.domain.model.DonationProduct
import com.shamelagpt.android.presentation.common.TestTags

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DonationSheet(
    uiState: DonationUiState,
    onDismiss: () -> Unit,
    onLoadProducts: () -> Unit,
    onRetry: () -> Unit,
    onPurchase: (Activity, String) -> Unit,
    onOpenPayPal: () -> Unit,
    onClearSuccess: () -> Unit,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val activity = context.findActivity()
    val errorText = uiState.errorMessage
        ?: uiState.errorMessageResId?.let { stringResource(it) }

    LaunchedEffect(Unit) {
        onLoadProducts()
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        modifier = modifier.testTag(TestTags.Settings.DonationSheet)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp, vertical = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            DonationHeader()

            Spacer(modifier = Modifier.height(16.dp))

            CurrentDonationStatus(uiState = uiState)

            when {
                uiState.isLoading -> {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator()
                    }
                }
                uiState.products.isEmpty() -> {
                    EmptyDonationOptions(onRetry = onRetry)
                }
                else -> {
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        uiState.products.forEach { product ->
                            DonationProductRow(
                                product = product,
                                isPurchasing = uiState.isPurchasing,
                                isCurrent = uiState.activeDonationProductId == product.productId,
                                activity = activity,
                                onPurchase = onPurchase
                            )
                        }
                    }
                }
            }

            if (!errorText.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = errorText,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.fillMaxWidth()
                )
            }

            Spacer(modifier = Modifier.height(18.dp))

            Text(
                text = stringResource(R.string.donate_footer_android),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(12.dp))

            OutlinedButton(
                onClick = onOpenPayPal,
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag(TestTags.Settings.DonationPayPalButton)
            ) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.OpenInNew,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp)
                )
                Spacer(modifier = Modifier.size(8.dp))
                Text(stringResource(R.string.donate_paypal_title))
            }

            Spacer(modifier = Modifier.height(20.dp))
        }
    }

    if (uiState.purchaseSuccess) {
        AlertDialog(
            onDismissRequest = onClearSuccess,
            confirmButton = {
                TextButton(
                    onClick = {
                        onClearSuccess()
                        onDismiss()
                    }
                ) {
                    Text(stringResource(R.string.dismiss))
                }
            },
            title = { Text(stringResource(R.string.donate_success_title)) },
            text = { Text(stringResource(R.string.donate_success_message)) }
        )
    }
}

@Composable
private fun DonationHeader() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = Icons.Default.Favorite,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.error,
            modifier = Modifier.size(44.dp)
        )
        Text(
            text = stringResource(R.string.donate_sheet_title),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
        Text(
            text = stringResource(R.string.donate_sheet_subtitle),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun CurrentDonationStatus(uiState: DonationUiState) {
    val productTitle = uiState.products
        .firstOrNull { it.productId == uiState.activeDonationProductId }
        ?.title
        ?: return

    Surface(
        color = MaterialTheme.colorScheme.primaryContainer,
        shape = MaterialTheme.shapes.medium,
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 12.dp)
    ) {
        Row(
            modifier = Modifier.padding(12.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
            Text(
                text = stringResource(R.string.donate_current_status, productTitle),
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold,
                color = MaterialTheme.colorScheme.onPrimaryContainer
            )
        }
    }
}

@Composable
private fun EmptyDonationOptions(onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text(
            text = stringResource(R.string.donate_load_failed),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
        OutlinedButton(
            onClick = onRetry,
            modifier = Modifier.testTag(TestTags.Settings.DonationRetryButton)
        ) {
            Text(stringResource(R.string.retry))
        }
    }
}

@Composable
private fun DonationProductRow(
    product: DonationProduct,
    isPurchasing: Boolean,
    isCurrent: Boolean,
    activity: Activity?,
    onPurchase: (Activity, String) -> Unit
) {
    Surface(
        shape = MaterialTheme.shapes.medium,
        tonalElevation = 1.dp,
        color = MaterialTheme.colorScheme.surfaceVariant,
        modifier = Modifier
            .fillMaxWidth()
            .testTag(TestTags.Settings.donationProduct(product.productId))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = product.title,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = product.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }

            when {
                isPurchasing -> CircularProgressIndicator(modifier = Modifier.size(24.dp))
                isCurrent -> AssistChip(
                    onClick = {},
                    label = { Text(stringResource(R.string.donate_current)) },
                    leadingIcon = {
                        Icon(
                            imageVector = Icons.Default.Check,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                )
                else -> Button(
                    enabled = activity != null,
                    onClick = {
                        val currentActivity = activity ?: return@Button
                        onPurchase(currentActivity, product.productId)
                    }
                ) {
                    Text(product.formattedPrice)
                }
            }
        }
    }
}

private tailrec fun Context.findActivity(): Activity? {
    return when (this) {
        is Activity -> this
        is ContextWrapper -> baseContext.findActivity()
        else -> null
    }
}
