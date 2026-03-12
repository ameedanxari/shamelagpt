//
//  AuthView.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import SwiftUI

struct AuthView: View {
    private enum Field: Hashable {
        case email
        case password
        case displayName
    }

    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: Field?
    let onAuthenticated: () -> Void
    let onContinueAsGuest: () -> Void

    var body: some View {
        ZStack {
            DesignSystem.Colors.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.md) {
                Text(viewModel.isLoginMode ? LocalizationKeys.authSignIn.localizedKey : LocalizationKeys.authCreateAccount.localizedKey)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))

                TextField(LocalizationKeys.authEmail.localizedKey, text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .textFieldStyle(.themed)
                    .focused($focusedField, equals: .email)
                    .accessibilityIdentifier(AccessibilityID.Auth.emailTextField)

                SecureField(LocalizationKeys.authPassword.localizedKey, text: $viewModel.password)
                    .textContentType(.password)
                    .textFieldStyle(.themed)
                    .focused($focusedField, equals: .password)
                    .accessibilityIdentifier(AccessibilityID.Auth.passwordTextField)

                if !viewModel.isLoginMode {
                    TextField(LocalizationKeys.authDisplayName.localizedKey, text: $viewModel.displayName)
                        .textFieldStyle(.themed)
                        .focused($focusedField, equals: .displayName)
                        .accessibilityIdentifier(AccessibilityID.Auth.displayNameTextField)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(DesignSystem.Colors.error)
                        .font(DesignSystem.Typography.subheadline)
                        .accessibilityIdentifier(AccessibilityID.Auth.errorLabel)
                }

                Button {
                    dismissKeyboard()
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

                Button {
                    dismissKeyboard()
                    onContinueAsGuest()
                } label: {
                    Text(LocalizationKeys.authContinueAsGuest.localizedKey)
                }
                .buttonStyle(.secondary)
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier(AccessibilityID.Auth.continueAsGuestButton)

                Button {
                    dismissKeyboard()
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
            .contentShape(Rectangle())
            .onTapGesture {
                dismissKeyboard()
            }
        }
    }

    private func dismissKeyboard() {
        focusedField = nil
        hideKeyboard()
    }
}
