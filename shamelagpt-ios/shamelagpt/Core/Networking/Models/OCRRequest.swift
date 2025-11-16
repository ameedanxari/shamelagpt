import Foundation

struct OCRRequest: Encodable {
    let imageBase64: String
    let threadId: String?
    let languageHint: String?
    
    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
        case threadId = "thread_id"
        case languageHint = "language_hint"
    }
}
