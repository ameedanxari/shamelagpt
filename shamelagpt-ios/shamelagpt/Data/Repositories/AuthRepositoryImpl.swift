//
//  AuthRepositoryImpl.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

final class AuthRepositoryImpl: AuthRepository {
    private let apiClient: APIClientProtocol
    private let sessionManager: SessionManager

    init(apiClient: APIClientProtocol, sessionManager: SessionManager) {
        self.apiClient = apiClient
        self.sessionManager = sessionManager
    }

    func signup(request: SignupRequest) async throws -> AuthResponse {
        do {
            AppLogger.auth.logDebug("signup request started")
            let response = try await apiClient.signup(request)
            persistSession(from: response)
            AppLogger.auth.logInfo("signup request succeeded")
            return response
        } catch {
            AppLogger.auth.logWarning("signup request failed reason=\(type(of: error))")
            throw normalizeError(error)
        }
    }

    func login(request: LoginRequest) async throws -> AuthResponse {
        do {
            AppLogger.auth.logDebug("login request started")
            let response = try await apiClient.login(request)
            persistSession(from: response)
            sessionManager.saveCredentials(email: request.email, password: request.password)
            AppLogger.auth.logInfo("login request succeeded")
            return response
        } catch {
            AppLogger.auth.logWarning("login request failed reason=\(type(of: error))")
            throw normalizeError(error)
        }
    }

    func forgotPassword(email: String) async throws {
        do {
            AppLogger.auth.logDebug("forgot password request started")
            try await apiClient.forgotPassword(email)
            AppLogger.auth.logInfo("forgot password request succeeded")
        } catch {
            AppLogger.auth.logWarning("forgot password request failed reason=\(type(of: error))")
            throw normalizeError(error)
        }
    }

    func googleSignIn(request: GoogleSignInRequest) async throws -> AuthResponse {
        do {
            AppLogger.auth.logDebug("google sign-in request started")
            let response = try await apiClient.googleSignIn(request)
            persistSession(from: response)
            AppLogger.auth.logInfo("google sign-in request succeeded")
            return response
        } catch {
            AppLogger.auth.logWarning("google sign-in request failed reason=\(type(of: error))")
            throw normalizeError(error)
        }
    }

    func refreshToken(request: RefreshTokenRequest) async throws -> AuthResponse {
        do {
            AppLogger.auth.logInfo("refresh token request started")
            let response = try await apiClient.refreshToken(request)
            persistSession(from: response)
            AppLogger.auth.logInfo("refresh token request succeeded")
            return response
        } catch {
            AppLogger.auth.logWarning("refresh token request failed reason=\(type(of: error))")
            throw normalizeError(error)
        }
    }

    func getCurrentUser() async throws -> UserResponse {
        do {
            return try await apiClient.getCurrentUser()
        } catch {
            throw normalizeError(error)
        }
    }

    func updateCurrentUser(request: UpdateUserRequest) async throws -> UserResponse {
        do {
            return try await apiClient.updateCurrentUser(request)
        } catch {
            throw normalizeError(error)
        }
    }

    func deleteCurrentUser() async throws {
        do {
            try await apiClient.deleteCurrentUser()
            logout()
        } catch {
            throw normalizeError(error)
        }
    }

    func verifyToken() async throws {
        do {
            try await apiClient.verifyToken()
        } catch {
            throw normalizeError(error)
        }
    }

    func getPreferences() async throws -> UserPreferencesRequest {
        do {
            return try await apiClient.getPreferences()
        } catch {
            throw normalizeError(error)
        }
    }

    func setPreferences(_ request: UserPreferencesRequest) async throws {
        do {
            try await apiClient.setPreferences(request)
        } catch {
            throw normalizeError(error)
        }
    }

    func logout() {
        AppLogger.auth.logInfo("logout called")
        sessionManager.clearSession()
        sessionManager.clearCredentials()
    }

    func token() -> String? {
        sessionManager.token()
    }

    func isLoggedIn() -> Bool {
        sessionManager.isLoggedIn()
    }

    private func persistSession(from response: AuthResponse) {
        let expires = Double(response.expiresIn) ?? 0
        sessionManager.saveSession(
            token: response.token,
            refreshToken: response.refreshToken,
            expiresInSeconds: expires
        )
    }

    private func normalizeError(_ error: Error) -> Error {
        if error is NetworkError || error is AppError {
            return error
        }
        return AppError.mapping(error)
    }
}
