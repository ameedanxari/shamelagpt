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
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password are required"
            return
        }

        Task {
            isLoading = true
            errorMessage = nil
            do {
                if isLoginMode {
                    _ = try await authRepository.login(
                        request: LoginRequest(email: email, password: password)
                    )
                } else {
                    _ = try await authRepository.signup(
                        request: SignupRequest(
                            email: email,
                            password: password,
                            displayName: displayName.isEmpty ? nil : displayName
                        )
                    )
                }
                isLoading = false
                onSuccess()
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
