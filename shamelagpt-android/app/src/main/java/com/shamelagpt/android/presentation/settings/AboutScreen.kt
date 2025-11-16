package com.shamelagpt.android.presentation.settings

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.TextButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
import com.shamelagpt.android.core.util.DonationLinkHandler

/**
 * About screen displaying mission, vision, and goal content.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AboutScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier
) {
    val missionPoints = listOf(
        stringResource(R.string.about_mission_point_support),
        stringResource(R.string.about_mission_point_combat_misinformation),
        stringResource(R.string.about_mission_point_ethical_ai),
        stringResource(R.string.about_mission_point_preserve_trust)
    )

    val visionPoints = listOf(
        stringResource(R.string.about_vision_point_sources),
        stringResource(R.string.about_vision_point_verifiable),
        stringResource(R.string.about_vision_point_underrepresented),
        stringResource(R.string.about_vision_point_children),
        stringResource(R.string.about_vision_point_developers)
    )

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.settings_about_shamelagpt)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = stringResource(R.string.back)
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
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Section(
                    title = stringResource(R.string.settings_about_shamelagpt),
                    body = stringResource(R.string.about_shamelagpt_intro)
                )
            }

            item {
                Section(
                    title = stringResource(R.string.about_mission_title),
                    body = stringResource(R.string.about_mission),
                    bullets = missionPoints
                )
            }

            item {
                Section(
                    title = stringResource(R.string.about_vision_title),
                    body = stringResource(R.string.about_vision_intro),
                    bullets = visionPoints
                )
            }

            item {
                Section(
                    title = stringResource(R.string.about_goal_title),
                    body = stringResource(R.string.about_goal)
                )
            }

            item {
                Section(
                    title = stringResource(R.string.about_data_source_title),
                    body = stringResource(R.string.about_data_source)
                )
            }

            item {
                Section(
                    title = stringResource(R.string.about_data_handling_title),
                    body = stringResource(R.string.about_data_handling)
                )
            }

            item {
                CompanySection()
            }
        }
    }
}

@Composable
private fun Section(
    title: String,
    body: String,
    bullets: List<String> = emptyList(),
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )

        Text(
            text = body,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        if (bullets.isNotEmpty()) {
            BulletList(items = bullets)
        }
    }
}

@Composable
private fun CompanySection(
    modifier: Modifier = Modifier
) {
    val companyUrl = "https://neurallines.com/"
    val context = LocalContext.current

    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = stringResource(R.string.about_company_title),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )

        Text(
            text = stringResource(R.string.about_company_description),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        TextButton(
            onClick = { DonationLinkHandler.openUrl(context, companyUrl) }
        ) {
            Text(
                text = stringResource(R.string.about_company_link),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun BulletList(
    items: List<String>,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        items.forEach { item ->
            BulletRow(text = item)
        }
    }
}

@Composable
private fun BulletRow(
    text: String,
    modifier: Modifier = Modifier
) {
    androidx.compose.foundation.layout.Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Text(
            text = "-",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.primary
        )
        Text(
            text = text,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}
