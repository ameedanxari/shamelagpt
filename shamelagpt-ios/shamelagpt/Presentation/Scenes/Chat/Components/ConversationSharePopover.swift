//
//  ConversationSharePopover.swift
//  ShamelaGPT
//
//  Share card for the chat header. Mirrors the web app's share popover:
//  description + switch, a divider, then a full-width "Copy shareable link"
//  button that stays disabled until the conversation is actually published.
//

import SwiftUI
import UIKit

struct ConversationSharePopover: View {

    // MARK: - Properties

    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    /// Transient "Copied" confirmation on the copy button.
    @State private var isLinkCopied = false
    /// Held so a second tap restarts the 2s window instead of racing the first reset.
    @State private var copyResetTask: Task<Void, Never>?

    /// How long the copy button shows its confirmation state.
    private static let copiedFeedbackDuration: UInt64 = 2_000_000_000

    /// Matches the web card width (w-72) closely enough to feel identical.
    private static let cardWidth: CGFloat = 300

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            descriptionRow

            Divider()

            copyLinkButton
        }
        .padding(AppTheme.Spacing.md)
        .frame(width: Self.cardWidth)
        .background(DesignSystem.Colors.card(colorScheme))
        // The popover/sheet chrome supplies the rounded corners and shadow; this
        // only rounds the surface for the compact-sheet fallback on older iOS.
        .cornerRadius(DesignSystem.Layout.cornerRadiusLarge)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Chat.sharePopover)
        .onChange(of: viewModel.isShared) { isShared in
            // Un-sharing disables the copy button; clear a stale "Copied" label.
            if !isShared {
                resetCopiedState()
            }
        }
        .onDisappear {
            copyResetTask?.cancel()
        }
    }

    // MARK: - Subviews

    private var descriptionRow: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Text(LocalizationKeys.chatShareDescription.localizedKey)
                .font(DesignSystem.Typography.footnote)
                .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if viewModel.isSharePopoverLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.small)
            }

            Toggle("", isOn: sharingBinding)
                .labelsHidden()
                .tint(AppTheme.Colors.primary)
                .disabled(viewModel.isSharePopoverLoading)
                .accessibilityIdentifier(AccessibilityID.Chat.shareToggle)
                .accessibilityLabel(Text(LocalizationKeys.chatShareToggleAccessibility.localizedKey))
        }
    }

    private var copyLinkButton: some View {
        Button(action: copyShareLink) {
            Label {
                Text(
                    (isLinkCopied ? LocalizationKeys.chatShareCopied : LocalizationKeys.chatShareCopyLink)
                        .localizedKey
                )
                .font(DesignSystem.Typography.footnote)
            } icon: {
                Image(systemName: isLinkCopied ? "checkmark" : "link")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xxs)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.Colors.primary)
        .disabled(!isCopyEnabled)
        .accessibilityIdentifier(AccessibilityID.Chat.shareCopyLinkButton)
    }

    // MARK: - Helpers

    /// The copy button is only live once the server has confirmed the conversation
    /// is shared and handed back a link. Copying before that would spread a URL
    /// that answers 404 for the recipient.
    private var isCopyEnabled: Bool {
        viewModel.isShared && !viewModel.isSharePopoverLoading && viewModel.shareURL != nil
    }

    private var sharingBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isShared },
            set: { newValue in
                Task { await viewModel.setSharing(newValue) }
            }
        )
    }

    private func copyShareLink() {
        guard let shareURL = viewModel.shareURL else { return }

        UIPasteboard.general.string = shareURL
        AppLogger.chat.logInfo("Copied share link to pasteboard")

        copyResetTask?.cancel()
        withAnimation(AppTheme.Animation.quick) {
            isLinkCopied = true
        }
        copyResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.copiedFeedbackDuration)
            guard !Task.isCancelled else { return }
            withAnimation(AppTheme.Animation.quick) {
                isLinkCopied = false
            }
        }
    }

    private func resetCopiedState() {
        copyResetTask?.cancel()
        isLinkCopied = false
    }
}

// MARK: - Compact Adaptation

/// Keeps the card rendering as a real popover on iPhone.
///
/// `.popover` degrades to a full-height sheet in compact width; iOS 16.4 added
/// `presentationCompactAdaptation` to opt out of that. The app still deploys to
/// iOS 15.6, so older devices fall back to the sheet presentation.
struct CompactPopoverAdaptation: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }
}

extension View {
    func compactPopoverAdaptation() -> some View {
        modifier(CompactPopoverAdaptation())
    }
}
