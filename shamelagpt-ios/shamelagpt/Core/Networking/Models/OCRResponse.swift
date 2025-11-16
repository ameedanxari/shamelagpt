import Foundation

struct OCRResponse: Decodable {
    let extractedText: String
    let imageUrl: String
    let metadata: OCRMetadata
}

struct OCRMetadata: Decodable {
    let success: Bool
    let detectedLanguage: String?
    let confidence: String?
    let textLength: Int
}
