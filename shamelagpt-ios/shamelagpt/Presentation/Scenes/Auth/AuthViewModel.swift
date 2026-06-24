//
//  AuthViewModel.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var displayName: String = ""
    @Published var isLoginMode: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let authRepository: AuthRepository

    init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        if ProcessInfo.processInfo.environment["UI_TESTING"] == "1",
           ProcessInfo.processInfo.environment["UITEST_AUTH_MODE"]?.lowercased() == "signup" {
            isLoginMode = false
        }
    }

    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil
    }

    func setError(_ message: String) {
        errorMessage = message
    }

    func clearError() {
        errorMessage = nil
    }

    func authenticate(onSuccess: @escaping () -> Void) {
        let mode = isLoginMode ? "login" : "signup"
        AppLogger.auth.logInfo(
            prefix: AppLogger.LogPrefix.authState,
            "event=form.authenticate.requested mode=\(mode) email=\(AppLogger.redactedEmail(email)) displayNamePresent=\(!displayName.isEmpty)"
        )
        guard !email.isEmpty, !password.isEmpty else {
            AppLogger.auth.logWarning(
                prefix: AppLogger.LogPrefix.authState,
                "event=form.authenticate.validationFailed mode=\(mode) reason=missingRequiredFields emailPresent=\(!email.isEmpty) passwordPresent=\(!password.isEmpty)"
            )
            errorMessage = "Email and password are required"
            return
        }

        Task {
            isLoading = true
            errorMessage = nil
            do {
                if isLoginMode {
                    AppLogger.auth.logDebug(
                        prefix: AppLogger.LogPrefix.authState,
                        "event=form.login.repositoryCall.start email=\(AppLogger.redactedEmail(email))"
                    )
                    _ = try await authRepository.login(
                        request: LoginRequest(email: email, password: password)
                    )
                } else {
                    AppLogger.auth.logDebug(
                        prefix: AppLogger.LogPrefix.authState,
                        "event=form.signup.repositoryCall.start email=\(AppLogger.redactedEmail(email)) displayNamePresent=\(!displayName.isEmpty)"
                    )
                    _ = try await authRepository.signup(
                        request: SignupRequest(
                            email: email,
                            password: password,
                            displayName: displayName.isEmpty ? nil : displayName
                        )
                    )
                }
                isLoading = false
                AppLogger.auth.logInfo(
                    prefix: AppLogger.LogPrefix.authState,
                    "event=form.authenticate.success mode=\(mode)"
                )
                onSuccess()
            } catch {
                isLoading = false
                AppLogger.auth.logWarning(
                    prefix: AppLogger.LogPrefix.authState,
                    "event=form.authenticate.failure mode=\(mode) reason=\(type(of: error)) message=\(error.localizedDescription)"
                )
                if shouldShowInvalidCredentialsError(error: error, isLoginMode: isLoginMode) {
                    AppLogger.auth.logWarning("login rejected for invalid credentials; showing friendly copy")
                    errorMessage = LocalizationKeys.authInvalidCredentials.localized
                } else if shouldSuggestSignInAfterSignup(error: error, isLoginMode: isLoginMode) {
                    AppLogger.auth.logWarning("signup rejected for existing account; suggesting login")
                    errorMessage = LocalizationKeys.authEmailExistsUseLogin.localized
                } else {
                    AppLogger.auth.logError("authentication error", error: error)
                    errorMessage = error.userFacingMessage
                }
            }
        }
    }

    private func shouldShowInvalidCredentialsError(error: Error, isLoginMode: Bool) -> Bool {
        guard isLoginMode else { return false }

        if let networkError = error as? NetworkError {
            switch networkError {
            case .httpError(let statusCode):
                return statusCode == 400 || statusCode == 401
            case .badRequest:
                return true
            default:
                break
            }
        }

        let message = error.localizedDescription.lowercased()
        return message.contains("invalid credential") ||
            message.contains("invalid email or password") ||
            message.contains("email or password")
    }

    func forgotPassword() {
        guard !email.isEmpty else {
            AppLogger.auth.logWarning("forgot password validation failed: email missing")
            errorMessage = "Email is required to reset password"
            return
        }

        Task {
            isLoading = true
            errorMessage = nil
            do {
                AppLogger.auth.logInfo("forgot password request started")
                try await authRepository.forgotPassword(email: email)
                isLoading = false
                AppLogger.auth.logInfo("forgot password request completed")
                // On success, we might want to show a success message or alert
                // For now, clear error and stop loading
            } catch {
                isLoading = false
                AppLogger.auth.logWarning("forgot password request failed reason=\(type(of: error))")
                AppLogger.auth.logError("forgot password error", error: error)
                errorMessage = error.userFacingMessage
            }
        }
    }

    func googleSignIn(idToken: String, onSuccess: @escaping () -> Void) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                AppLogger.auth.logInfo("google sign-in request started")
                _ = try await authRepository.googleSignIn(request: GoogleSignInRequest(idToken: idToken))
                isLoading = false
                AppLogger.auth.logInfo("google sign-in success")
                onSuccess()
            } catch {
                isLoading = false
                AppLogger.auth.logWarning("google sign-in failed reason=\(type(of: error))")
                AppLogger.auth.logError("google sign-in error", error: error)
                errorMessage = LocalizationKeys.authGoogleSignInFailed.localized
            }
        }
    }

    func appleSignIn(idToken: String, onSuccess: @escaping () -> Void) {
        AppLogger.appleAuth.logInfo(
            prefix: AppLogger.LogPrefix.appleAuth,
            "event=viewModel.appleSignIn.start idTokenLength=\(idToken.count)"
        )
        Task {
            isLoading = true
            errorMessage = nil
            AppLogger.appleAuth.logDebug(
                prefix: AppLogger.LogPrefix.appleAuth,
                "event=viewModel.appleSignIn.loadingState isLoading=true errorCleared=true"
            )
            do {
                AppLogger.appleAuth.logDebug(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=viewModel.appleSignIn.repositoryCall.start"
                )
                _ = try await authRepository.appleSignIn(request: AppleSignInRequest(idToken: idToken))
                isLoading = false
                AppLogger.appleAuth.logInfo(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=viewModel.appleSignIn.success isLoading=false navigate=true"
                )
                onSuccess()
            } catch {
                isLoading = false
                let nsError = error as NSError
                AppLogger.appleAuth.logWarning(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=viewModel.appleSignIn.failure domain=\(nsError.domain) code=\(nsError.code) errorType=\(type(of: error)) message=\(error.localizedDescription)"
                )
                if let networkError = error as? NetworkError {
                    AppLogger.appleAuth.logWarning(
                        prefix: AppLogger.LogPrefix.appleAuth,
                        "event=viewModel.appleSignIn.networkError detail=\(networkError)"
                    )
                }
                AppLogger.appleAuth.logError(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=viewModel.appleSignIn.error",
                    error: error
                )
                errorMessage = LocalizationKeys.authAppleSignInFailed.localized
                AppLogger.appleAuth.logDebug(
                    prefix: AppLogger.LogPrefix.appleAuth,
                    "event=viewModel.appleSignIn.userFacingError message=\(errorMessage ?? "nil")"
                )
            }
        }
    }

    private func shouldSuggestSignInAfterSignup(error: Error, isLoginMode: Bool) -> Bool {
        guard !isLoginMode else { return false }
        guard let networkError = error as? NetworkError else { return false }
        switch networkError {
        case .httpError(let statusCode):
            return statusCode == 400
        case .badRequest:
            return true
        default:
            return false
        }
    }
}
