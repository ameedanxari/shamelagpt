package com.shamelagpt.android.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.foundation.clickable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.core.util.DonationLinkHandler
import com.shamelagpt.android.presentation.settings.components.SettingsItem
import com.shamelagpt.android.presentation.settings.components.SettingsSectionHeader
import androidx.compose.ui.res.stringResource
import com.shamelagpt.android.R
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    isAuthenticated: Boolean,
    onNavigateToLanguage: () -> Unit,
    onNavigateToAuth: () -> Unit,
    onLogout: () -> Unit,
    viewModel: SettingsViewModel = koinViewModel(),
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val selectedLanguage by viewModel.selectedLanguage.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface,
                    titleContentColor = MaterialTheme.colorScheme.onSurface
                )
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentPadding = PaddingValues(vertical = 8.dp)
        ) {
            // General Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.settings_general))
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.settings_language),
                    subtitle = getLanguageDisplayName(selectedLanguage),
                    icon = Icons.Default.Language,
                    onClick = onNavigateToLanguage
                )
            }

            item {
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Preferences Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.settings_ai_preferences))
            }

            if (isAuthenticated) {
                item {
                    SettingsItem(
                        title = "Custom system prompt",
                        subtitle = viewModel.customPrompt.collectAsState().value.ifBlank { "Optional" },
                        icon = Icons.Default.Tune,
                        onClick = { }
                    )
                }

                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp)
                    ) {
                        OutlinedTextField(
                            value = viewModel.customPrompt.collectAsState().value,
                            onValueChange = viewModel::updateCustomPrompt,
                            label = { Text("Custom system prompt") },
                            modifier = Modifier.fillMaxWidth()
                        )
                        Spacer(modifier = Modifier.height(8.dp))

                        // List-based selectors for response preferences
                        val responsePrefs = viewModel.responsePreferences.collectAsState().value
                        var showLengthDialog by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }
                        var showStyleDialog by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }
                        var showFocusDialog by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }

                        SettingsItem(
                            title = "Preferred length",
                            subtitle = responsePrefs.length?.let { it.capitalize() } ?: "Not set",
                            icon = Icons.Default.ShortText,
                            onClick = { showLengthDialog = true }
                        )

                        SettingsItem(
                            title = "Style",
                            subtitle = responsePrefs.style?.let { it.capitalize() } ?: "Not set",
                            icon = Icons.Default.FormatPaint,
                            onClick = { showStyleDialog = true }
                        )

                        SettingsItem(
                            title = "Focus",
                            subtitle = responsePrefs.focus?.let { it.capitalize() } ?: "Not set",
                            icon = Icons.Default.FilterList,
                            onClick = { showFocusDialog = true }
                        )

                        Spacer(modifier = Modifier.height(12.dp))
                        Button(
                            onClick = { viewModel.savePreferences() },
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Save preferences")
                        }

                        // Dialogs
                        if (showLengthDialog) {
                            val options = listOf("short" to "Short", "medium" to "Medium", "detailed" to "Detailed")
                            AlertDialog(
                                onDismissRequest = { showLengthDialog = false },
                                title = { Text("Preferred length") },
                                text = {
                                    Column {
                                        options.forEach { (value, label) ->
                                            ListItem(
                                                headlineText = { Text(label) },
                                                modifier = Modifier.clickable {
                                                    viewModel.updateResponsePreferences(value, responsePrefs.style, responsePrefs.focus)
                                                    // Persist immediately
                                                    viewModel.savePreferences()
                                                    showLengthDialog = false
                                                }
                                            )
                                        }
                                    }
                                },
                                confirmButton = {},
                                dismissButton = {}
                            )
                        }

                        if (showStyleDialog) {
                            val options = listOf("conversational" to "Conversational", "formal" to "Formal", "technical" to "Technical")
                            AlertDialog(
                                onDismissRequest = { showStyleDialog = false },
                                title = { Text("Style") },
                                text = {
                                    Column {
                                        options.forEach { (value, label) ->
                                            ListItem(
                                                headlineText = { Text(label) },
                                                modifier = Modifier.clickable {
                                                    viewModel.updateResponsePreferences(responsePrefs.length, value, responsePrefs.focus)
                                                    viewModel.savePreferences()
                                                    showStyleDialog = false
                                                }
                                            )
                                        }
                                    }
                                },
                                confirmButton = {},
                                dismissButton = {}
                            )
                        }

                        if (showFocusDialog) {
                            val options = listOf("practical" to "Practical", "theoretical" to "Theoretical", "historical" to "Historical")
                            AlertDialog(
                                onDismissRequest = { showFocusDialog = false },
                                title = { Text("Focus") },
                                text = {
                                    Column {
                                        options.forEach { (value, label) ->
                                            ListItem(
                                                headlineText = { Text(label) },
                                                modifier = Modifier.clickable {
                                                    viewModel.updateResponsePreferences(responsePrefs.length, responsePrefs.style, value)
                                                    viewModel.savePreferences()
                                                    showFocusDialog = false
                                                }
                                            )
                                        }
                                    }
                                },
                                confirmButton = {},
                                dismissButton = {}
                            )
                        }
                    }
                }
            } else {
                // Guest View - Locked State
                item {
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
                        )
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalAlignment = Alignment.Start
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Lock,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = stringResource(R.string.settings_ai_preferences_locked_title),
                                    style = MaterialTheme.typography.titleMedium,
                                    color = MaterialTheme.colorScheme.onSurface
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                text = stringResource(R.string.settings_ai_preferences_locked_message),
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            Button(
                                onClick = onNavigateToAuth,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Login,
                                    contentDescription = null,
                                    modifier = Modifier.size(18.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(stringResource(R.string.settings_sign_in_button))
                            }
                        }
                    }
                }
            }

            // Support Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.settings_support))
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.settings_support_shamelagpt),
                    subtitle = "Help us keep this project running",
                    icon = Icons.Default.Favorite,
                    onClick = {
                        DonationLinkHandler.openDonationLink(context)
                    }
                )
            }

            item {
                Spacer(modifier = Modifier.height(16.dp))
            }

            // About Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.settings_about))
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.settings_about_shamelagpt),
                    icon = Icons.Default.Info,
                    onClick = {
                        // TODO: Navigate to About screen
                    }
                )
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.settings_privacy_policy),
                    icon = Icons.Default.PrivacyTip,
                    onClick = {
                        DonationLinkHandler.openUrl(context, "https://shamelagpt.com/privacy")
                    }
                )
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.settings_terms_of_service),
                    icon = Icons.Default.Description,
                    onClick = {
                        DonationLinkHandler.openUrl(context, "https://shamelagpt.com/terms")
                    }
                )
            }

            item {
                Spacer(modifier = Modifier.height(24.dp))
            }

            // Footer
            item {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "${stringResource(R.string.settings_version)} 1.0.0",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
                    )
                }
            }

            if (isAuthenticated) {
                item {
                    SettingsItem(
                        title = "Sign out",
                        icon = Icons.Default.ExitToApp,
                        onClick = {
                            viewModel.logout(
                                onLoggedOut = onLogout,
                                onError = { /* Ignore for now, could show toast */ }
                            )
                        }
                    )
                }
            }
        }
    }
}

/**
 * Get display name for language code
 */
private fun getLanguageDisplayName(languageCode: String): String {
    return when (languageCode) {
        "en" -> "English"
        "ar" -> "العربية"
        else -> "English"
    }
}
