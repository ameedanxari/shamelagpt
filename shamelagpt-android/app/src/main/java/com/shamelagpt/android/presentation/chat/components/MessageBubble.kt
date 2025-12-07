package com.shamelagpt.android.presentation.chat.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.widget.Toast
import androidx.compose.animation.core.*
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
import com.shamelagpt.android.core.util.BiDirectionalText
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.model.Source
import java.text.SimpleDateFormat
import java.util.*

/**
 * Message bubble component that displays a single chat message.
 *
 * @param message Message to display
 * @param modifier Modifier for the bubble
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MessageBubble(
    message: Message,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    var showContextMenu by remember { mutableStateOf(false) }

    // Format timestamp
    val timeText = remember(message.timestamp) {
        val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())
        formatter.format(Date(message.timestamp))
    }

    // Alignment: User messages on the end (right in LTR), AI messages on the start
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp),
        contentAlignment = if (message.isUserMessage) Alignment.CenterEnd else Alignment.CenterStart
    ) {
        Column(
            horizontalAlignment = if (message.isUserMessage) Alignment.End else Alignment.Start
        ) {
            // Message bubble
            Surface(
                modifier = Modifier
                    .widthIn(max = 300.dp)
                    .combinedClickable(
                        onClick = { },
                        onLongClick = { showContextMenu = true }
                    ),
                shape = RoundedCornerShape(16.dp),
                color = if (message.isUserMessage) {
                    MaterialTheme.colorScheme.primary
                } else {
                    MaterialTheme.colorScheme.surfaceVariant
                },
                tonalElevation = 1.dp
            ) {
                Column(modifier = Modifier.padding(12.dp)) {
                    // Image thumbnail for fact-check messages
                    if (message.isFactCheckMessage && message.imageData != null) {
                        val bitmap = remember(message.imageData) {
                            BitmapFactory.decodeByteArray(
                                message.imageData,
                                0,
                                message.imageData.size
                            )
                        }
                        if (bitmap != null) {
                            Image(
                                bitmap = bitmap.asImageBitmap(),
                                contentDescription = "Fact-check image",
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .heightIn(max = 120.dp)
                                    .clip(RoundedCornerShape(8.dp)),
                                contentScale = ContentScale.Fit
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                        }
                    }

                    // Language indicator for fact-check messages
                    if (message.isFactCheckMessage && message.detectedLanguage != null) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(bottom = 4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Translate,
                                contentDescription = null,
                                modifier = Modifier.size(14.dp),
                                tint = if (message.isUserMessage) {
                                    MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.7f)
                                } else {
                                    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                                }
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = getLanguageDisplayName(message.detectedLanguage),
                                style = MaterialTheme.typography.labelSmall,
                                color = if (message.isUserMessage) {
                                    MaterialTheme.colorScheme.onPrimary.copy(alpha = 0.7f)
                                } else {
                                    MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                                }
                            )
                        }
                    }

                    // Message text
                    if (message.isUserMessage) {
                        // User messages: bidirectional text support
                        BiDirectionalText(
                            text = message.content,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                    } else {
                        // AI messages: bidirectional text support
                        BiDirectionalText(
                            text = message.content,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Timestamp
            Text(
                text = timeText,
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp, start = 8.dp, end = 8.dp)
            )

            // Sources (only for AI messages)
            if (!message.isUserMessage && !message.sources.isNullOrEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                SourcesList(sources = message.sources)
            }
        }
    }

    // Context menu
    if (showContextMenu) {
        DropdownMenu(
            expanded = showContextMenu,
            onDismissRequest = { showContextMenu = false }
        ) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.copy)) },
                onClick = {
                    copyToClipboard(context, message.content)
                    Toast.makeText(
                        context,
                        context.getString(R.string.copied),
                        Toast.LENGTH_SHORT
                    ).show()
                    showContextMenu = false
                }
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.share)) },
                onClick = {
                    shareMessage(context, message.content)
                    showContextMenu = false
                }
            )
        }
    }
}

/**
 * Displays a list of sources as clickable links.
 *
 * @param sources List of sources to display
 */
@Composable
private fun SourcesList(sources: List<Source>) {
    Column(
        modifier = Modifier
            .widthIn(max = 300.dp)
            .padding(start = 8.dp)
    ) {
        Text(
            text = stringResource(R.string.sources),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(bottom = 4.dp)
        )
        sources.forEach { source ->
            TextButton(
                onClick = { /* TODO: Open source URL */ },
                modifier = Modifier.fillMaxWidth(),
                contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
            ) {
                Text(
                    text = source.bookName,
                    style = MaterialTheme.typography.bodySmall,
                    // Use tertiary (amber) color for source links per website design
                    color = MaterialTheme.colorScheme.tertiary,
                    textAlign = TextAlign.Start,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

/**
 * Copies text to clipboard.
 */
private fun copyToClipboard(context: Context, text: String) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    val clip = ClipData.newPlainText("Message", text)
    clipboard.setPrimaryClip(clip)
}

/**
 * Shares text using Android's share sheet.
 */
private fun shareMessage(context: Context, text: String) {
    val sendIntent = Intent().apply {
        action = Intent.ACTION_SEND
        putExtra(Intent.EXTRA_TEXT, text)
        type = "text/plain"
    }
    val shareIntent = Intent.createChooser(sendIntent, null)
    context.startActivity(shareIntent)
}

/**
 * Returns a display name for the language code.
 */
private fun getLanguageDisplayName(languageCode: String): String {
    return when (languageCode) {
        "ar" -> "Arabic"
        "en" -> "English"
        else -> languageCode.uppercase()
    }
}
