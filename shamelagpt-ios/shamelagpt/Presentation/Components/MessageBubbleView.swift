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

    @State private var showingCopyConfirmation = false

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
        .accessibilityIdentifier("MessageBubble")
        .accessibilityLabel(message.content)
        .accessibilityHint(message.isUserMessage
                           ? "Your message. Double tap to view context menu with copy and share options."
                           : (!displayedSources.isEmpty
                              ? "Assistant message. Contains \(displayedSources.count) sources. Double tap for options."
                              : "Assistant message. Double tap for options."))
        .accessibilityValue(formattedTimestamp)
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
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(messageLines.enumerated()), id: \.offset) { _, line in
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
                .accessibilityIdentifier("SourcesHeader")

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
        .accessibilityIdentifier("SourceLink-\(source.id)")
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

    private var messageLines: [AttributedString] {
        let normalizedLines = normalizedLines(from: messageDisplayContent)
        return normalizedLines.map { line in
            let displayLine = line.isEmpty ? " " : line
            if message.isAssistantMessage {
                return AttributedString(parseMarkdown(displayLine))
            } else {
                return AttributedString(stringLiteral: displayLine)
            }
        }
    }

    // MARK: - Actions

    private func copyMessage() {
        UIPasteboard.general.string = shareContent
        showingCopyConfirmation = true

        // Hide confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopyConfirmation = false
        }
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

    private func parseMarkdown(_ text: String) -> NSAttributedString {
        // Use stock iOS markdown support without any preprocessing
        // iOS AttributedString handles CommonMark markdown automatically

        do {
            let normalized = normalizeMarkdownInput(text)

            // Parse markdown using Swift's AttributedString API (available on iOS 15+),
            // then bridge to an NSMutableAttributedString so we can mutate fonts per-range.
            let swiftAttr = try AttributedString(
                markdown: normalized,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
            )

            let ns = NSMutableAttributedString(attributedString: NSAttributedString(swiftAttr))

            // Use simple script-run segmentation to apply language-aware fonts per range
            let fullString = ns.string as NSString
            var index = 0
            while index < fullString.length {
                let rangeStart = index
                // Get single-character substring safely
                let firstCharRange = NSRange(location: index, length: 1)
                let firstSubstring = fullString.substring(with: firstCharRange)
                let isArabic = LanguageDetector.containsArabicScript(in: firstSubstring)

                // Expand range while same script type
                var j = index + 1
                while j < fullString.length {
                    let nextCharRange = NSRange(location: j, length: 1)
                    let nextSubstring = fullString.substring(with: nextCharRange)
                    let nextIsArabic = LanguageDetector.containsArabicScript(in: nextSubstring)
                    if nextIsArabic != isArabic { break }
                    j += 1
                }

                let runRange = NSRange(location: rangeStart, length: j - rangeStart)
                let substring = fullString.substring(with: runRange)

                // Detect language for the run (prefer heuristic)
                let detected = LanguageDetector.detectLanguage(for: substring)

                // Map to language-aware font while preserving original size/traits (so markdown headings keep scale)
                let currentFont = ns.attribute(.font, at: runRange.location, effectiveRange: nil) as? UIFont
                let uiFont = languageAwareFont(for: detected, originalFont: currentFont)
                AppLogger.font.logDebug("MessageBubbleView: runRange=\(runRange.location)-\(runRange.length) detected=\(detected ?? "nil") substringPreview=\(substring.prefix(24)) -> uiFont=\(uiFont.fontName) pointSize=\(uiFont.pointSize)")
                ns.addAttribute(NSAttributedString.Key.font, value: uiFont, range: runRange)

                index = j
            }

            return ns
        } catch {
            // Fallback to plain text if markdown parsing fails
            AppLogger.ui.logError("Markdown parsing failed, using plain text", error: error)
            return NSAttributedString(string: text)
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
    private func messageLineView(_ line: AttributedString) -> some View {
        if message.isAssistantMessage {
            Text(line)
        } else {
            Text(line)
                .font(AppTheme.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
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

    func normalizedLines(from text: String) -> [String] {
        let normalized = normalizeNewlines(in: text)
        return normalized
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
    }
}

// MARK: - Preview Provider

struct MessageBubbleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MessageBubbleView(message: Message.preview)
                .previewDisplayName("User Message")
                .previewLayout(.sizeThatFits)
                .padding()

            MessageBubbleView(message: Message.previewAssistant)
                .previewDisplayName("Assistant Message")
                .previewLayout(.sizeThatFits)
                .padding()

            MessageBubbleView(message: Message(
                conversationId: "preview",
                content: "This is a much longer message that spans multiple lines. It demonstrates how the message bubble adapts to different content lengths and maintains proper formatting throughout. The bubble should expand to accommodate all the text while maintaining its rounded corners and proper padding.",
                isUserMessage: false
            ))
            .previewDisplayName("Long Message")
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
