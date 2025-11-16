package com.shamelagpt.android.presentation.chat.components

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.text.format.DateFormat
import android.text.format.DateUtils
import android.widget.Toast
import androidx.compose.animation.core.*
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.text.ClickableText
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Translate
import androidx.compose.material3.*
import androidx.compose.material3.Typography
import androidx.compose.material3.surfaceColorAtElevation
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import com.shamelagpt.android.R
import com.shamelagpt.android.core.util.BiDirectionalText
import com.shamelagpt.android.core.util.detectLayoutDirection
import com.shamelagpt.android.core.util.localizeDigits
import com.shamelagpt.android.core.utils.FontUtils
import com.shamelagpt.android.data.remote.ResponseParser
import com.shamelagpt.android.domain.model.Message
import com.shamelagpt.android.domain.model.Source
import com.shamelagpt.android.presentation.common.TestTags
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
    val messageTextColor = if (message.isUserMessage) {
        MaterialTheme.colorScheme.onPrimary
    } else {
        MaterialTheme.colorScheme.onSurfaceVariant
    }
    val displayContent = remember(message.content, message.sources) {
        extractDisplayContent(message)
    }
    val displayedSources = remember(message.content, message.sources) {
        message.sources ?: ResponseParser.parseAnswer(message.content).second
    }
    val messageLines = remember(displayContent) { parseMessageLines(displayContent) }

    // Localized timestamp formatting (aligns with iOS behavior for "today" and avoids hardcoded English labels).
    val appLocale = context.resources.configuration.locales[0]
    val timeText = remember(message.timestamp, appLocale.toLanguageTag()) {
        if (DateUtils.isToday(message.timestamp)) {
            localizeDigits(DateFormat.getTimeFormat(context).format(Date(message.timestamp)), appLocale)
        } else {
            localizeDigits(
                DateUtils.getRelativeTimeSpanString(
                message.timestamp,
                System.currentTimeMillis(),
                DateUtils.DAY_IN_MILLIS,
                DateUtils.FORMAT_ABBREV_RELATIVE
                ).toString(),
                appLocale
            )
        }
    }


    // Alignment: User messages on the end (right in LTR), AI messages on the start
    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 4.dp)
            .testTag(TestTags.Chat.MessageBubble),
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
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null,
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
                    messageLines.forEach { line ->
                        MessageLine(
                            line = line,
                            textColor = messageTextColor
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
            if (!message.isUserMessage && !displayedSources.isNullOrEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                SourcesList(sources = displayedSources!!)
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
                    copyToClipboard(context, shareContent(displayContent, displayedSources))
                    Toast.makeText(
                        context,
                        context.getString(R.string.copied),
                        Toast.LENGTH_SHORT
                    ).show()
                    showContextMenu = false
                }
            )
            DropdownMenuItem(
                text = { Text(stringResource(R.string.common_share)) },
                onClick = {
                    shareMessage(context, shareContent(displayContent, displayedSources))
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
    val uriHandler = LocalUriHandler.current
    
    Surface(
        modifier = Modifier
            .widthIn(max = 300.dp)
            .padding(top = 4.dp),
        color = MaterialTheme.colorScheme.surfaceColorAtElevation(1.dp),
        shape = RoundedCornerShape(12.dp),
        border = androidx.compose.foundation.BorderStroke(
            0.5.dp, 
            MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.3f)
        )
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = stringResource(R.string.sources),
                style = MaterialTheme.typography.labelSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(bottom = 8.dp)
            )
            
            Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
                sources.forEach { source ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(4.dp))
                            .clickable {
                                source.sourceURL?.let { url ->
                                    try {
                                        uriHandler.openUri(url)
                                    } catch (e: Exception) {
                                        // Fallback for malformed URLs
                                    }
                                }
                            }
                            .padding(vertical = 1.dp, horizontal = 4.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(4.dp)
                                .background(MaterialTheme.colorScheme.tertiary, RoundedCornerShape(2.dp))
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = source.citation,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textDecoration = TextDecoration.Underline
                        )
                    }
                }
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

private fun parseMessageLines(text: String): List<ParsedLine> {
    val normalized = normalizeNewlines(text)
    // Use default split behavior (no negative limit) to avoid IllegalArgumentException
    val rawLines = normalized.split("\n")
    val lines = mutableListOf<ParsedLine>()
    var inCodeBlock = false
    val fenceRegex = Regex("^```")

    rawLines.forEach { raw ->
        val isFence = fenceRegex.containsMatchIn(raw.trimStart())
        if (isFence) {
            inCodeBlock = !inCodeBlock
            // Skip rendering the fence markers themselves to keep UI clean
            return@forEach
        }
        lines.add(ParsedLine(text = raw, inCodeBlock = inCodeBlock))
    }

    // If message ends with a trailing newline, preserve an empty line
    if (normalized.endsWith("\n")) {
        lines.add(ParsedLine(text = "", inCodeBlock = inCodeBlock))
    }

    return lines
}

private fun normalizeNewlines(text: String): String {
    return text
        .replace("\\r\\n", "\n")
        .replace("\\n", "\n")
        .replace("\r\n", "\n")
}

@Composable
private fun MessageLine(
    line: ParsedLine,
    textColor: Color
) {
    val uriHandler = LocalUriHandler.current
    val layoutDirection = remember(line) { detectLayoutDirection(line.text) }
    val lineType = remember(line) { detectLineType(line) }
    val typography = MaterialTheme.typography

    CompositionLocalProvider(LocalLayoutDirection provides layoutDirection) {
        when (lineType) {
            is LineType.Empty -> {
                BiDirectionalText(
                    text = " ",
                    style = MaterialTheme.typography.bodyMedium,
                    color = textColor
                )
            }
            is LineType.CodeBlock -> {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 2.dp)
                        .background(
                            color = MaterialTheme.colorScheme.surfaceColorAtElevation(2.dp),
                            shape = RoundedCornerShape(6.dp)
                        )
                        .padding(8.dp)
                ) {
                    Text(
                        text = if (lineType.text.isEmpty()) " " else lineType.text,
                        style = typography.bodyMedium.copy(
                            fontFamily = FontFamily.Monospace,
                            color = textColor
                        )
                    )
                }
            }
            is LineType.Blockquote -> {
                Row(
                    verticalAlignment = Alignment.Top,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier
                        .padding(vertical = 2.dp)
                        .height(IntrinsicSize.Min)
                ) {
                    Box(
                        modifier = Modifier
                            .width(4.dp)
                            .fillMaxHeight()
                            .background(MaterialTheme.colorScheme.outlineVariant, RoundedCornerShape(2.dp))
                    )
                    AnnotatedText(
                        content = lineType.text,
                        style = typography.bodyMedium.copy(fontStyle = FontStyle.Italic),
                        textColor = textColor,
                        onUrlClick = { uriHandler.openUri(it) }
                    )
                }
            }
            is LineType.Heading -> {
                val style = headingTextStyle(lineType.level, typography)
                AnnotatedText(
                    content = lineType.text,
                    style = style,
                    textColor = textColor,
                    onUrlClick = { uriHandler.openUri(it) }
                )
            }
            is LineType.Bullet -> {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    Text(
                        text = "•",
                        style = typography.bodyMedium.copy(color = textColor, fontFamily = fontFamilyFor(lineType.text)),
                        color = textColor
                    )
                    AnnotatedText(
                        content = lineType.text,
                        style = typography.bodyMedium,
                        textColor = textColor,
                        onUrlClick = { uriHandler.openUri(it) }
                    )
                }
            }
            is LineType.Ordered -> {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.Top
                ) {
                    Text(
                        text = "${lineType.index}.",
                        style = typography.bodyMedium.copy(color = textColor, fontFamily = fontFamilyFor(lineType.text)),
                        color = textColor
                    )
                    AnnotatedText(
                        content = lineType.text,
                        style = typography.bodyMedium,
                        textColor = textColor,
                        onUrlClick = { uriHandler.openUri(it) }
                    )
                }
            }
            is LineType.Paragraph -> {
                AnnotatedText(
                    content = lineType.text,
                    style = typography.bodyMedium,
                    textColor = textColor,
                    onUrlClick = { uriHandler.openUri(it) }
                )
            }
        }
    }
}

private fun headingTextStyle(level: Int, typography: Typography): TextStyle {
    return when (level) {
        1 -> typography.titleLarge
        2 -> typography.titleMedium
        3 -> typography.titleSmall
        else -> typography.bodyMedium
    }
}

@Composable
private fun AnnotatedText(
    content: String,
    style: TextStyle,
    textColor: Color,
    onUrlClick: (String) -> Unit
) {
    val linkColor = MaterialTheme.colorScheme.primary
    val codeBackground = MaterialTheme.colorScheme.surfaceColorAtElevation(2.dp)
    val annotated = remember(content, linkColor, codeBackground) {
        buildAnnotatedMarkdownText(content, linkColor, codeBackground)
    }
    val effectiveFont = fontFamilyFor(content)
    ClickableText(
        text = annotated,
        style = style.copy(color = textColor, fontFamily = effectiveFont),
        onClick = { offset ->
            annotated.getStringAnnotations(URL_TAG, offset, offset)
                .firstOrNull()
                ?.let { annotation ->
                    onUrlClick(annotation.item)
                }
        }
    )
}

private fun buildAnnotatedMarkdownText(
    text: String,
    linkColor: Color,
    codeBackground: Color
): AnnotatedString {
    val tokenRegex = Regex(
        "\\[([^\\]]+)]\\(([^\\)]+)\\)" +            // link
            "|`([^`]+)`" +                           // inline code
            "|\\*\\*([^*]+)\\*\\*" +                 // bold **
            "|__([^_]+)__" +                         // bold __
            "|\\*([^*]+)\\*" +                       // italic *
            "|_([^_]+)_" +                           // italic _
            "|~~([^~]+)~~"                           // strikethrough
    )

    return buildAnnotatedString {
        var currentIndex = 0

        tokenRegex.findAll(text).forEach { match ->
            val range = match.range
            if (range.first > currentIndex) {
                append(text.substring(currentIndex, range.first))
            }

            when {
                match.groups[1] != null && match.groups[2] != null -> {
                    val label = match.groupValues[1]
                    val url = match.groupValues[2]
                    val start = length
                    append(label)
                    addStringAnnotation(tag = URL_TAG, annotation = url, start = start, end = start + label.length)
                    addStyle(
                        style = SpanStyle(
                            color = linkColor,
                            textDecoration = TextDecoration.Underline
                        ),
                        start = start,
                        end = start + label.length
                    )
                }
                match.groups[3] != null -> {
                    val code = match.groupValues[3]
                    val start = length
                    append(code)
                    addStyle(
                        style = SpanStyle(
                            fontFamily = FontFamily.Monospace,
                            background = codeBackground
                        ),
                        start = start,
                        end = start + code.length
                    )
                }
                match.groups[4] != null -> {
                    val bold = match.groupValues[4]
                    val start = length
                    append(bold)
                    addStyle(
                        style = SpanStyle(fontWeight = FontWeight.Bold),
                        start = start,
                        end = start + bold.length
                    )
                }
                match.groups[5] != null -> {
                    val bold = match.groupValues[5]
                    val start = length
                    append(bold)
                    addStyle(
                        style = SpanStyle(fontWeight = FontWeight.Bold),
                        start = start,
                        end = start + bold.length
                    )
                }
                match.groups[6] != null -> {
                    val italic = match.groupValues[6]
                    val start = length
                    append(italic)
                    addStyle(
                        style = SpanStyle(fontStyle = FontStyle.Italic),
                        start = start,
                        end = start + italic.length
                    )
                }
                match.groups[7] != null -> {
                    val italic = match.groupValues[7]
                    val start = length
                    append(italic)
                    addStyle(
                        style = SpanStyle(fontStyle = FontStyle.Italic),
                        start = start,
                        end = start + italic.length
                    )
                }
                match.groups[8] != null -> {
                    val strike = match.groupValues[8]
                    val start = length
                    append(strike)
                    addStyle(
                        style = SpanStyle(textDecoration = TextDecoration.LineThrough),
                        start = start,
                        end = start + strike.length
                    )
                }
            }

            currentIndex = range.last + 1
        }

        if (currentIndex < text.length) {
            append(text.substring(currentIndex))
        }
    }
}

private sealed interface LineType {
    object Empty : LineType
    data class CodeBlock(val text: String) : LineType
    data class Blockquote(val text: String) : LineType
    data class Heading(val level: Int, val text: String) : LineType
    data class Bullet(val text: String) : LineType
    data class Ordered(val index: Int, val text: String) : LineType
    data class Paragraph(val text: String) : LineType
}

private fun detectLineType(line: ParsedLine): LineType {
    if (line.text.isEmpty()) return LineType.Empty
    if (line.inCodeBlock) return LineType.CodeBlock(line.text)

    val trimmedStart = line.text.trimStart()

    val headingMatch = Regex("^(#{1,6})\\s+(.*)$").find(trimmedStart)
    if (headingMatch != null) {
        val level = headingMatch.groupValues[1].length
        val text = headingMatch.groupValues[2].trim()
        return LineType.Heading(level = level, text = text)
    }

    val blockquoteMatch = Regex("^>\\s?(.*)$").find(trimmedStart)
    if (blockquoteMatch != null) {
        return LineType.Blockquote(text = blockquoteMatch.groupValues[1].trim())
    }

    val bulletMatch = Regex("^[\\-\\*\\+]\\s+(.*)$").find(trimmedStart)
    if (bulletMatch != null) {
        return LineType.Bullet(text = bulletMatch.groupValues[1].trim())
    }

    val orderedMatch = Regex("^(\\d+)\\.\\s+(.*)$").find(trimmedStart)
    if (orderedMatch != null) {
        val index = orderedMatch.groupValues[1].toIntOrNull() ?: 0
        return LineType.Ordered(index = index, text = orderedMatch.groupValues[2].trim())
    }

    return LineType.Paragraph(text = line.text)
}

@Composable
private fun fontFamilyFor(text: String): FontFamily {
    val context = LocalContext.current
    val appLanguage = context.resources.configuration.locales[0].language.lowercase()
    val detectedLanguage = FontUtils.detectLanguage(text)

    val resolvedLanguage = when {
        detectedLanguage == "ur" -> "ur"
        detectedLanguage == "ar" && appLanguage == "ur" -> "ur"
        else -> detectedLanguage
    }

    return FontUtils.getFontFamilyForLanguage(resolvedLanguage)
}

private fun extractDisplayContent(message: Message): String {
    val base = if (message.isUserMessage) {
        message.content
    } else {
        runCatching { ResponseParser.parseAnswer(message.content).first }
            .getOrDefault(message.content)
    }
    return sanitizeDisplayContent(base)
}

private fun sanitizeDisplayContent(text: String): String {
    val normalized = normalizeNewlines(text)
    return normalized.replace(Regex("https?://shamela\\.\\s*ws"), "https://shamela.ws")
}

private fun shareContent(content: String, sources: List<Source>?): String {
    if (sources.isNullOrEmpty()) return content
    val sourcesLines = sources.joinToString("\n") { source ->
        "- ${source.citation} - ${source.sourceURL}"
    }
    return buildString {
        append(content)
        append("\n\nSources:\n")
        append(sourcesLines)
    }
}

private data class ParsedLine(
    val text: String,
    val inCodeBlock: Boolean
)

private const val URL_TAG = "URL"
