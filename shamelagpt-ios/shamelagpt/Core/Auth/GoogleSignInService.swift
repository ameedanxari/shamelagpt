//
//  GoogleSignInService.swift
//  ShamelaGPT
//
//  Google sign-in over ASWebAuthenticationSession + PKCE.
//

import AuthenticationServices
import CryptoKit
import Foundation

/// Produces a Google ID token for `POST /api/auth/google`.
///
/// Deliberately not the GoogleSignIn SDK. The app has no third-party dependencies and this
/// flow is the whole of what that SDK does for us: an authorization-code exchange with
/// PKCE, returning the `id_token`. `ASWebAuthenticationSession` also needs **no
/// entitlement**, so unlike Sign in with Apple this works in the simulator and under a
/// free personal team.
///
/// PKCE (RFC 7636) is what makes a client secret unnecessary. A native app cannot keep a
/// secret — anyone can unzip the binary — so instead we send the hash of a random verifier
/// up front and the verifier itself at redemption. An attacker who intercepts the
/// redirected authorization code cannot exchange it without the verifier, which never
/// leaves the device.
@MainActor
final class GoogleSignInService: NSObject {

    enum GoogleSignInError: LocalizedError {
        case cancelled
        case missingAuthorizationCode
        case tokenExchangeFailed(String)
        case missingIDToken

        var errorDescription: String? {
            switch self {
            case .cancelled:
                return "Sign-in was cancelled."
            case .missingAuthorizationCode:
                return "Google did not return an authorization code."
            case .tokenExchangeFailed(let detail):
                return "Could not complete Google sign-in. \(detail)"
            case .missingIDToken:
                return "Google did not return an identity token."
            }
        }
    }

    private enum Endpoint {
        static let authorize = "https://accounts.google.com/o/oauth2/v2/auth"
        static let token = "https://oauth2.googleapis.com/token"
    }

    private let clientID: String
    private let session: URLSession
    private var webAuthSession: ASWebAuthenticationSession?

    init(clientID: String = Constants.Google.iosClientID, session: URLSession = .shared) {
        self.clientID = clientID
        self.session = session
        super.init()
    }

    /// Google requires installed apps to redirect to the reversed client ID scheme.
    private var redirectURI: String {
        "\(Constants.Google.reversedClientID):/oauth2redirect"
    }

    /// Runs the browser flow and exchanges the resulting code for an ID token.
    func signIn() async throws -> String {
        let verifier = Self.makeCodeVerifier()
        let challenge = Self.makeCodeChallenge(from: verifier)
        // Guards against a forged redirect being fed back into the app.
        let state = Self.makeCodeVerifier()

        let code = try await authorize(challenge: challenge, state: state)
        return try await exchange(code: code, verifier: verifier)
    }

    // MARK: - Step 1: browser authorization

    private func authorize(challenge: String, state: String) async throws -> String {
        var components = URLComponents(string: Endpoint.authorize)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]

        guard let url = components.url else {
            throw GoogleSignInError.tokenExchangeFailed("Could not build the authorization URL.")
        }

        let callbackScheme = Constants.Google.reversedClientID

        return try await withCheckedThrowingContinuation { continuation in
            // `resume` must run exactly once; ASWebAuthenticationSession guarantees a single
            // completion callback, so this is safe.
            let authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: GoogleSignInError.cancelled)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard
                    let callbackURL,
                    let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems
                else {
                    continuation.resume(throwing: GoogleSignInError.missingAuthorizationCode)
                    return
                }
                guard items.first(where: { $0.name == "state" })?.value == state else {
                    continuation.resume(
                        throwing: GoogleSignInError.tokenExchangeFailed("Redirect state did not match.")
                    )
                    return
                }
                guard let code = items.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: GoogleSignInError.missingAuthorizationCode)
                    return
                }
                continuation.resume(returning: code)
            }

            authSession.presentationContextProvider = self
            // Use a fresh browser session so a previously signed-in Google account does not
            // silently reuse itself — the user should be able to pick an account.
            authSession.prefersEphemeralWebBrowserSession = true
            // Held so ARC does not deallocate the session while the sheet is up.
            self.webAuthSession = authSession

            if !authSession.start() {
                continuation.resume(
                    throwing: GoogleSignInError.tokenExchangeFailed("Could not open the sign-in browser.")
                )
            }
        }
    }

    // MARK: - Step 2: code -> id_token

    private struct TokenResponse: Decodable {
        let idToken: String?

        enum CodingKeys: String, CodingKey {
            case idToken = "id_token"
        }
    }

    private func exchange(code: String, verifier: String) async throws -> String {
        var request = URLRequest(url: URL(string: Endpoint.token)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // No client_secret: this is a public client authenticated by PKCE.
        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "code_verifier", value: verifier),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI)
        ]
        request.httpBody = body.query?.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            let detail = String(data: data, encoding: .utf8)?.prefix(200) ?? ""
            AppLogger.auth.logError("Google token exchange failed status=\(status) body=\(detail)")
            throw GoogleSignInError.tokenExchangeFailed("Google returned \(status).")
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        guard let idToken = decoded.idToken else {
            throw GoogleSignInError.missingIDToken
        }
        AppLogger.auth.logInfo("Google token exchange succeeded")
        return idToken
    }

    // MARK: - PKCE helpers

    /// A high-entropy random string, base64url-encoded (RFC 7636 §4.1).
    private static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    /// S256 challenge: base64url(SHA256(verifier)).
    private static func makeCodeChallenge(from verifier: String) -> String {
        let digest = SHA256.hash(data: Data(verifier.utf8))
        return Data(digest).base64URLEncodedString()
    }
}

// MARK: - Presentation anchor

extension GoogleSignInService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        return scene?.keyWindow
            ?? scene?.windows.first
            ?? ASPresentationAnchor()
    }
}

private extension Data {
    /// base64url without padding, as OAuth requires.
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
