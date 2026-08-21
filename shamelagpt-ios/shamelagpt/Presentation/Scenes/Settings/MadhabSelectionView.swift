//
//  MadhabSelectionView.swift
//  ShamelaGPT
//
//  Created by Codex on 21/08/2026.
//

import SwiftUI

/// Card list for picking a school of jurisprudence, mirroring the web's
/// School of Thought section: name, Arabic name, and founder + death year.
struct MadhabSelectionView: View {
    @ObservedObject var viewModel: MadhabPreferenceViewModel

    var body: some View {
        List {
            Section {
                ForEach(MadhabPreference.allCases) { madhab in
                    MadhabCardRow(
                        madhab: madhab,
                        isSelected: viewModel.selection == madhab,
                        isDisabled: viewModel.isSaving
                    ) {
                        Task { await viewModel.select(madhab) }
                    }
                }
            } header: {
                Text(LocalizationKeys.madhabTitleArabic.localizedKey)
                    .font(AppTheme.Typography.caption)
            } footer: {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(LocalizationKeys.madhabHelp.localizedKey)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.Typography.small)
                            .foregroundColor(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, AppTheme.Spacing.xs)
            }
        }
        .navigationTitle(LocalizationKeys.madhabTitle.localizedKey)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.isLoading || viewModel.isSaving {
                    ProgressView()
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

/// One school card. The Arabic name is always rendered in Arabic script and
/// right-to-left regardless of the app language, matching the web, so it reads
/// correctly even when the surrounding UI is LTR English.
private struct MadhabCardRow: View {
    let madhab: MadhabPreference
    let isSelected: Bool
    let isDisabled: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(madhab.titleKey.localizedKey)
                        .font(AppTheme.Typography.body.weight(.semibold))
                        .foregroundColor(isSelected ? AppTheme.Colors.primary : AppTheme.Colors.primaryText)

                    Text(madhab.arabicNameKey.localizedKey)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                        .environment(\.locale, Locale(identifier: "ar"))
                        .environment(\.layoutDirection, .rightToLeft)

                    Text(madhab.descriptionKey.localizedKey)
                        .font(AppTheme.Typography.small)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: AppTheme.Spacing.xs)

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(AppTheme.Typography.body)
                        .accessibilityIdentifier(AccessibilityID.Settings.madhabCheckmark(madhab.rawValue))
                }
            }
            .padding(.vertical, AppTheme.Spacing.xs)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .accessibilityIdentifier(AccessibilityID.Settings.madhabOption(madhab.rawValue))
        .accessibilityLabel(
            Text(
                L10n.formattedKeyWithLocalizedArgs(
                    LocalizationKeys.madhabSelectAccessibility,
                    argKeys: madhab.titleKey
                )
            )
        )
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

struct MadhabSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MadhabSelectionView(viewModel: MadhabPreferenceViewModel(authRepository: nil))
        }
    }
}
