//
//  EmptyStateView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// A view that displays an empty state when there are no messages
struct EmptyStateView: View {

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            // Icon
            Image(systemName: "book.closed.fill")
                .font(.system(size: AppTheme.Layout.largeIconSize))
                .foregroundColor(AppTheme.Colors.primary)
                .symbolRenderingMode(.hierarchical)

            // Title
            Text(LocalizationKeys.startConversation.localizedKey)
                .font(AppTheme.Typography.heading)
                .foregroundColor(AppTheme.Colors.primaryText)
                .fontWeight(.semibold)

            // Description
            Text(LocalizationKeys.emptyStateDescription.localizedKey)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            // Suggested questions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(LocalizationKeys.emptyStateTryAsking.localizedKey)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .fontWeight(.medium)

                suggestionButton(text: LocalizationKeys.emptyStateSuggestion1.localizedKey)
                suggestionButton(text: LocalizationKeys.emptyStateSuggestion2.localizedKey)
                suggestionButton(text: LocalizationKeys.emptyStateSuggestion3.localizedKey)
            }
            .padding(.top, AppTheme.Spacing.md)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subviews

    private func suggestionButton(text: LocalizedStringKey) -> some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.accent)

            Text(text)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.primaryText)

            Spacer()
        }
        .padding(AppTheme.Spacing.sm)
        .background(DesignSystem.Colors.surface(colorScheme))
        .cornerRadius(AppTheme.Layout.cornerRadius)
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmptyStateView()

            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()

                EmptyStateView()
            }
            .previewDisplayName("With Background")
        }
    }
}
