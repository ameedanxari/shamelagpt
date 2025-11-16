package com.shamelagpt.android.presentation.settings

import androidx.compose.foundation.layout.*
import androidx.compose.material3.ScaffoldDefaults

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
import com.shamelagpt.android.core.util.EmailIntentHelper
import com.shamelagpt.android.presentation.common.TestTags
import com.shamelagpt.android.presentation.settings.components.SettingsItem
import com.shamelagpt.android.presentation.settings.components.SettingsSectionHeader
import androidx.compose.ui.res.stringResource
import com.shamelagpt.android.R
import com.shamelagpt.android.BuildConfig
import org.koin.androidx.compose.koinViewModel

import androidx.compose.ui.platform.testTag

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    isAuthenticated: Boolean,
    onNavigateToLanguage: () -> Unit,
    onNavigateToAbout: () -> Unit,
    onNavigateToAuth: () -> Unit,
    onLogout: () -> Unit,
    viewModel: SettingsViewModel = koinViewModel(),
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val selectedLanguage by viewModel.selectedLanguage.collectAsState()
    val isAuthenticatedState by viewModel.isAuthenticated.collectAsState()
    var showLogoutDialog by remember { mutableStateOf(false) }


    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    titleContentColor = MaterialTheme.colorScheme.onPrimary
                )
            )
        },
        contentWindowInsets = ScaffoldDefaults.contentWindowInsets.exclude(WindowInsets.navigationBars)
    ) { paddingValues ->

        LazyColumn(
            modifier = modifier
                .testTag(TestTags.Settings.List)
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
                    onClick = onNavigateToLanguage,
                    modifier = Modifier.testTag(TestTags.Settings.LanguageItem)
                )
            }

            item {
                Spacer(modifier = Modifier.height(16.dp))
            }

            // Preferences Section
            item {
                SettingsSectionHeader(title = stringResource(R.string.settings_ai_preferences))
            }

            if (isAuthenticatedState) {

                item {
                    SettingsItem(
                        title = stringResource(R.string.settings_custom_prompt),
                        subtitle = viewModel.customPrompt.collectAsState().value.ifBlank { stringResource(R.string.settings_custom_prompt_optional) },
                        icon = Icons.Default.Tune,
                        onClick = { },
                         modifier = Modifier.testTag(TestTags.Settings.CustomPromptItem)
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
                            label = { Text(stringResource(R.string.settings_custom_prompt)) },
                            modifier = Modifier.fillMaxWidth().testTag(TestTags.Settings.CustomPromptTextField)
                        )
                        Spacer(modifier = Modifier.height(8.dp))

                        // List-based selectors for response preferences
                        val responsePrefs = viewModel.responsePreferences.collectAsState().value
                        var showLengthDialog by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }
                        var showStyleDialog by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }
                        var showFocusDialog by androidx.compose.runtime.remember { androidx.compose.runtime.mutableStateOf(false) }



                        val notSetText = stringResource(R.string.settings_not_set)
                        val shortText = stringResource(R.string.settings_pref_length_short)
                        val mediumText = stringResource(R.string.settings_pref_length_medium)
                        val detailedText = stringResource(R.string.settings_pref_length_detailed)
                        val conversationalText = stringResource(R.string.settings_pref_style_conversational)
                        val academicText = stringResource(R.string.settings_pref_style_academic)
                        val technicalText = stringResource(R.string.settings_pref_style_technical)
                        val practicalText = stringResource(R.string.settings_pref_focus_practical)
                        val theoreticalText = stringResource(R.string.settings_pref_focus_theoretical)
                        val historicalText = stringResource(R.string.settings_pref_focus_historical)

                        SettingsItem(
                            title = stringResource(R.string.settings_pref_length_title),
                            subtitle = responsePrefs.length?.let { 
                                when(it.lowercase()) {
                                    "short" -> shortText
                                    "medium" -> mediumText
                                    "detailed" -> detailedText
                                    else -> it.replaceFirstChar { char -> if (char.isLowerCase()) char.titlecase() else char.toString() }
                                }
                            } ?: notSetText,
                            icon = Icons.Default.ShortText,
                            onClick = { showLengthDialog = true },
                            modifier = Modifier.testTag(TestTags.Settings.LengthItem)
                        )

                        SettingsItem(
                            title = stringResource(R.string.settings_pref_style_title),
                            subtitle = responsePrefs.style?.let { 
                                when(it.lowercase()) {
                                    "conversational" -> conversationalText
                                    "academic" -> academicText
                                    "technical" -> technicalText
                                    else -> it.replaceFirstChar { char -> if (char.isLowerCase()) char.titlecase() else char.toString() }
                                }
                            } ?: notSetText,
                            icon = Icons.Default.FormatPaint,
                            onClick = { showStyleDialog = true },
                            modifier = Modifier.testTag(TestTags.Settings.StyleItem)
                        )

                        SettingsItem(
                            title = stringResource(R.string.settings_pref_focus_title),
                            subtitle = responsePrefs.focus?.let { 
                                when(it.lowercase()) {
                                    "practical" -> practicalText
                                    "theoretical" -> theoreticalText
                                    "historical" -> historicalText
                                    else -> it.replaceFirstChar { char -> if (char.isLowerCase()) char.titlecase() else char.toString() }
                                }
                            } ?: notSetText,
                            icon = Icons.Default.FilterList,
                            onClick = { showFocusDialog = true },
                            modifier = Modifier.testTag(TestTags.Settings.FocusItem)
                        )

                        Spacer(modifier = Modifier.height(12.dp))
                        Button(
                            onClick = { viewModel.savePreferences() },
                            modifier = Modifier.fillMaxWidth().testTag(TestTags.Settings.SavePreferencesButton)
                        ) {
                            Text(stringResource(R.string.settings_save_preferences))
                        }

                        // Dialogs
                        if (showLengthDialog) {
                            val options = listOf("short" to shortText, "medium" to mediumText, "detailed" to detailedText)
                            AlertDialog(
                                onDismissRequest = { showLengthDialog = false },
                                title = { Text(stringResource(R.string.settings_pref_length_title)) },
                                text = {
                                    Column {
                                        options.forEach { (value, label) ->
                                            ListItem(
                                                headlineContent = { Text(label) },
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
                            val options = listOf("conversational" to conversationalText, "academic" to academicText, "technical" to technicalText)
                            AlertDialog(
                                onDismissRequest = { showStyleDialog = false },
                                title = { Text(stringResource(R.string.settings_pref_style_title)) },
                                text = {
                                    Column {
                                        options.forEach { (value, label) ->
                                            ListItem(
                                                headlineContent = { Text(label) },
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
                            val options = listOf("practical" to practicalText, "theoretical" to theoreticalText, "historical" to historicalText)
                            AlertDialog(
                                onDismissRequest = { showFocusDialog = false },
                                title = { Text(stringResource(R.string.settings_pref_focus_title)) },
                                text = {
                                    Column {
                                        options.forEach { (value, label) ->
                                            ListItem(
                                                headlineContent = { Text(label) },
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

                        // Logout Confirmation Dialog
                        if (showLogoutDialog) {
                            AlertDialog(
                                onDismissRequest = { showLogoutDialog = false },
                                title = { Text(stringResource(R.string.sign_out_confirmation_title)) },
                                text = { Text(stringResource(R.string.sign_out_confirmation_message)) },
                                confirmButton = {
                                    Button(
                                        onClick = {
                                            showLogoutDialog = false
                                            viewModel.logout(
                                                onLoggedOut = {
                                                    // Do not navigate away, just refresh UI
                                                },
                                                onError = { /* Ignore for now */ }
                                            )
                                        },
                                        colors = ButtonDefaults.buttonColors(
                                            containerColor = MaterialTheme.colorScheme.error
                                        )
                                    ) {
                                        Text(stringResource(R.string.settings_sign_out))
                                    }
                                },
                                dismissButton = {
                                    TextButton(onClick = { showLogoutDialog = false }) {
                                        Text(stringResource(R.string.common_cancel))
                                    }
                                }
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
                                modifier = Modifier.fillMaxWidth().testTag(TestTags.Settings.SignInButton)
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
                    subtitle = stringResource(R.string.settings_support_subtitle),
                    icon = Icons.Default.Favorite,
                    onClick = {
                        DonationLinkHandler.openDonationLink(context)
                    },
                    modifier = Modifier.testTag(TestTags.Settings.SupportItem)
                )
            }

            item {
                SettingsItem(
                    title = stringResource(R.string.send_feedback),
                    icon = Icons.Default.Email,
                    onClick = { EmailIntentHelper.openFeedbackEmail(context) }
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
                        onNavigateToAbout()
                    },
                    modifier = Modifier.testTag(TestTags.Settings.AboutItem)
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
                AppInfoFooter()
            }

            if (isAuthenticatedState) {

                item {
                    SettingsItem(
                        title = stringResource(R.string.settings_sign_out),
                        icon = Icons.Default.ExitToApp,
                        iconTint = MaterialTheme.colorScheme.error,
                        textColor = MaterialTheme.colorScheme.error,
                        onClick = {
                            showLogoutDialog = true
                        },
                        modifier = Modifier.testTag(TestTags.Settings.LogoutItem)
                    )

                }
            }
        }
    }
}

@Composable
private fun AppInfoFooter() {
    val version = BuildConfig.VERSION_NAME.ifBlank { "–" }
    val build = BuildConfig.VERSION_CODE
    val display = if (build > 0) "$version ($build)" else version

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = "${stringResource(R.string.settings_version)} $display",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}

/**
 * Get display name for language code
 */
@Composable
private fun getLanguageDisplayName(languageCode: String): String {
    return when (languageCode.trim().lowercase()) {
        "en" -> stringResource(R.string.english)
        "english" -> stringResource(R.string.english)
        "ar" -> stringResource(R.string.arabic)
        "arabic" -> stringResource(R.string.arabic)
        "ur" -> stringResource(R.string.urdu)
        "urdu" -> stringResource(R.string.urdu)
        else -> stringResource(R.string.english)
    }
}
