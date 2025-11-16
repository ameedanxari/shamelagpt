//
//  MessageBubbleView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI
import Foundation

/// A view that displays a message bubble with content, timestamp, and sources
struct MessageBubbleView: View {

    // MARK: - Properties

    let message: Message
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var cachedLines: [ParsedLine] = []

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: AppTheme.Spacing.xs) {
            if message.isUserMessage {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.isUserMessage ? .trailing : .leading, spacing: AppTheme.Spacing.xxs) {
                // Message bubble
                messageBubble

                // Timestamp
                Text(formattedTimestamp)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
                    .padding(.horizontal, AppTheme.Spacing.xs)

                // Sources section (if available)
                if !displayedSources.isEmpty {
                    sourcesSection
                }
            }

            if !message.isUserMessage {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xxs)
        .messageAppearance(delay: 0.1)
        .messageAccessibility(
            isUserMessage: message.isUserMessage,
            content: message.content,
            timestamp: message.timestamp
        )
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .bottom)),
            removal: .opacity
        ))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityID.Chat.messageBubble)
        .accessibilityLabel(message.content)
        .accessibilityHint(message.isUserMessage
                           ? "Your message. Double tap to view context menu with copy and share options."
                           : (!displayedSources.isEmpty
                              ? "Assistant message. Contains \(displayedSources.count) sources. Double tap for options."
                              : "Assistant message. Double tap for options."))
        .accessibilityValue(formattedTimestamp)
        .onAppear {
            updateCachedLines()
        }
        .onChange(of: message.content) { _ in
            updateCachedLines()
        }
    }

    // MARK: - Subviews

    private var messageBubble: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            // Image thumbnail for fact-check messages
            if message.isFactCheckMessage, let imageData = message.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 120)
                    .cornerRadius(8)
            }

            // Language indicator for fact-check messages
            if message.isFactCheckMessage, let language = message.detectedLanguage {
                HStack(spacing: 4) {
                    Image(systemName: "character.bubble")
                        .font(.system(size: 12))
                        .foregroundColor(message.isUserMessage ? .white.opacity(0.7) : AppTheme.Colors.secondaryText)
                    Text(languageDisplayName(for: language))
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(message.isUserMessage ? .white.opacity(0.7) : AppTheme.Colors.secondaryText)
                }
                .padding(.bottom, 2)
            }

            // Message text
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                ForEach(Array(displayLines.enumerated()), id: \.offset) { _, line in
                    messageLineView(line)
                }
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(bubbleBackground)
        .cornerRadius(AppTheme.Layout.messageBubbleRadius)
        .contextMenu {
            contextMenuItems
        }
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        // Minimal styling per website design - subtle background difference for distinction
        if message.isUserMessage {
            DesignSystem.Colors.card(colorScheme).opacity(0.8)
        } else {
            DesignSystem.Colors.surface(colorScheme)
        }
    }

    private var contextMenuItems: some View {
        Group {
            Button(action: copyMessage) {
                Label("Copy message", systemImage: "doc.on.doc")
            }
            .accessibilityLabel("Copy message to clipboard")
            .accessibilityHint("Copies the message text to your clipboard")

            Button(action: shareMessage) {
                Label("Share message", systemImage: "square.and.arrow.up")
            }
            .accessibilityLabel("Share message")
            .accessibilityHint("Opens the share sheet to share this message")
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text("Sources:")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .fontWeight(.semibold)
                .accessibilityIdentifier(AccessibilityID.Chat.sourcesHeader)

            ForEach(displayedSources) { source in
                sourceLink(for: source)
            }
        }
        .padding(AppTheme.Spacing.xs)
        .background(DesignSystem.Colors.surface(colorScheme))
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .padding(.horizontal, AppTheme.Spacing.xs)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sources")
    }

    private func sourceLink(for source: Source) -> some View {
        Button(action: {
            openSource(source)
        }) {
            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: "book.fill")
                    .font(.system(size: 12))
                    .foregroundColor(DesignSystem.Colors.accent)

                Text(source.citation)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(DesignSystem.Colors.accent)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        }
        .accessibilityIdentifier("\(AccessibilityID.Chat.sourceLinkPrefix)\(source.id)")
        .padding(.vertical, AppTheme.Spacing.xxs)
        .accessibilityLabel("Source: \(source.citation)")
        .accessibilityHint("Double tap to open source reference")
    }

    // MARK: - Computed Properties

    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }

    private var displayLines: [ParsedLine] {
        if cachedLines.isEmpty {
            return parseLines(from: messageDisplayContent)
        }
        return cachedLines
    }

    private func updateCachedLines() {
        let lines = parseLines(from: messageDisplayContent)
        DispatchQueue.main.async {
            self.cachedLines = lines
        }
    }

    private func parseLines(from content: String) -> [ParsedLine] {
        let normalized = normalizeNewlines(in: content)
        if !message.isAssistantMessage {
            return normalized
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map { part in
                    let line = String(part)
                    return line.isEmpty ? ParsedLine(kind: .empty) : ParsedLine(kind: .paragraph(line))
                }
        }

        let rawLines = normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)

        var lines: [ParsedLine] = []
        var inCodeBlock = false

        for rawLine in rawLines {
            let trimmedLeading = rawLine.trimmingCharacters(in: .whitespaces)
            if trimmedLeading.hasPrefix("```") {
                inCodeBlock.toggle()
                continue
            }

            if inCodeBlock {
                lines.append(ParsedLine(kind: .codeBlock(rawLine)))
            } else {
                lines.append(detectLineType(rawLine))
            }
        }

        if normalized.hasSuffix("\n") {
            lines.append(ParsedLine(kind: .empty))
        }

        return lines
    }

    // MARK: - Actions

    private func copyMessage() {
        UIPasteboard.general.string = shareContent
    }

    private func shareMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [shareContent],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }

    private func openSource(_ source: Source) {
        if let urlString = source.sourceUrl,
           let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Helpers

    private func languageDisplayName(for code: String) -> String {
        switch code {
        case "ar":
            return "Arabic"
        case "en":
            return "English"
        default:
            return code.uppercased()
        }
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        do {
            let normalized = normalizeMarkdownInput(text)
            let swiftAttr = try AttributedString(
                markdown: normalized,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
            let ns = NSMutableAttributedString(attributedString: NSAttributedString(swiftAttr))
            applyLanguageAwareFonts(to: ns)
            return AttributedString(ns)
        } catch {
            AppLogger.ui.logError("Inline markdown parsing failed, using plain text", error: error)
            return AttributedString(stringLiteral: text)
        }
    }

    private func normalizeMarkdownInput(_ text: String) -> String {
        normalizeNewlines(in: text)
    }

    private func normalizeNewlines(in text: String) -> String {
        text
            // Normalize escaped newlines so server responses with "\n" render as real line breaks.
            .replacingOccurrences(of: "\\r\\n", with: "\n")
            .replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\r\n", with: "\n")
    }

    @ViewBuilder
    private func messageLineView(_ line: ParsedLine) -> some View {
        switch line.kind {
        case .empty:
            Text(" ")
                .font(AppTheme.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
        case .codeBlock(let text):
            Text(text.isEmpty ? " " : text)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, AppTheme.Spacing.xxs)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.surface(colorScheme))
                .cornerRadius(6)
        case .blockquote(let text):
            HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                Rectangle()
                    .fill(AppTheme.Colors.tertiaryText.opacity(0.5))
                    .frame(width: 3)
                    .cornerRadius(2)
                Text(displayText(text))
                    .font(AppTheme.Typography.body.italic())
                    .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .heading(let level, let text):
            Text(displayText(text))
                .font(headingFont(for: level))
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        case .bullet(let text):
            HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                Text("•")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                Text(displayText(text))
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .ordered(let index, let text):
            HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                Text("\(index).")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                Text(displayText(text))
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .paragraph(let text):
            Text(displayText(text))
                .font(AppTheme.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func displayText(_ text: String) -> AttributedString {
        if message.isAssistantMessage {
            return parseInlineMarkdown(text)
        }
        return AttributedString(stringLiteral: text)
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1:
            return AppTheme.Typography.heading.weight(.bold)
        case 2:
            return AppTheme.Typography.body.weight(.semibold)
        case 3:
            return AppTheme.Typography.body.weight(.medium)
        default:
            return AppTheme.Typography.body
        }
    }

    private func detectLineType(_ line: String) -> ParsedLine {
        if line.isEmpty {
            return ParsedLine(kind: .empty)
        }

        let trimmedStart = line.trimmingCharacters(in: .whitespaces)

        if let heading = matchGroups(pattern: "^(#{1,6})\\s+(.*)$", in: trimmedStart), heading.count == 2 {
            let level = heading[0].count
            return ParsedLine(kind: .heading(level: level, text: heading[1].trimmingCharacters(in: .whitespaces)))
        }

        if let blockQuote = matchGroups(pattern: "^>\\s?(.*)$", in: trimmedStart), blockQuote.count == 1 {
            return ParsedLine(kind: .blockquote(blockQuote[0].trimmingCharacters(in: .whitespaces)))
        }

        if let bullet = matchGroups(pattern: "^[\\-*+]\\s+(.*)$", in: trimmedStart), bullet.count == 1 {
            return ParsedLine(kind: .bullet(bullet[0].trimmingCharacters(in: .whitespaces)))
        }

        if let ordered = matchGroups(pattern: "^(\\d+)\\.\\s+(.*)$", in: trimmedStart), ordered.count == 2 {
            let index = Int(ordered[0]) ?? 0
            return ParsedLine(kind: .ordered(index: index, text: ordered[1].trimmingCharacters(in: .whitespaces)))
        }

        return ParsedLine(kind: .paragraph(line))
    }

    private func matchGroups(pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else {
            return nil
        }
        return (1..<match.numberOfRanges).compactMap { idx in
            let groupRange = match.range(at: idx)
            guard groupRange.location != NSNotFound else { return nil }
            return nsText.substring(with: groupRange)
        }
    }

    private func applyLanguageAwareFonts(to attributedText: NSMutableAttributedString) {
        let fullString = attributedText.string as NSString
        var index = 0

        while index < fullString.length {
            let rangeStart = index
            let firstCharRange = NSRange(location: index, length: 1)
            let firstSubstring = fullString.substring(with: firstCharRange)
            let isArabicScript = LanguageDetector.containsArabicScript(in: firstSubstring)

            var nextIndex = index + 1
            while nextIndex < fullString.length {
                let nextCharRange = NSRange(location: nextIndex, length: 1)
                let nextSubstring = fullString.substring(with: nextCharRange)
                let nextIsArabicScript = LanguageDetector.containsArabicScript(in: nextSubstring)
                if nextIsArabicScript != isArabicScript {
                    break
                }
                nextIndex += 1
            }

            let runRange = NSRange(location: rangeStart, length: nextIndex - rangeStart)
            let runText = fullString.substring(with: runRange)
            let detectedLanguage = LanguageDetector.detectLanguage(for: runText)
            let existingFont = attributedText.attribute(.font, at: runRange.location, effectiveRange: nil) as? UIFont
            let mappedFont = languageAwareFont(for: detectedLanguage, originalFont: existingFont)
            attributedText.addAttribute(.font, value: mappedFont, range: runRange)

            index = nextIndex
        }
    }

    private var messageDisplayContent: String {
        let base = message.isAssistantMessage
            ? ResponseParser.parseMarkdownResponse(message.content).cleanContent
            : message.content
        return sanitizedContent(base)
    }

    private var displayedSources: [Source] {
        if !message.sources.isEmpty {
            return message.sources
        }
        if message.isAssistantMessage {
            return ResponseParser.parseMarkdownResponse(message.content).sources
        }
        return []
    }

    private var shareContent: String {
        guard !displayedSources.isEmpty else { return messageDisplayContent }

        let sourcesLines = displayedSources.map { source -> String in
            if let url = source.sourceUrl, !url.isEmpty {
                return "- \(source.citation) - \(url)"
            }
            return "- \(source.citation)"
        }.joined(separator: "\n")

        return """
        \(messageDisplayContent)

        Sources:
        \(sourcesLines)
        """
    }

    private func languageAwareFont(for detectedLanguage: String?, originalFont: UIFont?) -> UIFont {
        let baseFont = originalFont ?? UIFont.preferredFont(forTextStyle: .body)
        let weight = baseFont.fontWeight
        let languageFont = FontRegistry.shared.uiFont(forLanguage: detectedLanguage, textStyle: .body, weight: weight)
        let descriptorWithTraits = languageFont.fontDescriptor
            .withSymbolicTraits(baseFont.fontDescriptor.symbolicTraits) ?? languageFont.fontDescriptor
        return UIFont(descriptor: descriptorWithTraits, size: baseFont.pointSize)
    }
}

private struct ParsedLine {
    let kind: LineKind
}

private enum LineKind {
    case empty
    case codeBlock(String)
    case blockquote(String)
    case heading(level: Int, text: String)
    case bullet(String)
    case ordered(index: Int, text: String)
    case paragraph(String)
}

private extension UIFont {
    var fontWeight: UIFont.Weight {
        let traits = fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
        if let weightValue = traits?[.weight] as? CGFloat {
            return UIFont.Weight(weightValue)
        }
        return .regular
    }
}

// MARK: - Content Normalization Helpers

private extension MessageBubbleView {
    func sanitizedContent(_ text: String) -> String {
        let normalized = normalizeNewlines(in: text)
        // Fix domain breaks like "https://shamela. ws" that may appear in stored text
        return normalized
            .replacingOccurrences(of: "https?://shamela\\.\\s*ws", with: "https://shamela.ws", options: .regularExpression)
    }
}

#if DEBUG
// MARK: - Preview Provider

struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageBubbleView(message: .preview)
                .previewDisplayName("User Message")
                .previewLayout(.sizeThatFits)
                .padding()

            MessageBubbleView(message: .previewAssistant)
                .previewDisplayName("Assistant Message")
                .previewLayout(.sizeThatFits)
                .padding()

            MessageBubbleView(message: Message(
                conversationId: "preview",
                content: "This is a much longer message that spans multiple lines. It demonstrates how the message bubble adapts to different content lengths and maintains proper formatting throughout. The bubble should expand to accommodate all the text while maintaining its rounded corners and proper padding.",
                isUserMessage: false,
                sources: [Source.preview]
            ))
            .previewDisplayName("Long Message")
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
#endif
