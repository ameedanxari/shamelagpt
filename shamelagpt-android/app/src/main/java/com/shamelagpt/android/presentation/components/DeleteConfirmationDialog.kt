package com.shamelagpt.android.presentation.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import com.shamelagpt.android.R

/**
 * Dialog for confirming conversation deletion.
 *
 * @param onConfirm Callback when delete is confirmed
 * @param onDismiss Callback when dialog is dismissed or cancelled
 * @param modifier Modifier for the dialog
 */
@Composable
fun DeleteConfirmationDialog(
    onConfirm: () -> Unit,
    onDismiss: () -> Unit,
    conversationTitle: String? = null,
    modifier: Modifier = Modifier
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = stringResource(R.string.delete_conversation))
        },
        text = {
            if (conversationTitle != null) {
                Text(text = stringResource(R.string.delete_confirmation_with_title, conversationTitle))
            } else {
                Text(text = stringResource(R.string.delete_confirmation))
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onConfirm()
                    onDismiss()
                },
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text(stringResource(R.string.common_delete))
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text(stringResource(R.string.common_cancel))
            }
        },
        modifier = modifier
    )
}
