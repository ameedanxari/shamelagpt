//
//  AuthView.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import SwiftUI
import AuthenticationServices

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

            // Divider
            HStack {
                Rectangle().frame(height: 1).foregroundColor(DesignSystem.Colors.textSecondary(colorScheme).opacity(0.3))
                Text("OR")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                Rectangle().frame(height: 1).foregroundColor(DesignSystem.Colors.textSecondary(colorScheme).opacity(0.3))
            }
            .padding(.vertical, DesignSystem.Spacing.xs)

            // Apple Sign-In button
            SignInWithAppleButton(
                viewModel.isLoginMode ? .signIn : .signUp,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                           let identityTokenData = appleIDCredential.identityToken,
                           let idToken = String(data: identityTokenData, encoding: .utf8) {
                            viewModel.appleSignIn(idToken: idToken, onSuccess: onAuthenticated)
                        } else {
                            viewModel.errorMessage = "Failed to get Apple ID token"
                        }
                    case .failure(let error):
                        if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 50)
            .cornerRadius(DesignSystem.Layout.cornerRadius)
            .disabled(viewModel.isLoading)

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

