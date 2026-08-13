import Foundation

/// Response body of `POST /api/transcribe`.
///
/// The decoder is configured with `.convertFromSnakeCase`, so no CodingKeys are needed.
struct TranscriptionResponse: Codable {
    /// Authoritative transcript. This replaces whatever the on-device recognizer produced.
    let text: String

    /// Diagnostic ONLY. The backend has been observed returning `"English"`, `"Urdu"` and
    /// `"ur"` for this same field across requests, so it is not a stable ISO-639-1 code.
    /// Never branch on it — log it and move on.
    let language: String?
}
