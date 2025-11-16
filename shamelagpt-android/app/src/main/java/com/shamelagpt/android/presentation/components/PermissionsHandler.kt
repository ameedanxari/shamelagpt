package com.shamelagpt.android.presentation.components

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalContext
import androidx.core.content.ContextCompat

/**
 * Composable function to handle runtime permissions with dialogs and rationale.
 *
 * @param permission The permission to request
 * @param rationaleTitle Title for the rationale dialog
 * @param rationaleMessage Message explaining why the permission is needed
 * @param onPermissionResult Callback invoked with the permission result
 */
@Composable
fun PermissionHandler(
    permission: String,
    rationaleTitle: String,
    rationaleMessage: String,
    onPermissionResult: (Boolean) -> Unit
) {
    val context = LocalContext.current
    var showRationale by remember { mutableStateOf(false) }
    var showSettingsDialog by remember { mutableStateOf(false) }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            onPermissionResult(true)
        } else {
            // Check if we should show rationale or if permission is permanently denied
            showSettingsDialog = true
            onPermissionResult(false)
        }
    }

    // Check current permission status
    LaunchedEffect(permission) {
        when {
            ContextCompat.checkSelfPermission(
                context,
                permission
            ) == PackageManager.PERMISSION_GRANTED -> {
                onPermissionResult(true)
            }
            else -> {
                showRationale = true
            }
        }
    }

    // Rationale dialog
    if (showRationale) {
        AlertDialog(
            onDismissRequest = {
                showRationale = false
                onPermissionResult(false)
            },
            title = { Text(rationaleTitle) },
            text = { Text(rationaleMessage) },
            confirmButton = {
                TextButton(
                    onClick = {
                        showRationale = false
                        permissionLauncher.launch(permission)
                    }
                ) {
                    Text("Grant Permission")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showRationale = false
                        onPermissionResult(false)
                    }
                ) {
                    Text("Cancel")
                }
            }
        )
    }

    // Settings dialog (for permanently denied permissions)
    if (showSettingsDialog) {
        AlertDialog(
            onDismissRequest = {
                showSettingsDialog = false
            },
            title = { Text("Permission Required") },
            text = { Text("This permission was denied. Please enable it in app settings to use this feature.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showSettingsDialog = false
                        openAppSettings(context)
                    }
                ) {
                    Text("Open Settings")
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showSettingsDialog = false
                    }
                ) {
                    Text("Cancel")
                }
            }
        )
    }
}

/**
 * Composable to request microphone permission.
 */
@Composable
fun RequestMicrophonePermission(
    onPermissionResult: (Boolean) -> Unit
) {
    PermissionHandler(
        permission = Manifest.permission.RECORD_AUDIO,
        rationaleTitle = "Microphone Permission",
        rationaleMessage = "Microphone permission is required for voice input. This allows you to dictate your questions using speech.",
        onPermissionResult = onPermissionResult
    )
}

/**
 * Opens the app settings page.
 */
private fun openAppSettings(context: Context) {
    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.fromParts("package", context.packageName, null)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK
    }
    context.startActivity(intent)
}

/**
 * Checks if a permission is granted.
 */
fun Context.isPermissionGranted(permission: String): Boolean {
    return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
}
