//
//  SettingsView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct SettingsView: View {
    let isAuthenticated: Bool
    let onLogout: () -> Void
    let onSignIn: () -> Void
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showDonationLink = false
    @State private var customPrompt: String = ""
    @State private var lengthPref: String = ""
    @State private var stylePref: String = ""
    @State private var focusPref: String = ""
    @State private var isLoading = false
    @State private var hasLoadedPreferences = false
    @State private var error: String?
    private let preferencesRepository: PreferencesRepository? = DependencyContainer.shared.resolve(PreferencesRepository.self)

    private let donationURL = URL(string: "https://www.paypal.com/donate/?hosted_button_id=MSBDG5ESU2AMU")!

    var body: some View {
        Form {
            // General Section
            Section(header: Text(LocalizationKeys.general.localizedKey)) {
                NavigationLink(destination: LanguageSelectionView()) {
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.language.localizedKey)
                            .font(AppTheme.Typography.body)

                        Spacer()

                        Text(languageManager.currentLanguageDisplayName)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                }
                .accessibilityIdentifier("LanguageRow")
            }

            // AI Preferences Section
            Section(header: Text(LocalizationKeys.aiPreferences.localizedKey)) {
                if isAuthenticated {
                    NavigationLink(
                        destination: CustomPromptEditView(
                            customPrompt: $customPrompt,
                            onSave: {
                                await savePreferences()
                            }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(LocalizationKeys.customPromptTitle.localizedKey)
                                .font(AppTheme.Typography.heading)
                                .foregroundColor(AppTheme.Colors.primaryText)

                            if customPrompt.isEmpty {
                                Text(LocalizationKeys.customPromptPlaceholder.localizedKey)
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.tertiaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            } else {
                                Text(customPrompt)
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                    }
                    // Replace free-text fields with selection lists to match LanguageSelection style
                    NavigationLink(destination: PreferenceSelectionView(
                        title: LocalizationKeys.prefLengthTitle,
                        key: .length,
                        options: [
                            (LocalizationKeys.prefLengthShort, "short"),
                            (LocalizationKeys.prefLengthMedium, "medium"),
                            (LocalizationKeys.prefLengthDetailed, "detailed")
                        ],
                        selectedValue: $lengthPref,
                        preferencesRepository: preferencesRepository
                    )) {
                        HStack {
                                Text(LocalizationKeys.prefLengthTitle.localizedKey)
                                    .font(AppTheme.Typography.body)
                                Spacer()
                                Text(displayForLength(lengthPref).localizedKey)
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.tertiaryText)
                            }
                    }

                    NavigationLink(destination: PreferenceSelectionView(
                        title: LocalizationKeys.prefStyleTitle,
                        key: .style,
                        options: [
                            (LocalizationKeys.prefStyleConversational, "conversational"),
                            (LocalizationKeys.prefStyleAcademic, "academic"),
                            (LocalizationKeys.prefStyleTechnical, "technical")
                        ],
                        selectedValue: $stylePref,
                        preferencesRepository: preferencesRepository
                    )) {
                        HStack {
                                Text(LocalizationKeys.prefStyleTitle.localizedKey)
                                    .font(AppTheme.Typography.body)
                                Spacer()
                                Text(displayForStyle(stylePref).localizedKey)
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.tertiaryText)
                            }
                    }

                    NavigationLink(destination: PreferenceSelectionView(
                        title: LocalizationKeys.prefFocusTitle,
                        key: .focus,
                        options: [
                            (LocalizationKeys.prefFocusPractical, "practical"),
                            (LocalizationKeys.prefFocusTheoretical, "theoretical"),
                            (LocalizationKeys.prefFocusHistorical, "historical")
                        ],
                        selectedValue: $focusPref,
                        preferencesRepository: preferencesRepository
                    )) {
                        HStack {
                                Text(LocalizationKeys.prefFocusTitle.localizedKey)
                                    .font(AppTheme.Typography.body)
                                Spacer()
                                Text(displayForFocus(focusPref).localizedKey)
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(AppTheme.Colors.tertiaryText)
                            }
                    }
                    if let error = error {
                        Text(error).foregroundColor(.red)
                    }
                    Button(LocalizationKeys.refreshPreferences.localizedKey) {
                        Task { await loadPreferences(force: true) }
                    }
                    .disabled(isLoading)
                } else {
                    // Guest user: Show locked state with sign-in CTA
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(AppTheme.Colors.primary)
                            Text(LocalizationKeys.aiPreferencesLockedTitle.localizedKey)
                                .font(AppTheme.Typography.body.weight(.semibold))
                                .foregroundColor(AppTheme.Colors.primaryText)
                        }

                        Text(LocalizationKeys.aiPreferencesLockedMessage.localizedKey)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: onSignIn) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                Text(LocalizationKeys.signInButton.localizedKey)
                            }
                            .font(AppTheme.Typography.body.weight(.medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.Layout.cornerRadius)
                        }
                        .padding(.top, AppTheme.Spacing.xs)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                }
            }


            // Support Section
            Section(header: Text(LocalizationKeys.support.localizedKey)) {
                Button(action: {
                    showDonationLink = true
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.supportShamelaGPT.localizedKey)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                }
            }

            if isAuthenticated {
                Section {
                    Button(role: .destructive, action: onLogout) {
                        HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                                    .frame(width: AppTheme.Layout.iconSize)
                                Text(LocalizationKeys.signOut.localizedKey)
                                    .font(AppTheme.Typography.body)
                            }
                    }
                }
            }

            // About Section
            Section(header: Text(LocalizationKeys.about.localizedKey)) {
                NavigationLink(destination: AboutView()) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.aboutShamelaGPT.localizedKey)
                            .font(AppTheme.Typography.body)
                    }
                }
                .accessibilityIdentifier("AboutRow")

                NavigationLink(destination: PrivacyPolicyView()) {
                    HStack {
                        Image(systemName: "hand.raised")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.privacyPolicy.localizedKey)
                            .font(AppTheme.Typography.body)
                    }
                }
                .accessibilityIdentifier("PrivacyRow")

                NavigationLink(destination: TermsOfServiceView()) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(AppTheme.Colors.primary)
                            .frame(width: AppTheme.Layout.iconSize)

                        Text(LocalizationKeys.termsOfService.localizedKey)
                            .font(AppTheme.Typography.body)
                    }
                }
                .accessibilityIdentifier("TermsRow")
            }

            // Footer Section
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: AppTheme.Spacing.xxs) {
                        Text(LocalizationKeys.shamelaGPT.localizedKey)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.tertiaryText)

                        HStack(spacing: 4) {
                            Text(LocalizationKeys.settingsVersion.localizedKey)
                            Text("1.0.0")
                                .font(AppTheme.Typography.small)
                                .foregroundColor(AppTheme.Colors.tertiaryText)
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle(LocalizationKeys.settings.localizedKey)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDonationLink) {
            SafariView(url: donationURL)
                .ignoresSafeArea()
        }
        .task {
            if isAuthenticated && !hasLoadedPreferences {
                await loadPreferences()
            }
        }
    }

    private func loadPreferences(force: Bool = false) async {
        guard let repo = preferencesRepository else { return }
        guard force || !hasLoadedPreferences else { return }

        isLoading = true
        defer { isLoading = false }
        do {
            let prefs = try await repo.fetchPreferences()
            customPrompt = prefs.customSystemPrompt ?? ""
            lengthPref = prefs.responsePreferences?.length ?? ""
            stylePref = prefs.responsePreferences?.style ?? ""
            focusPref = prefs.responsePreferences?.focus ?? ""
            hasLoadedPreferences = true
            AppLogger.app.logInfo("Preferences refreshed from server")
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Display helpers

    private func displayForLength(_ value: String) -> String {
        switch value.lowercased() {
        case "short": return LocalizationKeys.prefLengthShort
        case "medium": return LocalizationKeys.prefLengthMedium
        case "detailed": return LocalizationKeys.prefLengthDetailed
        case "": return ""
        default: return value
        }
    }

    private func displayForStyle(_ value: String) -> String {
        switch value.lowercased() {
        case "conversational": return LocalizationKeys.prefStyleConversational
        case "academic": return LocalizationKeys.prefStyleAcademic
        case "technical": return LocalizationKeys.prefStyleTechnical
        case "": return ""
        default: return value
        }
    }

    private func displayForFocus(_ value: String) -> String {
        switch value.lowercased() {
        case "practical": return LocalizationKeys.prefFocusPractical
        case "theoretical": return LocalizationKeys.prefFocusTheoretical
        case "historical": return LocalizationKeys.prefFocusHistorical
        case "": return ""
        default: return value
        }
    }

    private func savePreferences() async {
        guard let repo = preferencesRepository else { return }
        isLoading = true
        error = nil
        do {
            let prefs = UserPreferencesModel(
                languagePreference: languageManager.currentLanguage.rawValue,
                customSystemPrompt: customPrompt.isEmpty ? nil : customPrompt,
                responsePreferences: ResponsePreferencesRequest(
                    length: lengthPref.isEmpty ? nil : lengthPref,
                    style: stylePref.isEmpty ? nil : stylePref,
                    focus: focusPref.isEmpty ? nil : focusPref
                )
            )
            try await repo.updatePreferences(prefs)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SettingsView(isAuthenticated: true, onLogout: {}, onSignIn: {})
                .previewDisplayName("Authenticated")
            SettingsView(isAuthenticated: false, onLogout: {}, onSignIn: {})
                .previewDisplayName("Guest")
        }
    }
}

// MARK: - Custom Prompt Editor

struct CustomPromptEditView: View {
    @Binding var customPrompt: String
    let onSave: () async -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text(LocalizationKeys.customPromptTitle.localizedKey)) {
                TextEditor(text: $customPrompt)
                    .font(AppTheme.Typography.body)
                    .frame(minHeight: 200, alignment: .topLeading)
                    .accessibilityIdentifier("CustomPromptEditor")
            }
        }
        .navigationTitle(LocalizationKeys.customPromptEditTitle.localizedKey)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(LocalizationKeys.save.localizedKey) {
                    Task {
                        await onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}
