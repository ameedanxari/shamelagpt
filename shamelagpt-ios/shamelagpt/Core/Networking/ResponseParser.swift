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
    /// المصادر / Sources:
    /// - Title - https://shamela.ws/book/123/45
    /// ```
    static func parseMarkdownResponse(_ markdown: String) -> ParsedResponse {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")

        // Find the first sources header in either English or Arabic, with optional slash and colon
        let headerPattern = #"(?mi)^\s*#*\s*(?:المصادر|Sources)(?:\s*/\s*(?:Sources|المصادر))?\s*:?\s*$"#
        guard let headerRange = normalized.range(of: headerPattern, options: .regularExpression) else {
            let cleanContent = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
            return ParsedResponse(cleanContent: cleanContent, sources: [])
        }

        let contentPart = normalized[..<headerRange.lowerBound]
        let sourcesPartFull = normalized[headerRange.upperBound...]

        // Take until the next header repeat if present
        let nextHeaderRange = sourcesPartFull.range(of: headerPattern, options: .regularExpression)
        let sourcesSlice = nextHeaderRange.map { sourcesPartFull[..<$0.lowerBound] } ?? sourcesPartFull

        let cleanContent = contentPart.trimmingCharacters(in: .whitespacesAndNewlines)
        let sources = parseSources(from: String(sourcesSlice))

        return ParsedResponse(cleanContent: cleanContent, sources: sources)
    }

    /// Parses sources from the sources section
    /// Supports formats:
    /// 1. * **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
    /// 2. - **[Book Title](https://shamela.ws/book/123/45)** - Author Name
    private static func parseSources(from sourcesText: String) -> [Source] {
        var sources: [Source] = []

        let lines = sourcesText
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("*") || $0.hasPrefix("-") }

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
        // Try markdown link format first: **[Title](URL)** - Author
        // Pattern: **[Title](URL)** - Author
        let markdownLinkPattern = "\\*\\*\\[(.*?)\\]\\((.*?)\\)\\*\\*\\s*-\\s*(.*)"
        
        if let regex = try? NSRegularExpression(pattern: markdownLinkPattern, options: []),
           let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: (line as NSString).length)) {
            
            let nsString = line as NSString
            let title = nsString.substring(with: match.range(at: 1))
            let url = nsString.substring(with: match.range(at: 2))
            let author = nsString.substring(with: match.range(at: 3))
            
            let (volumeNumber, pageNumber) = extractVolumeAndPage(from: url)
            
            return Source(
                bookTitle: title,
                author: author,
                volumeNumber: volumeNumber,
                pageNumber: pageNumber,
                text: line,
                sourceUrl: url
            )
        }
        
        // Fallback to structured format: **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
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
            // Last-chance fallback: split on URL directly (e.g., "Title - https://...").
            guard let rawURL = extractFirstURL(from: line) else { return nil }
            let titleFallback = line
                .replacingOccurrences(of: rawURL, with: "")
                .replacingOccurrences(of: " - ", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let (volumeNumber, pageNumber) = extractVolumeAndPage(from: rawURL)
            return Source(
                bookTitle: titleFallback.isEmpty ? rawURL : titleFallback,
                author: nil,
                volumeNumber: volumeNumber,
                pageNumber: pageNumber,
                text: line,
                sourceUrl: rawURL
            )
        }

        // Extract volume and page numbers from URL if present
        // Format: https://shamela.ws/book/123/45 where 45 is the page
        let (volumeNumber, pageNumber) = extractVolumeAndPage(from: url)

        return Source(
            bookTitle: title,
            author: nil, // Author not provided in structured format
            volumeNumber: volumeNumber,
            pageNumber: pageNumber,
            text: line, // Store the full citation line as text
            sourceUrl: url
        )
    }

    private static func extractFirstURL(from text: String) -> String? {
        let pattern = "https?://[^\\s]+"
        guard let range = text.range(of: pattern, options: .regularExpression) else { return nil }
        return String(text[range])
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
