//
//  AuthTokenProvider.swift
//  ShamelaGPT
//
//  Supplies a *valid* bearer token to APIClient, renewing it when needed.
//

import Foundation

/// Supplies bearer tokens to `APIClient`.
protocol AuthTokenProviding: Sendable {
    /// A token that should still be accepted by the server, refreshing first if it is
    /// expired or about to expire. Returns `nil` when there is no session at all.
    func validToken() async -> String?

    /// Renews unconditionally. Used to recover from a 401 on a token we believed was good
    /// (clock skew, a server-side revocation, or an expiry we never recorded).
    func forceRefresh() async -> String?
}

/// A fixed token. Used by tests and by callers that manage their own credentials.
struct StaticTokenProvider: AuthTokenProviding {
    private let provider: @Sendable () -> String?

    init(_ provider: @escaping @Sendable () -> String?) {
        self.provider = provider
    }

    func validToken() async -> String? { provider() }
    func forceRefresh() async -> String? { provider() }
}

/// Keeps the stored Firebase ID token fresh.
///
/// Firebase ID tokens live for one hour. Previously nothing renewed them: once the local
/// expiry passed, `SessionManager.token()` returned `nil`, `APIClient` omitted the
/// `Authorization` header entirely, and the request reached an authenticated endpoint
/// unauthenticated — a 401 that the app reported as "you have been signed out".
///
/// This is an `actor` for a specific reason: the app fires several requests at once
/// (chat stream, conversation list, preferences). Without serialisation each would notice
/// the stale token and start its own refresh. Firebase invalidates the previous refresh
/// result in some flows, so the racing calls can clobber each other and log the user out.
/// Funnelling every caller through one in-flight `Task` — "single flight" — means N
/// concurrent callers produce exactly one network round trip and all observe the same result.
actor SessionTokenProvider: AuthTokenProviding {
    /// Renew this far ahead of expiry so a token can't die mid-request.
    private static let refreshSkew: TimeInterval = 5 * 60

    private let sessionManager: SessionManager
    private let baseURL: URL
    private let session: URLSession
    private var inFlight: Task<String?, Never>?

    init(sessionManager: SessionManager, baseURL: URL, session: URLSession) {
        self.sessionManager = sessionManager
        self.baseURL = baseURL
        self.session = session
    }

    func validToken() async -> String? {
        guard let stored = sessionManager.rawToken() else { return nil }
        guard sessionManager.isExpiring(within: Self.refreshSkew) else { return stored }
        AppLogger.auth.logInfo("token expiring within skew - refreshing before request")
        return await refresh() ?? nil
    }

    func forceRefresh() async -> String? {
        AppLogger.auth.logInfo("force refresh requested (401 recovery)")
        return await refresh()
    }

    /// Coalesces concurrent refreshes onto a single network call.
    private func refresh() async -> String? {
        if let existing = inFlight {
            AppLogger.auth.logDebug("joining in-flight token refresh")
            return await existing.value
        }

        let task = Task<String?, Never> { [sessionManager, baseURL, session] in
            guard let refreshToken = sessionManager.refreshToken() else {
                AppLogger.auth.logWarning("no refresh token stored - cannot renew session")
                return nil
            }

            var request = URLRequest(url: baseURL.appendingPathComponent("api/auth/refresh"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            // Deliberately no Authorization header: the refresh token is the credential,
            // and the token we would attach is the expired one we are trying to replace.

            do {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                request.httpBody = try encoder.encode(RefreshTokenRequest(refreshToken: refreshToken))

                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    AppLogger.auth.logWarning("token refresh rejected status=\(code)")
                    return nil
                }

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let auth = try decoder.decode(AuthResponse.self, from: data)

                // `expires_in` arrives as a string ("3600") from Firebase via the backend.
                sessionManager.saveSession(
                    token: auth.token,
                    refreshToken: auth.refreshToken,
                    expiresInSeconds: Double(auth.expiresIn) ?? 0
                )
                AppLogger.auth.logInfo("token refresh succeeded")
                return auth.token
            } catch {
                AppLogger.auth.logError("token refresh failed", error: error)
                return nil
            }
        }

        inFlight = task
        let result = await task.value
        inFlight = nil
        return result
    }
}
