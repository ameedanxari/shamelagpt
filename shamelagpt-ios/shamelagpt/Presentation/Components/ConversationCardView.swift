//
//  ConversationCardView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// Card view component for displaying a conversation in the history list
struct ConversationCardView: View {

    // MARK: - Properties

    let title: String
    let preview: String
    let timestamp: String
    let conversationType: ConversationType?
    let isLocalOnly: Bool

    // MARK: - Initialization

    init(title: String, preview: String, timestamp: String, conversationType: ConversationType? = nil, isLocalOnly: Bool = false) {
        self.title = title
        self.preview = preview
        self.timestamp = timestamp
        self.conversationType = conversationType
        self.isLocalOnly = isLocalOnly
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            // Conversation icon
            conversationIcon

            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                // Title with fact-check badge
                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Typography.body.weight(.semibold))
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .lineLimit(1)

                    // Fact-check badge (mirrors local-only pill for quick visual scanning)
                    if conversationType == .factCheck {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.accent)
                            Text(LocalizationKeys.factCheckBadge.localizedKey)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.Colors.accent)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.primary.opacity(0.12))
                        .cornerRadius(4)
                    }
                    if isLocalOnly {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.slash")
                                .font(.system(size: 10))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                            Text(LocalizationKeys.localOnlyBadge.localizedKey)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignSystem.Colors.surface(ColorScheme.dark).opacity(0.2))
                        .cornerRadius(4)
                    }

                    Spacer()
                }

                // Preview
                Text(preview)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(2)

                // Timestamp
                Text(timestamp)
                    .font(AppTheme.Typography.small)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .contentShape(Rectangle())
    }

    // MARK: - Subviews

    private var conversationIcon: some View {
            ZStack {
            Circle()
                .fill(DesignSystem.Colors.primary.opacity(0.1))
                .frame(width: 48, height: 48)

            Image(systemName: "message.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.Colors.primary)
        }
    }
}

struct ConversationCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            List {
                ConversationCardView(
                    title: "What is the ruling on prayer?",
                    preview: "Prayer is one of the five pillars of Islam and is obligatory for all Muslims...",
                    timestamp: "2 hours ago"
                )
                .listRowBackground(DesignSystem.Colors.background(.light))
            }
            .listStyle(.plain)
            .previewDisplayName("Single Card")

            List {
                ConversationCardView(
                    title: "What is the ruling on prayer?",
                    preview: "Prayer is one of the five pillars of Islam and is obligatory for all Muslims...",
                    timestamp: "2 hours ago"
                )
                .listRowBackground(DesignSystem.Colors.background(.light))

                ConversationCardView(
                    title: "Fasting in Ramadan",
                    preview: "Fasting during Ramadan is obligatory for all adult Muslims who are physically able...",
                    timestamp: "1 day ago"
                )
                .listRowBackground(AppTheme.Colors.background)

                ConversationCardView(
                    title: "Zakat calculation",
                    preview: "Zakat is calculated at 2.5% of one's wealth that has been in possession for a lunar year...",
                    timestamp: "3 days ago"
                )
                .listRowBackground(AppTheme.Colors.background)

                ConversationCardView(
                    title: "New Conversation",
                    preview: "No messages",
                    timestamp: "Just now"
                )
                .listRowBackground(AppTheme.Colors.background)
            }
            .listStyle(.plain)
            .previewDisplayName("Multiple Cards")
        }
    }
}
