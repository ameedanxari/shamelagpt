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
        guard !started else {
            AppLogger.auth.logDebug(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.bootstrap.skipped reason=alreadyStarted"
            )
            return
        }
        started = true

        if sessionManager.isLoggedIn() {
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.bootstrap.sessionFound"
            )
            isAuthenticated = true
            isBootstrapping = false
            return
        }

        guard sessionManager.refreshToken()?.isEmpty == false else {
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.bootstrap.restoreSkipped reason=noRefreshToken"
            )
            isAuthenticated = false
            isBootstrapping = false
            return
        }

        AppLogger.auth.logInfo(
            prefix: AppLogger.LogPrefix.authState,
            "event=startup.bootstrap.restoreStarted"
        )
        Task {
            let restored = await restoreSession()
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.bootstrap.restoreCompleted restored=\(restored) loggedIn=\(sessionManager.isLoggedIn())"
            )
            isAuthenticated = restored && sessionManager.isLoggedIn()
            isBootstrapping = false
        }
    }

    /// Restores only from the refresh token. Earlier builds fell back to replaying a
    /// stored email/password, which meant the app could re-authenticate from scratch
    /// without the user ever asking — and required keeping their password on device.
    private func restoreSession() async -> Bool {
        switch await tryRefreshToken() {
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
            AppLogger.auth.logDebug(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.refresh.skipped reason=noRefreshToken"
            )
            return .skipped
        }

        do {
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.refresh.start"
            )
            _ = try await authRepository.refreshToken(request: RefreshTokenRequest(refreshToken: refreshToken))
            AppLogger.auth.logInfo(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.refresh.success"
            )
            return .success
        } catch {
            AppLogger.auth.logWarning(
                prefix: AppLogger.LogPrefix.authState,
                "event=startup.refresh.failure unauthorized=\(isUnauthorized(error)) reason=\(type(of: error))"
            )
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
