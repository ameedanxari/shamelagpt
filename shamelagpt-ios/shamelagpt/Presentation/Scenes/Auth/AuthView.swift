//
//  AuthView.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import AuthenticationServices
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
            // Background tap to dismiss keyboard — sits behind all interactive elements
            DesignSystem.Colors.background(colorScheme)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissKeyboard()
                }

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
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.error)
                        Text(error)
                            .foregroundColor(DesignSystem.Colors.error)
                            .font(DesignSystem.Typography.subheadline)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.error.opacity(0.08))
                    .cornerRadius(AppTheme.Layout.cornerRadius)
                    .accessibilityIdentifier(AccessibilityID.Auth.errorLabel)
                }

                // Success is rendered in the primary colour, not the error style — a reset
                // email being sent is a good outcome and should not look like a failure.
                if let info = viewModel.infoMessage {
                    HStack(alignment: .top, spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                        Text(info)
                            .foregroundColor(DesignSystem.Colors.textPrimary(colorScheme))
                            .font(DesignSystem.Typography.subheadline)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.Colors.primary.opacity(0.08))
                    .cornerRadius(AppTheme.Layout.cornerRadius)
                    .accessibilityIdentifier(AccessibilityID.Auth.infoLabel)
                }

                // Sign-in only: there is no password to recover while creating an account.
                if viewModel.isLoginMode {
                    HStack {
                        Spacer()
                        Button {
                            if !viewModel.isLoading {
                                dismissKeyboard()
                                viewModel.forgotPassword()
                            }
                        } label: {
                            Text(LocalizationKeys.authForgotPassword.localizedKey)
                                .font(DesignSystem.Typography.footnote)
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .disabled(viewModel.isLoading)
                        .accessibilityIdentifier(AccessibilityID.Auth.forgotPasswordButton)
                    }
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
                // Matches the Apple button and the rest of the stack. Without an explicit
                // frame the SDK button renders at its own intrinsic size, so it sat at a
                // different height and width from every other control on the screen.
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .accessibilityIdentifier(AccessibilityID.Auth.googleSignInButton)

                SignInWithAppleButton(viewModel.isLoginMode ? .signIn : .signUp) { request in
                    viewModel.clearError()
                    AppLogger.appleAuth.logInfo(
                        prefix: AppLogger.LogPrefix.appleAuth,
                        "event=view.appleButton.request mode=\(viewModel.isLoginMode ? "signIn" : "signUp") isLoading=\(viewModel.isLoading) scopes=fullName,email"
                    )
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    AppLogger.appleAuth.logInfo(
                        prefix: AppLogger.LogPrefix.appleAuth,
                        "event=view.appleButton.completion"
                    )
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(appleSignInButtonStyle)
                .frame(height: 44)
                .accessibilityIdentifier(AccessibilityID.Auth.appleSignInButton)

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
            .onAppear {
                applyUITestAuthMode()
            }
        }
    }

    private func applyUITestAuthMode() {
        let environment = ProcessInfo.processInfo.environment
        guard environment["UI_TESTING"] == "1",
              environment["UITEST_AUTH_MODE"]?.lowercased() == "signup",
              viewModel.isLoginMode else {
            return
        }
        viewModel.isLoginMode = false
        viewModel.errorMessage = nil
    }

    private func dismissKeyboard() {
        focusedField = nil
        hideKeyboard()
    }

    private var googleSignInButtonScheme: GoogleSignInButtonColorScheme {
        colorScheme == .dark ? .dark : .light
    }

    private var appleSignInButtonStyle: SignInWithAppleButton.Style {
        colorScheme == .dark ? .white : .black
    }

    private func handleGoogleSignIn() {
        viewModel.clearError()
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

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        AppLogger.appleAuth.logInfo(
            prefix: AppLogger.LogPrefix.appleAuth,
            "event=view.handleAppleSignIn.resultReceived"
        )
        switch result {
        case .success(let authorization):
            AppLogger.appleAuth.logDebug(
                prefix: AppLogger.LogPrefix.appleAuth,
                "event=view.handleAppleSignIn.authorizationSuccess credentialType=\(type(of: authorization.credential))"
            )
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                AppLogger.appleAuth.logWarning(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=view.handleAppleSignIn.unexpectedCredential credentialType=\(type(of: authorization.credential))"
                )
                viewModel.setError(LocalizationKeys.authAppleSignInFailed.localized)
                return
            }

            let authorizationCodeState = appleIDCredential.authorizationCode.map { "present(length=\($0.count))" } ?? "nil"
            let identityTokenState = appleIDCredential.identityToken.map { "present(length=\($0.count))" } ?? "nil"
            AppLogger.appleAuth.logDebug(
                prefix: AppLogger.LogPrefix.appleAuth,
                "event=view.handleAppleSignIn.credential userId=\(AppLogger.redactedId(appleIDCredential.user)) email=\(AppLogger.redactedEmail(appleIDCredential.email)) fullNameGivenPresent=\(appleIDCredential.fullName?.givenName?.isEmpty == false) fullNameFamilyPresent=\(appleIDCredential.fullName?.familyName?.isEmpty == false) identityToken=\(identityTokenState) authorizationCode=\(authorizationCodeState)"
            )

            guard let identityTokenData = appleIDCredential.identityToken,
                  let idToken = String(data: identityTokenData, encoding: .utf8),
                  !idToken.isEmpty else {
                AppLogger.appleAuth.logWarning(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=view.handleAppleSignIn.missingIdentityToken identityToken=\(appleIDCredential.identityToken == nil ? "nil" : "presentButNotUTF8Decodable")"
                )
                viewModel.setError(LocalizationKeys.authAppleSignInFailed.localized)
                return
            }

            AppLogger.appleAuth.logInfo(
                prefix: AppLogger.LogPrefix.appleAuth,
                "event=view.handleAppleSignIn.identityTokenReady idTokenLength=\(idToken.count)"
            )
            logAppleIdentityTokenDiagnostics(idToken)
            viewModel.appleSignIn(idToken: idToken, onSuccess: onAuthenticated)

        case .failure(let error):
            if isAppleSignInCancellation(error) {
                AppLogger.appleAuth.logInfo(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=view.handleAppleSignIn.cancelled"
                )
                return
            }
            let nsError = error as NSError
            AppLogger.appleAuth.logWarning(
                prefix: AppLogger.LogPrefix.appleAuth,
                "event=view.handleAppleSignIn.failure domain=\(nsError.domain) code=\(nsError.code) errorType=\(type(of: error)) description=\(error.localizedDescription)"
            )
            AppLogger.appleAuth.logError(
                prefix: AppLogger.LogPrefix.appleAuth,
                "event=view.handleAppleSignIn.error",
                error: error
            )
            viewModel.setError(LocalizationKeys.authAppleSignInFailed.localized)
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

    private func isAppleSignInCancellation(_ error: Error) -> Bool {
        guard let authError = error as? ASAuthorizationError else {
            return false
        }
        return authError.code == .canceled
    }

    private func logAppleIdentityTokenDiagnostics(_ idToken: String) {
        let parts = idToken.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2,
              let header = decodeJWTPart(parts[0]),
              let payload = decodeJWTPart(parts[1]) else {
            AppLogger.appleAuth.logWarning(
                prefix: AppLogger.LogPrefix.appleAuth,
                "event=view.handleAppleSignIn.identityTokenClaims.decodeFailed partCount=\(parts.count)"
            )
            return
        }

        let now = Int(Date().timeIntervalSince1970)
        let expiresIn = intValue(payload["exp"]).map { $0 - now }.map(String.init) ?? "nil"
        let issuedAgo = intValue(payload["iat"]).map { now - $0 }.map(String.init) ?? "nil"
        AppLogger.appleAuth.logInfo(
            prefix: AppLogger.LogPrefix.appleAuth,
            "event=view.handleAppleSignIn.identityTokenClaims kid=\(stringValue(header["kid"])) alg=\(stringValue(header["alg"])) iss=\(stringValue(payload["iss"])) aud=\(audienceValue(payload["aud"])) sub=\(AppLogger.redactedId(stringValue(payload["sub"]))) email=\(AppLogger.redactedEmail(stringValue(payload["email"]))) emailVerified=\(stringValue(payload["email_verified"])) expiresInSeconds=\(expiresIn) issuedAgoSeconds=\(issuedAgo)"
        )
    }

    private func decodeJWTPart(_ part: Substring) -> [String: Any]? {
        var base64 = String(part)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let padding = base64.count % 4
        if padding > 0 {
            base64.append(String(repeating: "=", count: 4 - padding))
        }
        guard let data = Data(base64Encoded: base64),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            return nil
        }
        return dictionary
    }

    private func stringValue(_ value: Any?) -> String {
        switch value {
        case let value as String:
            return value
        case let value as NSNumber:
            return value.stringValue
        case .some(let value):
            return String(describing: value)
        case .none:
            return "nil"
        }
    }

    private func audienceValue(_ value: Any?) -> String {
        if let values = value as? [String] {
            return values.joined(separator: ",")
        }
        return stringValue(value)
    }

    private func intValue(_ value: Any?) -> Int? {
        switch value {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }
}
