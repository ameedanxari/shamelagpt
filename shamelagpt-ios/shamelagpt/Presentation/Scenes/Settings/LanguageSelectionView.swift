//
//  LanguageSelectionView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

struct LanguageSelectionView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(Language.allCases) { language in
                Button(action: {
                    selectLanguage(language)
                }) {
                    // Temporary UI-test bypass: use default font for all language rows.
                    let rowFont: Font = .body

                    HStack {
                        Text(language.displayName)
                            .font(rowFont)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .environment(\.locale, {
                                switch language {
                                case .arabic:
                                    return Locale(identifier: "ar")
                                case .urdu:
                                    return Locale(identifier: "ur")
                                default:
                                    return Locale(identifier: "en")
                                }
                            }())
                            .onAppear {
                                // Log which font will be used for this language label
                                let langCode = language.rawValue
                                AppLogger.ui.logDebug("LanguageSelection row for \(language.displayName) (code=\(langCode)) uses default system font")
                            }

                        Spacer()

                        if languageManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppTheme.Colors.primary)
                                .font(rowFont)
                                .accessibilityIdentifier(AccessibilityID.Settings.languageCheckmark(language.rawValue))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier(AccessibilityID.Settings.languageOption(language.rawValue))
            }

            Section {
                Text(LocalizationKeys.languageFontRestartNote.localizedKey)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
        }
        .navigationTitle(LocalizationKeys.language.localizedKey)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectLanguage(_ language: Language) {
        AppLogger.ui.logInfo("LanguageSelectionView.selectLanguage: selected=\(language.displayName) code=\(language.rawValue)")
        languageManager.setLanguage(language)

        // Automatically navigate back after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

struct LanguageSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LanguageSelectionView()
        }
    }
}
