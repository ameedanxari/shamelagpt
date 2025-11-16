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
                AppInfoView()

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

                    bulletList([
                        LocalizationKeys.aboutMissionPointSupport.localizedKey,
                        LocalizationKeys.aboutMissionPointCombatMisinformation.localizedKey,
                        LocalizationKeys.aboutMissionPointEthicalAI.localizedKey,
                        LocalizationKeys.aboutMissionPointPreserveTrust.localizedKey
                    ])

                    sectionTitle(LocalizationKeys.aboutVisionTitle.localizedKey)

                    Text(LocalizationKeys.aboutVisionIntro.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)

                    bulletList([
                        LocalizationKeys.aboutVisionPointSources.localizedKey,
                        LocalizationKeys.aboutVisionPointVerifiable.localizedKey,
                        LocalizationKeys.aboutVisionPointUnderrepresented.localizedKey,
                        LocalizationKeys.aboutVisionPointChildren.localizedKey,
                        LocalizationKeys.aboutVisionPointDevelopers.localizedKey
                    ])

                    sectionTitle(LocalizationKeys.aboutGoalTitle.localizedKey)

                    Text(LocalizationKeys.aboutGoal.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)

                    sectionTitle(LocalizationKeys.aboutDataSourceTitle.localizedKey)

                    Text(LocalizationKeys.aboutDataSource.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)

                    sectionTitle(LocalizationKeys.aboutDataHandlingTitle.localizedKey)

                    Text(LocalizationKeys.aboutDataHandling.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)

                    sectionTitle(LocalizationKeys.aboutCompanyTitle.localizedKey)

                    Text(LocalizationKeys.aboutCompanyDescription.localizedKey)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)

                    if let url = URL(string: "https://neurallines.com/") {
                        Link(LocalizationKeys.aboutCompanyLink.localizedKey, destination: url)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
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

    private func bulletList(_ items: [LocalizedStringKey]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundColor(AppTheme.Colors.primary)
                        .padding(.top, 6)
                    Text(item)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .lineSpacing(4)
                }
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
    }
}
