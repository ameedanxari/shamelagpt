//
//  ReasoningPanelView.swift
//  ShamelaGPT
//
//  Collapsed, expandable panel for the model's chain-of-thought.
//

import SwiftUI

/// Shows the `{"type":"reasoning"}` chain-of-thought for a turn.
///
/// Collapsed by default: the reasoning routinely runs to hundreds of words and is
/// supporting detail, not the answer, so it must never push the answer off screen.
/// Styled to match `ThinkingBubbleView` — same surface, same muted italic caption —
/// because it is the same class of secondary, machine-generated commentary.
struct ReasoningPanelView: View {

    /// The full chain-of-thought, already concatenated from the stream deltas with no
    /// separator. This view never re-joins anything; it renders what it is handed.
    let reasoning: String

    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Button(action: toggle) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(AppTheme.Colors.secondaryText)

                    Text(LocalizationKeys.chatReasoningTitle.localizedKey)
                        .font(AppTheme.Typography.caption.weight(.semibold))
                        .foregroundColor(AppTheme.Colors.secondaryText)

                    Spacer(minLength: AppTheme.Spacing.xs)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(AccessibilityID.Chat.reasoningPanelToggle)
            .accessibilityLabel(Text(toggleLabelKey.localizedKey))
            .accessibilityAddTraits(.isButton)

            if isExpanded {
                Text(reasoning)
                    .font(AppTheme.Typography.caption.italic())
                    .foregroundColor(AppTheme.Colors.secondaryText.opacity(0.9))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .accessibilityIdentifier(AccessibilityID.Chat.reasoningPanelBody)
                    .transition(.opacity)
            }
        }
        .padding(AppTheme.Spacing.sm)
        .background(DesignSystem.Colors.surface(colorScheme))
        .cornerRadius(AppTheme.Layout.cornerRadius)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Chat.reasoningPanel)
    }

    private var toggleLabelKey: String {
        isExpanded ? LocalizationKeys.chatReasoningHide : LocalizationKeys.chatReasoningShow
    }

    private func toggle() {
        withAnimation(AppTheme.Animation.standard) {
            isExpanded.toggle()
        }
    }
}

#if DEBUG
// MARK: - Preview Provider

struct ReasoningPanelView_Previews: PreviewProvider {
    static var previews: some View {
        ReasoningPanelView(
            reasoning: "The user is asking about the ruling on combining prayers while travelling. I should check the four schools before answering, and cite the primary sources rather than paraphrasing them."
        )
        .previewDisplayName("Collapsed by default")
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif
