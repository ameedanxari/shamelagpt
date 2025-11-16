package com.shamelagpt.android.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.core.util.DonationLinkHandler
import com.shamelagpt.android.presentation.settings.components.SettingsItem
import com.shamelagpt.android.presentation.settings.components.SettingsSectionHeader
import org.koin.androidx.compose.koinViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateToLanguage: () -> Unit,
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
                SettingsSectionHeader(title = "General")
            }

            item {
                SettingsItem(
                    title = "Language",
                    subtitle = getLanguageDisplayName(selectedLanguage),
                    icon = Icons.Default.Language,
                    onClick = onNavigateToLanguage
                )
            }

            item {
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Support Section
            item {
                SettingsSectionHeader(title = "Support")
            }

            item {
                SettingsItem(
                    title = "❤️ Support ShamelaGPT",
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
                SettingsSectionHeader(title = "About")
            }

            item {
                SettingsItem(
                    title = "About ShamelaGPT",
                    icon = Icons.Default.Info,
                    onClick = {
                        // TODO: Navigate to About screen
                    }
                )
            }

            item {
                SettingsItem(
                    title = "Privacy Policy",
                    icon = Icons.Default.PrivacyTip,
                    onClick = {
                        // TODO: Open Privacy Policy URL
                        DonationLinkHandler.openUrl(context, "https://shamelagpt.com/privacy")
                    }
                )
            }

            item {
                SettingsItem(
                    title = "Terms of Service",
                    icon = Icons.Default.Description,
                    onClick = {
                        // TODO: Open Terms of Service URL
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
                        text = "Version 1.0.0",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center
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
