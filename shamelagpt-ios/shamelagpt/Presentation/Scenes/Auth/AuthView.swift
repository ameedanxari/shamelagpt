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

            // Social sign-in sits above the credential form, matching the web app.
            Button {
                if !viewModel.isLoading {
                    viewModel.signInWithGoogle(onSuccess: onAuthenticated)
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    GoogleGlyph()
                    Text(LocalizationKeys.authContinueWithGoogle.localizedKey)
                }
            }
            .buttonStyle(.secondary)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier(AccessibilityID.Auth.googleSignInButton)

            Button {
                if !viewModel.isLoading {
                    viewModel.signInWithApple(onSuccess: onAuthenticated)
                }
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "apple.logo")
                    Text(LocalizationKeys.authContinueWithApple.localizedKey)
                }
            }
            .buttonStyle(.secondary)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier(AccessibilityID.Auth.appleSignInButton)

            // "OR" divider
            HStack(spacing: DesignSystem.Spacing.sm) {
                dividerRule
                Text(LocalizationKeys.authOrDivider.localizedKey)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                dividerRule
            }

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

    private var dividerRule: some View {
        Rectangle()
            .fill(DesignSystem.Colors.textSecondary(colorScheme).opacity(0.3))
            .frame(height: 1)
    }
}

/// The Google "G" drawn as vector shapes.
///
/// Google's brand terms require the official mark and forbid recolouring it, so it cannot
/// be an SF Symbol or a tinted template image. Drawing it keeps the four brand colours
/// exact without adding an asset that has to be exported at three scales.
private struct GoogleGlyph: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.918, green: 0.263, blue: 0.208), lineWidth: 4)   // red
                .rotationEffect(.degrees(-135))
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.984, green: 0.737, blue: 0.020), lineWidth: 4)   // yellow
                .rotationEffect(.degrees(135))
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.204, green: 0.659, blue: 0.325), lineWidth: 4)   // green
                .rotationEffect(.degrees(45))
            Circle()
                .trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0.259, green: 0.522, blue: 0.957), lineWidth: 4)   // blue
                .rotationEffect(.degrees(-45))
            Rectangle()
                .fill(Color(red: 0.259, green: 0.522, blue: 0.957))
                .frame(width: 8, height: 4)
                .offset(x: 4, y: 0)
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}

