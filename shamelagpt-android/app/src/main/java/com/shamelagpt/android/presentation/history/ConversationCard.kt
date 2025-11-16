package com.shamelagpt.android.presentation.history

import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudDone
import androidx.compose.material.icons.filled.FactCheck
import androidx.compose.material.icons.filled.OfflineBolt
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.core.util.formatRelativeTimestamp
import com.shamelagpt.android.data.local.entity.ConversationType
import com.shamelagpt.android.domain.model.Conversation
import com.shamelagpt.android.R

/**
 * Card component for displaying a conversation in the history list.
 *
 * Features:
 * - Title (bold, 1 line, ellipsis)
 * - Last message preview (2 lines, gray, ellipsis)
 * - Relative timestamp (e.g., "2 hours ago")
 * - Conversation badges (fact-check + local/server)
 * - Long-press context menu for share
 *
 * @param conversation Conversation to display
 * @param title Display title (already normalized/fallback-resolved)
 * @param preview Display preview text
 * @param onClick Callback when card is clicked
 * @param onShareClick Callback when share action is selected
 * @param modifier Modifier for the card
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ConversationCard(
    conversation: Conversation,
    title: String,
    preview: String,
    onClick: () -> Unit,
    onShareClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val appLocale = LocalContext.current.resources.configuration.locales[0]
    var showMenu by remember { mutableStateOf(false) }
    Card(
        modifier = modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = onClick,
                onLongClick = { showMenu = true }
            ),
        shape = RoundedCornerShape(12.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Content (title, preview, timestamp)
            Column(
                modifier = Modifier.weight(1f)
            ) {
                // Title with fact-check badge
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.weight(1f, fill = false)
                    )

                    // Fact-check badge
                    if (conversation.conversationType == ConversationType.FACT_CHECK) {
                        Surface(
                            shape = RoundedCornerShape(4.dp),
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
                        ) {
                            Row(
                                modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(4.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.FactCheck,
                                    contentDescription = null,
                                    modifier = Modifier.size(12.dp),
                                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                                Text(
                                    text = stringResource(id = R.string.history_fact_check_badge),
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }

                    if (conversation.isLocalOnly) {
                        SourceBadge(conversation = conversation)
                    }
                }

                Spacer(modifier = Modifier.height(4.dp))

                // Last message preview
                Text(
                    text = preview,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )

                Spacer(modifier = Modifier.height(4.dp))

                // Timestamp
                Text(
                    text = formatRelativeTimestamp(conversation.updatedAt, appLocale),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
            }

            Spacer(modifier = Modifier.width(4.dp))
        }

        DropdownMenu(
            expanded = showMenu,
            onDismissRequest = { showMenu = false }
        ) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.common_share)) },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Default.Share,
                        contentDescription = null
                    )
                },
                onClick = {
                    showMenu = false
                    onShareClick()
                }
            )
        }
    }
}

@Composable
private fun SourceBadge(conversation: Conversation) {
    val (textRes, icon, tint) = if (conversation.isLocalOnly) {
        Triple(
            R.string.history_local_only_badge,
            Icons.Default.OfflineBolt,
            MaterialTheme.colorScheme.secondary
        )
    } else {
        // Server-synced is considered the default state and does not require a badge.
        return
    }

    Surface(
        shape = RoundedCornerShape(4.dp),
        color = tint.copy(alpha = 0.12f)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(11.dp),
                tint = tint
            )
            Text(
                text = stringResource(textRes),
                style = MaterialTheme.typography.labelSmall,
                color = tint
            )
        }
    }
}
