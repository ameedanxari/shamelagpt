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
                    // Prefer the language-specific font so Arabic script renders correctly even before locale switches.
                    let languageCodeForFont: String? = language.rawValue
                    let rowFont = FontRegistry.shared.swiftUIFont(forLanguage: languageCodeForFont, textStyle: .body)

                    HStack {
                        Text(language.displayName)
                            .font(rowFont)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .environment(\.locale, language == .arabic ? Locale(identifier: "ar") : Locale.current)
                            .onAppear {
                                // Log which font will be used for this language label
                                let langCode = language.rawValue
                                let uiFont = FontRegistry.shared.uiFont(forLanguage: languageCodeForFont, textStyle: .body)
                                AppLogger.ui.logDebug("LanguageSelection row for \(language.displayName) (code=\(langCode)) will render with font=\(uiFont.fontName) size=\(uiFont.pointSize)")
                            }

                        Spacer()

                        if languageManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppTheme.Colors.primary)
                                .font(rowFont)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
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
