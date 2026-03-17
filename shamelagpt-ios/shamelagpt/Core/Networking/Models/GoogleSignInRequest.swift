import Foundation

struct GoogleSignInRequest: Encodable {
    let idToken: String
}

struct AppleSignInRequest: Encodable {
    let idToken: String
}
