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
    }

    func toggleMode() {
        isLoginMode.toggle()
        errorMessage = nil
    }

    func authenticate(onSuccess: @escaping () -> Void) {
        let mode = isLoginMode ? "login" : "signup"
        AppLogger.auth.logInfo("authenticate requested mode=\(mode)")
        guard !email.isEmpty, !password.isEmpty else {
            AppLogger.auth.logWarning("authenticate validation failed: missing required fields")
            errorMessage = "Email and password are required"
            return
        }

        Task {
            isLoading = true
            errorMessage = nil
            do {
                if isLoginMode {
                    AppLogger.auth.logDebug("sending login request")
                    _ = try await authRepository.login(
                        request: LoginRequest(email: email, password: password)
                    )
                } else {
                    AppLogger.auth.logDebug("sending signup request")
                    _ = try await authRepository.signup(
                        request: SignupRequest(
                            email: email,
                            password: password,
                            displayName: displayName.isEmpty ? nil : displayName
                        )
                    )
                }
                isLoading = false
                AppLogger.auth.logInfo("authentication success mode=\(mode)")
                onSuccess()
            } catch {
                isLoading = false
                AppLogger.auth.logWarning("authentication failed mode=\(mode) reason=\(type(of: error))")
                AppLogger.auth.logError("authentication error", error: error)
                errorMessage = error.userFacingMessage
            }
        }
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
                errorMessage = error.userFacingMessage
            }
        }
    }
}
