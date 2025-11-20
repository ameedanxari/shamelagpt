//
//  ResponseParser.swift
//  ShamelaGPT
//
//  Created by Ameed Khalid on 05/11/2025.
//

import Foundation

/// Parses API responses and extracts content and sources
struct ResponseParser {

    /// Result of parsing a markdown response
    struct ParsedResponse {
        let cleanContent: String
        let sources: [Source]
    }

    /// Parses a markdown response containing content and sources
    /// Expected format:
    /// ```
    /// Content here...
    ///
    /// Sources:
    ///
    /// * **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
    /// ```
    static func parseMarkdownResponse(_ markdown: String) -> ParsedResponse {
        // Split by "Sources:" section
        let components = markdown.components(separatedBy: "\nSources:\n")

        // Get clean content (everything before Sources section)
        let cleanContent = components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? markdown

        // Parse sources if they exist
        var sources: [Source] = []
        if components.count > 1 {
            let sourcesSection = components[1]
            sources = parseSources(from: sourcesSection)
        }

        return ParsedResponse(cleanContent: cleanContent, sources: sources)
    }

    /// Parses sources from the sources section
    /// Format: * **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
    private static func parseSources(from sourcesText: String) -> [Source] {
        var sources: [Source] = []

        // Split by lines that start with "* "
        let lines = sourcesText.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("*") }

        for line in lines {
            // Remove the leading "* " or "- "
            let cleanLine = line
                .replacingOccurrences(of: "^[*-]\\s*", with: "", options: .regularExpression)

            // Extract book_name and source_url using regex
            if let source = extractSource(from: cleanLine) {
                sources.append(source)
            }
        }

        return sources
    }

    /// Extracts a Source object from a line
    private static func extractSource(from line: String) -> Source? {
        // Pattern: **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
        let bookNamePattern = "\\*\\*book_name:\\*\\*\\s*([^,]+)"
        let sourceUrlPattern = "\\*\\*source_url:\\*\\*\\s*(https?://[^\\s]+)"

        var bookTitle: String?
        var sourceUrl: String?

        // Extract book name
        if let bookMatch = line.range(of: bookNamePattern, options: .regularExpression) {
            let bookText = String(line[bookMatch])
            bookTitle = extractValue(from: bookText, pattern: bookNamePattern)
        }

        // Extract source URL
        if let urlMatch = line.range(of: sourceUrlPattern, options: .regularExpression) {
            let urlText = String(line[urlMatch])
            sourceUrl = extractValue(from: urlText, pattern: sourceUrlPattern)
        }

        // Create Source if we have the required fields
        guard let title = bookTitle?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = sourceUrl?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            return nil
        }

        // Extract volume and page numbers from URL if present
        // Format: https://shamela.ws/book/123/45 where 45 is the page
        let (volumeNumber, pageNumber) = extractVolumeAndPage(from: url)

        return Source(
            bookTitle: title,
            author: nil, // Author not provided in API response
            volumeNumber: volumeNumber,
            pageNumber: pageNumber,
            text: line, // Store the full citation line as text
            sourceUrl: url
        )
    }

    /// Extracts the matched value from a regex pattern
    private static func extractValue(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        guard let match = results.first, match.numberOfRanges > 1 else {
            return nil
        }

        let range = match.range(at: 1)
        return nsString.substring(with: range)
    }

    /// Extracts volume and page numbers from Shamela URL
    /// Format: https://shamela.ws/book/{bookId}/{page}
    private static func extractVolumeAndPage(from url: String) -> (volume: Int?, page: Int?) {
        let components = url.components(separatedBy: "/")

        // Get the last component which should be the page number
        if let lastComponent = components.last,
           let pageNumber = Int(lastComponent) {
            return (nil, pageNumber)
        }

        return (nil, nil)
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension ResponseParser {
    static var sampleMarkdownWithSources: String {
        """
        This is a sample answer about Islamic jurisprudence. The scholars have discussed this matter extensively.

        According to the majority opinion, the ruling is based on several principles.

        Sources:

        * **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/52
        * **book_name:** صحيح مسلم, **source_url:** https://shamela.ws/book/5678/123
        """
    }

    static var sampleMarkdownWithoutSources: String {
        """
        This is a simple answer without any sources.
        It contains multiple lines of text.
        """
    }
}
#endif
