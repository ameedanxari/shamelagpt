//
//  SettingsView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showDonationLink = false

    private let donationURL = URL(string: "https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU")!

    var body: some View {
        Form {
            // General Section
            Section(header: Text(LocalizationKeys.general.localized)) {
                NavigationLink(destination: LanguageSelectionView()) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.language.localized)
                            .font(AppTheme.Typography.body)

                        Spacer()

                        Text(languageManager.currentLanguageDisplayName)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                }
                .accessibilityIdentifier("LanguageRow")
            }

            // Support Section
            Section(header: Text(LocalizationKeys.support.localized)) {
                Button(action: {
                    showDonationLink = true
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.supportShamelaGPT.localized)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                }
            }

            // About Section
            Section(header: Text(LocalizationKeys.about.localized)) {
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.aboutShamelaGPT.localized)
                            .font(AppTheme.Typography.body)
                    }
                }

                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.privacyPolicy.localized)
                            .font(AppTheme.Typography.body)
                    }
                }

                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.termsOfService.localized)
                            .font(AppTheme.Typography.body)
                    }
                }
            }

            // Footer Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.xxs) {
                        Text(LocalizationKeys.shamelaGPT.localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.tertiaryText)

                        Text("\(LocalizationKeys.version.localized) 1.0.0")
                            .font(AppTheme.Typography.small)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(LocalizationKeys.settings.localized)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDonationLink) {
            SafariView(url: donationURL)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    SettingsView()
}
