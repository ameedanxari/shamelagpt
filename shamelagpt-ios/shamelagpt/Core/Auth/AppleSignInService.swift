//
//  AppleSignInService.swift
//  ShamelaGPT
//
//  Sign in with Apple via AuthenticationServices.
//

import AuthenticationServices
import Foundation

/// Produces an Apple identity token for `POST /api/auth/apple`.
///
/// Simpler than the Google flow: there is no browser round trip and no PKCE, because
/// `ASAuthorizationAppleIDProvider` talks to the system directly and hands back a signed
/// JWT. That JWT is exactly what the backend forwards to Firebase's `signInWithIdp`, so
/// no Firebase SDK is needed here either.
///
/// Requires the `com.apple.developer.applesignin` entitlement, which is a **paid**
/// membership capability — this cannot build under a free personal team.
@MainActor
final class AppleSignInService: NSObject {

    enum AppleSignInError: LocalizedError {
        case cancelled
        case missingIdentityToken
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return "Sign-in was cancelled."
            case .missingIdentityToken:
                return "Apple did not return an identity token."
            case .failed(let detail):
                return "Could not complete Sign in with Apple. \(detail)"
            }
        }
    }

    /// Result of a successful authorization.
    ///
    /// `fullName` and `email` are supplied by Apple **only on the very first
    /// authorization** for a given Apple ID / app pair. Every later sign-in returns nil for
    /// both, so they cannot be relied on as a source of profile data — the backend derives
    /// the account from the token instead.
    struct Credential {
        let identityToken: String
        let fullName: String?
        let email: String?
    }

    private var continuation: CheckedContinuation<Credential, Error>?
    /// Held so ARC keeps the controller alive while the system sheet is up.
    private var controller: ASAuthorizationController?

    func signIn() async throws -> Credential {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }

    private func finish(_ result: Result<Credential, Error>) {
        // Guard against the delegate firing twice; a continuation may only resume once.
        guard let continuation else { return }
        self.continuation = nil
        self.controller = nil
        continuation.resume(with: result)
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let tokenData = credential.identityToken,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            finish(.failure(AppleSignInError.missingIdentityToken))
            return
        }

        let name = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        AppLogger.auth.logInfo("apple authorization succeeded (nameProvided=\(!name.isEmpty))")
        finish(.success(
            Credential(
                identityToken: token,
                fullName: name.isEmpty ? nil : name,
                email: credential.email
            )
        ))
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            AppLogger.auth.logInfo("apple sign-in cancelled by user")
            finish(.failure(AppleSignInError.cancelled))
            return
        }
        AppLogger.auth.logError("apple sign-in failed", error: error)
        finish(.failure(AppleSignInError.failed(error.localizedDescription)))
    }
}

// MARK: - Presentation anchor

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        return scene?.keyWindow
            ?? scene?.windows.first
            ?? ASPresentationAnchor()
    }
}
