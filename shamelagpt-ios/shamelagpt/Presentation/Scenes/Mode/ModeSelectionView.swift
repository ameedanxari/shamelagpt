//
//  ModeSelectionView.swift
//  ShamelaGPT
//

import SwiftUI

/// Full-screen mode picker, mirroring the web app's `/mode-selection` route.
struct ModeSelectionView: View {
    @ObservedObject var viewModel: ModeSelectionViewModel
    @Environment(\.colorScheme) private var colorScheme

    /// Guests may read about fact-check but not enter it — the guest chat route never
    /// applies a mode server-side, so offering it would be a lie.
    let isGuest: Bool
    let onComplete: (ConversationMode) -> Void
    var onDismiss: (() -> Void)?

    var body: some View {
        ZStack {
            DesignSystem.Colors.background(colorScheme).ignoresSafeArea()

            // The cards scroll; the action bar is attached as a bottom safe-area inset.
            //
            // It must be an inset rather than a plain VStack row. When this screen is
            // pushed from Settings there is a tab bar, and iOS 26 renders a floating tab
            // bar whose `AdditionalDimmingOverlay` extends well above the bar itself. A
            // button merely placed at the bottom lands underneath that overlay: it looks
            // perfectly tappable and renders normally, but the overlay swallows the touch,
            // so nothing happens and no error is produced. `safeAreaInset` makes SwiftUI
            // account for the tab bar and keeps the primary action actually hittable.
            ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        header

                        ForEach(ConversationMode.selectable) { mode in
                            ModeCard(
                                mode: mode,
                                isSelected: viewModel.selected == mode,
                                isLocked: isGuest && mode.requiresAuthentication,
                                colorScheme: colorScheme
                            ) {
                                viewModel.select(mode)
                            }
                        }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: DesignSystem.Spacing.sm) {
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(DesignSystem.Typography.subheadline)
                            .foregroundColor(DesignSystem.Colors.error)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier(AccessibilityID.Mode.errorLabel)
                    }

                    Button {
                        viewModel.confirm(onComplete: onComplete)
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(LocalizationKeys.modeEnterButton.localizedKey)
                        }
                    }
                    .buttonStyle(.primary)
                    .disabled(viewModel.isSaving || (isGuest && viewModel.selected.requiresAuthentication))
                    .accessibilityIdentifier(AccessibilityID.Mode.confirmButton)

                    if let onDismiss {
                        Button(action: onDismiss) {
                            Text(LocalizationKeys.cancel.localizedKey)
                                .font(DesignSystem.Typography.footnote)
                                .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                        }
                        .accessibilityIdentifier(AccessibilityID.Mode.cancelButton)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.bottom, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.background(colorScheme))
            }
        }
        .accessibilityIdentifier(AccessibilityID.Mode.screen)
    }

    private var header: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text(LocalizationKeys.modeSelectionTitle.localizedKey)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                .multilineTextAlignment(.center)
            Text(LocalizationKeys.modeSelectionSubtitle.localizedKey)
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, DesignSystem.Spacing.lg)
    }
}

/// One mode option.
private struct ModeCard: View {
    let mode: ConversationMode
    let isSelected: Bool
    let isLocked: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: mode.symbolName)
                        .font(.title2)
                        .foregroundColor(isSelected ? DesignSystem.Colors.primary
                                                    : DesignSystem.Colors.textSecondary(colorScheme))
                    Text(mode.titleKey.localizedKey)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                    Spacer()
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                    } else if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }

                Text(mode.taglineKey.localizedKey)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                    .multilineTextAlignment(.leading)

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(mode.bulletKeys, id: \.self) { key in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                            Text("•")
                            Text(key.localizedKey)
                        }
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                    }
                }

                if isLocked {
                    Text(LocalizationKeys.modeSignInRequired.localizedKey)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.error)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.10) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? DesignSystem.Colors.primary
                                   : DesignSystem.Colors.textSecondary(colorScheme).opacity(0.25),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.6 : 1)
        .accessibilityIdentifier(
            mode == .factCheck ? AccessibilityID.Mode.factCheckCard : AccessibilityID.Mode.researchCard
        )
    }
}
