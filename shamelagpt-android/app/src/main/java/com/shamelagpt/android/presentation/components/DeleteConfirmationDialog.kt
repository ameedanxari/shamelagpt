package com.shamelagpt.android.presentation.components

import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

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
    modifier: Modifier = Modifier
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Delete Conversation?")
        },
        text = {
            Text(text = "This action cannot be undone.")
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
                Text("Delete")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        },
        modifier = modifier
    )
}
