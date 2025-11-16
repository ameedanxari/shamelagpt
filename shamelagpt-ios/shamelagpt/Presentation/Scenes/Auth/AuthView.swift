//
//  AuthView.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    let onAuthenticated: () -> Void
    let onContinueAsGuest: () -> Void

    var body: some View {
        ZStack {
            DesignSystem.Colors.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.md) {
            // Title
            Text(viewModel.isLoginMode ? LocalizationKeys.authSignIn.localizedKey : LocalizationKeys.authCreateAccount.localizedKey)
                .font(DesignSystem.Typography.title2)
                .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))

            // Email field
            TextField(LocalizationKeys.authEmail.localizedKey, text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
                .textFieldStyle(.themed)
                .accessibilityIdentifier(AccessibilityID.Auth.emailTextField)

            // Password field
            SecureField(LocalizationKeys.authPassword.localizedKey, text: $viewModel.password)
                .textContentType(.password)
                .textFieldStyle(.themed)
                .accessibilityIdentifier(AccessibilityID.Auth.passwordTextField)

            // Display name (signup only)
            if !viewModel.isLoginMode {
                TextField(LocalizationKeys.authDisplayName.localizedKey, text: $viewModel.displayName)
                    .textFieldStyle(.themed)
                    .accessibilityIdentifier(AccessibilityID.Auth.displayNameTextField)
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                .foregroundColor(DesignSystem.Colors.error)
                .font(DesignSystem.Typography.subheadline)
                .accessibilityIdentifier(AccessibilityID.Auth.errorLabel)
            }

            // Primary button (gradient)
            Button {
                if !viewModel.isLoading {
                    viewModel.authenticate(onSuccess: onAuthenticated)
                }
            } label: {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(viewModel.isLoginMode ? LocalizationKeys.authSignInButton.localizedKey : LocalizationKeys.authSignUp.localizedKey)
                }
            }
            .buttonStyle(.primary)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier(viewModel.isLoginMode ? AccessibilityID.Auth.signInButton : AccessibilityID.Auth.signUpButton)

            // Secondary button (outlined)
            Button {
                onContinueAsGuest()
            } label: {
                Text(LocalizationKeys.authContinueAsGuest.localizedKey)
            }
            .buttonStyle(.secondary)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier(AccessibilityID.Auth.continueAsGuestButton)

            // Toggle mode link
            Button {
                viewModel.toggleMode()
            } label: {
                Text(viewModel.isLoginMode ? LocalizationKeys.authNeedAccount.localizedKey : LocalizationKeys.authHaveAccount.localizedKey)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            .padding(.top, DesignSystem.Spacing.xs)
            .accessibilityIdentifier(AccessibilityID.Auth.toggleModeButton)
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

