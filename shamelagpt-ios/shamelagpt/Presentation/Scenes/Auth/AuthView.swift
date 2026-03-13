//
//  AuthView.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import GoogleSignIn
import GoogleSignInSwift
import SwiftUI
import UIKit

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

                // "or" divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(DesignSystem.Colors.border(colorScheme))
                    Text(LocalizationKeys.authOrDivider.localizedKey)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundColor(DesignSystem.Colors.textSecondary(colorScheme))
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(DesignSystem.Colors.border(colorScheme))
                }
                .padding(.vertical, DesignSystem.Spacing.xs)

                // Use Google-provided SwiftUI button to match brand/style guidance.
                GoogleSignInButton(
                    scheme: googleSignInButtonScheme,
                    style: .wide,
                    state: viewModel.isLoading ? .disabled : .normal
                ) {
                    dismissKeyboard()
                    guard !viewModel.isLoading else { return }
                    handleGoogleSignIn()
                }
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier(AccessibilityID.Auth.googleSignInButton)

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

    private var googleSignInButtonScheme: GoogleSignInButtonColorScheme {
        colorScheme == .dark ? .dark : .light
    }

    private func handleGoogleSignIn() {
        guard let presentingViewController = activePresentingViewController() else {
            AppLogger.auth.logWarning("google sign-in aborted: no presenting view controller")
            viewModel.setError(LocalizationKeys.authGoogleSignInFailed.localized)
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            if let error {
                if isGoogleSignInCancellation(error) {
                    AppLogger.auth.logInfo("google sign-in cancelled by user")
                    return
                }
                AppLogger.auth.logWarning("google sdk sign-in failed reason=\(type(of: error))")
                AppLogger.auth.logError("google sdk sign-in error", error: error)
                Task { @MainActor in
                    viewModel.setError(LocalizationKeys.authGoogleSignInFailed.localized)
                }
                return
            }

            guard let idToken = result?.user.idToken?.tokenString, !idToken.isEmpty else {
                AppLogger.auth.logWarning("google sign-in failed: missing id token")
                Task { @MainActor in
                    viewModel.setError(LocalizationKeys.authGoogleSignInFailed.localized)
                }
                return
            }

            Task { @MainActor in
                viewModel.googleSignIn(idToken: idToken, onSuccess: onAuthenticated)
            }
        }
    }

    private func activePresentingViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
        let windows = scenes.flatMap(\.windows)
        let keyWindow = windows.first { $0.isKeyWindow } ?? windows.first
        return topViewController(from: keyWindow?.rootViewController)
    }

    private func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root else { return nil }
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }

    private func isGoogleSignInCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return true
        }
        if nsError.code == -5 {
            // Google Sign-In cancellation code
            return true
        }
        return nsError.localizedDescription.lowercased().contains("cancel")
    }
}
