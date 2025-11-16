package com.shamelagpt.android.presentation.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.core.util.LanguageManager
import org.koin.androidx.compose.koinViewModel

data class Language(
    val code: String,
    val displayName: String
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LanguageSelectionScreen(
    onNavigateBack: () -> Unit,
    viewModel: SettingsViewModel = koinViewModel(),
    modifier: Modifier = Modifier
) {
    val selectedLanguage by viewModel.selectedLanguage.collectAsState()

    val languages = listOf(
        Language(LanguageManager.LANGUAGE_ENGLISH, "English"),
        Language(LanguageManager.LANGUAGE_ARABIC, "العربية")
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Select Language") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
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
            items(languages) { language ->
                LanguageItem(
                    language = language,
                    isSelected = language.code == selectedLanguage,
                    onSelect = {
                        viewModel.updateLanguage(language.code)
                        // Automatically navigate back after selection
                        onNavigateBack()
                    }
                )
            }
        }
    }
}

@Composable
private fun LanguageItem(
    language: Language,
    isSelected: Boolean,
    onSelect: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onSelect),
        color = if (isSelected) {
            MaterialTheme.colorScheme.primaryContainer
        } else {
            MaterialTheme.colorScheme.surface
        }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            RadioButton(
                selected = isSelected,
                onClick = onSelect,
                colors = RadioButtonDefaults.colors(
                    selectedColor = MaterialTheme.colorScheme.primary
                )
            )

            Spacer(modifier = Modifier.width(16.dp))

            Text(
                text = language.displayName,
                style = MaterialTheme.typography.bodyLarge,
                color = if (isSelected) {
                    MaterialTheme.colorScheme.onPrimaryContainer
                } else {
                    MaterialTheme.colorScheme.onSurface
                }
            )
        }
    }
}
