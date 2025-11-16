//
//  AuthRepository.swift
//  ShamelaGPT
//
//  Created by Codex on 05/12/2025.
//

import Foundation

protocol AuthRepository {
    func signup(request: SignupRequest) async throws -> AuthResponse
    func login(request: LoginRequest) async throws -> AuthResponse
    func forgotPassword(email: String) async throws
    func googleSignIn(request: GoogleSignInRequest) async throws -> AuthResponse
    func refreshToken(request: RefreshTokenRequest) async throws -> AuthResponse
    func getCurrentUser() async throws -> UserResponse
    func updateCurrentUser(request: UpdateUserRequest) async throws -> UserResponse
    func deleteCurrentUser() async throws
    func verifyToken() async throws
    func getPreferences() async throws -> UserPreferencesRequest
    func setPreferences(_ request: UserPreferencesRequest) async throws
    func logout()
    func token() -> String?
    func isLoggedIn() -> Bool
}
