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
        let response = try await apiClient.signup(request)
        persistSession(from: response)
        return response
    }

    func login(request: LoginRequest) async throws -> AuthResponse {
        let response = try await apiClient.login(request)
        persistSession(from: response)
        return response
    }

    func getCurrentUser() async throws -> UserResponse {
        try await apiClient.getCurrentUser()
    }

    func updateCurrentUser(request: UpdateUserRequest) async throws -> UserResponse {
        try await apiClient.updateCurrentUser(request)
    }

    func deleteCurrentUser() async throws {
        try await apiClient.deleteCurrentUser()
        logout()
    }

    func verifyToken() async throws {
        try await apiClient.verifyToken()
    }

    func getPreferences() async throws -> UserPreferencesRequest {
        try await apiClient.getPreferences()
    }

    func setPreferences(_ request: UserPreferencesRequest) async throws {
        try await apiClient.setPreferences(request)
    }

    func logout() {
        sessionManager.clearSession()
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
}
