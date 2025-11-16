//
//  Source.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Represents a source citation from the Shamela library
struct Source: Codable, Identifiable, Equatable {
    let id: String
    let bookTitle: String
    let author: String?
    let volumeNumber: Int?
    let pageNumber: Int?
    let text: String
    let sourceUrl: String?

    init(
        id: String = UUID().uuidString,
        bookTitle: String,
        author: String? = nil,
        volumeNumber: Int? = nil,
        pageNumber: Int? = nil,
        text: String,
        sourceUrl: String? = nil
    ) {
        self.id = id
        self.bookTitle = bookTitle
        self.author = author
        self.volumeNumber = volumeNumber
        self.pageNumber = pageNumber
        self.text = text
        self.sourceUrl = sourceUrl
    }

    /// Formatted citation string
    var citation: String {
        var parts: [String] = [bookTitle]

        if let author = author {
            parts.append(author)
        }

        if let volume = volumeNumber, let page = pageNumber {
            parts.append("\(volume)/\(page)")
        } else if let page = pageNumber {
            parts.append("p. \(page)")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension Source {
    static var preview: Source {
        Source(
            bookTitle: "صحيح البخاري",
            author: "محمد بن إسماعيل البخاري",
            volumeNumber: 1,
            pageNumber: 52,
            text: "Sample text from Sahih al-Bukhari"
        )
    }
}
#endif
