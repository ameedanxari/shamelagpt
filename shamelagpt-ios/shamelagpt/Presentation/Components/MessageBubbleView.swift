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
                if message.hasSources {
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
                           : (message.hasSources
                              ? "Assistant message. Contains \(message.sources.count) sources. Double tap for options."
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
            Text(formattedContent)
                .font(AppTheme.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
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

            ForEach(message.sources) { source in
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

    private var formattedContent: AttributedString {
        // Basic markdown support using AttributedString
        if message.isAssistantMessage {
            return parseMarkdown(message.content)
        }
        return AttributedString(message.content)
    }

    // MARK: - Actions

    private func copyMessage() {
        UIPasteboard.general.string = message.content
        showingCopyConfirmation = true

        // Hide confirmation after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showingCopyConfirmation = false
        }
    }

    private func shareMessage() {
        let activityVC = UIActivityViewController(
            activityItems: [message.content],
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

    private func parseMarkdown(_ text: String) -> AttributedString {
        // Use stock iOS markdown support without any preprocessing
        // iOS AttributedString handles CommonMark markdown automatically

        do {
            // Normalize escaped newlines so server responses with "\n" render as real line breaks.
            let normalized = text
                .replacingOccurrences(of: "\\r\\n", with: "\n")
                .replacingOccurrences(of: "\\n", with: "\n")
                // Also insert a space before capital letters that immediately follow punctuation without spacing (common in streamed text)
                .replacingOccurrences(of: "([\\.\\!\\?])(\\w)", with: "$1 $2", options: .regularExpression)

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

                // Map to font and apply
                let uiFont = FontRegistry.shared.uiFont(forLanguage: detected, textStyle: .body)
                AppLogger.font.logDebug("MessageBubbleView: runRange=\(runRange.location)-\(runRange.length) detected=\(detected ?? "nil") substringPreview=\(substring.prefix(24)) -> uiFont=\(uiFont.fontName)")
                ns.addAttribute(NSAttributedString.Key.font, value: uiFont, range: runRange)

                index = j
            }

            // Convert back to AttributedString for SwiftUI (use NSAttributedString bridge)
            return AttributedString(ns)
        } catch {
            // Fallback to plain text if markdown parsing fails
            AppLogger.ui.logError("Markdown parsing failed, using plain text", error: error)
            return AttributedString(text)
        }
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
