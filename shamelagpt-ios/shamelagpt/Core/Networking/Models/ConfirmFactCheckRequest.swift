import Foundation

struct ConfirmFactCheckRequest: Encodable {
    let reviewedText: String
    let imageUrl: String?
    let imageBase64: String?
    let threadId: String?
    let languagePreference: String?
    let enableThinking: Bool?
    
    enum CodingKeys: String, CodingKey {
        case reviewedText = "reviewed_text"
        case imageUrl = "image_url"
        case imageBase64 = "image_base64"
        case threadId = "thread_id"
        case languagePreference = "language_preference"
        case enableThinking = "enable_thinking"
    }
}
