//
//  AppStartupViewModel.swift
//  ShamelaGPT
//

import Foundation

@MainActor
final class AppStartupViewModel: ObservableObject {
    @Published var isBootstrapping: Bool
    @Published var isAuthenticated: Bool

    private let authRepository: AuthRepository
    private let sessionManager: SessionManager
    private var started = false

    init(
        authRepository: AuthRepository,
        sessionManager: SessionManager,
        initiallyAuthenticated: Bool
    ) {
        self.authRepository = authRepository
        self.sessionManager = sessionManager
        self.isAuthenticated = initiallyAuthenticated
        self.isBootstrapping = !initiallyAuthenticated
    }

    func bootstrap() {
        guard !started else { return }
        started = true

        if sessionManager.isLoggedIn() {
            isAuthenticated = true
            isBootstrapping = false
            return
        }

        let canAttemptRestore = (sessionManager.refreshToken()?.isEmpty == false) ||
            sessionManager.storedCredentials() != nil
        guard canAttemptRestore else {
            isAuthenticated = false
            isBootstrapping = false
            return
        }

        Task {
            let restored = await restoreSession()
            isAuthenticated = restored && sessionManager.isLoggedIn()
            isBootstrapping = false
        }
    }

    private func restoreSession() async -> Bool {
        switch await tryRefreshToken() {
        case .success:
            return true
        case .unauthorized:
            sessionManager.clearSession()
        case .failed, .skipped:
            break
        }

        switch await tryCredentialsLogin() {
        case .success:
            return true
        case .unauthorized:
            sessionManager.clearSession()
            sessionManager.clearCredentials()
        case .failed, .skipped:
            break
        }

        return false
    }

    private func tryRefreshToken() async -> AttemptResult {
        guard let refreshToken = sessionManager.refreshToken(), !refreshToken.isEmpty else {
            return .skipped
        }

        do {
            _ = try await authRepository.refreshToken(request: RefreshTokenRequest(refreshToken: refreshToken))
            return .success
        } catch {
            return isUnauthorized(error) ? .unauthorized : .failed
        }
    }

    private func tryCredentialsLogin() async -> AttemptResult {
        guard let creds = sessionManager.storedCredentials() else {
            return .skipped
        }

        do {
            _ = try await authRepository.login(request: LoginRequest(email: creds.email, password: creds.password))
            return .success
        } catch {
            return isUnauthorized(error) ? .unauthorized : .failed
        }
    }

    private func isUnauthorized(_ error: Error) -> Bool {
        if let networkError = error as? NetworkError,
           case .httpError(let statusCode) = networkError {
            return statusCode == 401 || statusCode == 403
        }

        if let appError = error as? AppError,
           case .api(let code, _) = appError {
            return code == 401 || code == 403
        }

        return false
    }

    private enum AttemptResult {
        case success
        case failed
        case unauthorized
        case skipped
    }
}
