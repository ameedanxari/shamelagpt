//
//  EmptyStateView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// A view that displays an empty state when there are no messages
struct EmptyStateView: View {

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
            Text(LocalizationKeys.startConversation.localized)
                .font(AppTheme.Typography.heading)
                .foregroundColor(AppTheme.Colors.primaryText)
                .fontWeight(.semibold)

            // Description
            Text(LocalizationKeys.emptyStateDescription.localized)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            // Suggested questions
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(LocalizationKeys.emptyStateTryAsking.localized)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .fontWeight(.medium)

                suggestionButton(text: LocalizationKeys.emptyStateSuggestion1.localized)
                suggestionButton(text: LocalizationKeys.emptyStateSuggestion2.localized)
                suggestionButton(text: LocalizationKeys.emptyStateSuggestion3.localized)
            }
            .padding(.top, AppTheme.Spacing.md)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subviews

    private func suggestionButton(text: String) -> some View {
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
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.Layout.cornerRadius)
    }
}

// MARK: - Preview Provider

#Preview {
    EmptyStateView()
}

#Preview("With Background") {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()

        EmptyStateView()
    }
}
