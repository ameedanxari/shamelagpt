//
//  ErrorStateView.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import SwiftUI

/// A reusable view for displaying error states with retry functionality
struct ErrorStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let retryAction: (() -> Void)?

    init(
        title: String? = nil,
        message: String,
        systemImage: String = "exclamationmark.triangle.fill",
        retryAction: (() -> Void)? = nil
    ) {
        // Store raw keys or plain strings; rendering will wrap in LocalizedStringKey
        self.title = title ?? LocalizationKeys.somethingWentWrong
        self.message = message
        self.systemImage = systemImage
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))
                .accessibilityHidden(true)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(LocalizedStringKey(title))
                    .font(AppTheme.Typography.heading)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text(LocalizedStringKey(message))
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                        Text(LocalizationKeys.tryAgain.localizedKey)
                    }
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.Layout.cornerRadius)
                }
                .accessibilityLabel(Text(LocalizationKeys.tryAgain.localizedKey))
                .accessibilityHint(Text(LocalizationKeys.tryAgainAccessibilityHint.localizedKey))
            }
        }
        .padding(AppTheme.Spacing.xl)
        .accessibilityElement(children: .contain)
    }
}

/// A specialized error view for network connectivity issues
struct NetworkErrorView: View {
    let retryAction: (() -> Void)?

    var body: some View {
        ErrorStateView(
            title: LocalizationKeys.noInternetConnection,
            message: LocalizationKeys.networkCheckConnection,
            systemImage: "wifi.slash",
            retryAction: retryAction
        )
    }
}

/// A specialized error view for API failures
struct APIErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?

    var body: some View {
        ErrorStateView(
            title: LocalizationKeys.unableToConnect,
            message: error.localizedDescription,
            systemImage: "exclamationmark.triangle.fill",
            retryAction: retryAction
        )
    }
}

/// A specialized error view for permission denied
struct PermissionDeniedView: View {
    let permissionType: String
    let settingsAction: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.8))

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(LocalizationKeys.permissionRequired.localizedKey)
                    .font(AppTheme.Typography.heading)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                Text(LocalizedStringKey(LocalizationKeys.permissionMessage(permissionType)))
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: settingsAction) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "gearshape")
                    Text(LocalizationKeys.openSettings.localizedKey)
                }
                .font(AppTheme.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Layout.cornerRadius)
            }
            .accessibilityLabel(Text(LocalizationKeys.openSettings.localizedKey))
            .accessibilityHint(Text(L10n.formattedKeyWithLocalizedArgs(LocalizationKeys.openSettingsAccessibilityHint, argKeys: permissionType)))
        }
        .padding(AppTheme.Spacing.xl)
    }
}

/// A banner that displays network connectivity status
struct NetworkStatusBanner: View {
    @ObservedObject var networkMonitor: NetworkMonitor

    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14))

                Text(LocalizationKeys.noInternetConnection.localizedKey)
                    .font(AppTheme.Typography.caption)

                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(DesignSystem.Colors.error)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(LocalizationKeys.noInternetConnection.localizedKey))
            .accessibilityAddTraits(.isStaticText)
        }
    }
}

struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorStateView(
                message: LocalizationKeys.failedToLoadData,
                retryAction: {}
            )
            .previewDisplayName("Error State")

            NetworkErrorView(retryAction: {})
                .previewDisplayName("Network Error")

            PermissionDeniedView(
                permissionType: "Microphone",
                settingsAction: {}
            )
            .previewDisplayName("Permission Denied")

            VStack {
                NetworkStatusBanner(networkMonitor: NetworkMonitor.shared)
                Spacer()
            }
            .previewDisplayName("Network Banner")
        }
    }
}
