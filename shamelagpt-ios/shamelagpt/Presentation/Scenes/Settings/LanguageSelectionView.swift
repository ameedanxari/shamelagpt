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
                    HStack {
                        Text(language.displayName)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.primaryText)

                        Spacer()

                        if languageManager.currentLanguage == language {
                            Image(systemName: "checkmark")
                                .foregroundColor(AppTheme.Colors.primary)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func selectLanguage(_ language: Language) {
        languageManager.setLanguage(language)

        // Automatically navigate back after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        LanguageSelectionView()
    }
}
