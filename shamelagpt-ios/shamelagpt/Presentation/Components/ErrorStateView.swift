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
        self.title = title ?? LocalizationKeys.somethingWentWrong.localized
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
                Text(title)
                    .font(AppTheme.Typography.heading)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "arrow.clockwise")
                        Text(LocalizationKeys.tryAgain.localized)
                    }
                    .font(AppTheme.Typography.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.primary)
                    .cornerRadius(AppTheme.Layout.cornerRadius)
                }
                .accessibilityLabel(LocalizationKeys.tryAgain.localized)
                .accessibilityHint(LocalizationKeys.tryAgainAccessibilityHint.localized)
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
            title: LocalizationKeys.noInternetConnection.localized,
            message: LocalizationKeys.networkCheckConnection.localized,
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
            title: LocalizationKeys.unableToConnect.localized,
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
                Text(LocalizationKeys.permissionRequired.localized)
                    .font(AppTheme.Typography.heading)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)

                Text(LocalizationKeys.permissionMessage(permissionType))
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }

            Button(action: settingsAction) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "gearshape")
                    Text(LocalizationKeys.openSettings.localized)
                }
                .font(AppTheme.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.primary)
                .cornerRadius(AppTheme.Layout.cornerRadius)
            }
            .accessibilityLabel(LocalizationKeys.openSettings.localized)
            .accessibilityHint(LocalizationKeys.openSettingsAccessibilityHint.localized.localized(with: permissionType))
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

                Text(LocalizationKeys.noInternetConnection.localized)
                    .font(AppTheme.Typography.caption)

                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Color.red)
            .transition(.move(edge: .top).combined(with: .opacity))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(LocalizationKeys.noInternetConnection.localized)
            .accessibilityAddTraits(.isStaticText)
        }
    }
}

// MARK: - Preview Provider

#Preview("Error State") {
    ErrorStateView(
        message: LocalizationKeys.failedToLoadData.localized,
        retryAction: {}
    )
}

#Preview("Network Error") {
    NetworkErrorView(retryAction: {})
}

#Preview("Permission Denied") {
    PermissionDeniedView(
        permissionType: "Microphone",
        settingsAction: {}
    )
}

#Preview("Network Banner") {
    VStack {
        NetworkStatusBanner(networkMonitor: NetworkMonitor.shared)
        Spacer()
    }
}
