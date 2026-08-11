import Foundation

/// Body for `POST /api/auth/apple`.
///
/// `idToken` is the Apple identity token from `ASAuthorizationAppleIDCredential`. The
/// encoder's `.convertToSnakeCase` strategy sends it as `id_token`, which is what the
/// backend expects.
struct AppleSignInRequest: Encodable {
    let idToken: String
}
