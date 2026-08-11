import Foundation

/// Response of `GET /api/auth/me/mode`.
struct ModePreferenceResponse: Decodable {
    let modePreference: Int
    let modeName: String?
}

/// Body for `PUT /api/auth/me/mode`.
///
/// The backend validates the value is in {0, 1, 2} and rejects anything else with 422.
struct UpdateModeRequest: Encodable {
    let modePreference: Int
}
