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
    var onSuggestionTap: (String) -> Void = { _ in }

    private let suggestionKeys = [
        LocalizationKeys.emptyStateSuggestion1,
        LocalizationKeys.emptyStateSuggestion2,
        LocalizationKeys.emptyStateSuggestion3
    ]

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

                ForEach(suggestionKeys, id: \.self) { key in
                    suggestionButton(for: key)
                }
            }
            .padding(.top, AppTheme.Spacing.md)
            .padding(.horizontal, AppTheme.Spacing.md)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subviews

    private func suggestionButton(for key: String) -> some View {
        let localizedValue = LanguageManager.shared.localizedString(forKey: key)

        return Button(action: {
            onSuggestionTap(localizedValue)
        }) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.accent)

                Text(key.localizedKey)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.primaryText)

                Spacer()
            }
            .padding(AppTheme.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Colors.surface(colorScheme))
            .cornerRadius(AppTheme.Layout.cornerRadius)
        }
        .buttonStyle(PlainButtonStyle())
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
