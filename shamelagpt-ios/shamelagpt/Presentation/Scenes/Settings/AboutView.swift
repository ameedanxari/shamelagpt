//
//  AboutView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // App Icon
                HStack {
                    Spacer()
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppTheme.Colors.primary)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.lg)

                // App Name and Version
                VStack(spacing: AppTheme.Spacing.xs) {
                    Text(LocalizationKeys.shamelaGPT.localizedKey)
                        .font(AppTheme.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.Colors.primaryText)

                    HStack(spacing: 4) {
                        Text(LocalizationKeys.settingsVersion.localizedKey)
                        Text("1.0.0")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .padding(.vertical, AppTheme.Spacing.sm)

                // About Content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    sectionTitle(LocalizationKeys.aboutShamelaGPT.localizedKey)

                    Text(LocalizationKeys.aboutContent.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)

                    sectionTitle(LocalizationKeys.aboutMissionTitle.localizedKey)

                    Text(LocalizationKeys.aboutMission.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)

                    sectionTitle(LocalizationKeys.aboutDataSourceTitle.localizedKey)

                    Text(LocalizationKeys.aboutDataSource.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .navigationTitle(LocalizationKeys.about.localizedKey)
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
    }

    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(AppTheme.Typography.heading)
            .fontWeight(.semibold)
            .foregroundColor(AppTheme.Colors.primaryText)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
    }
}
