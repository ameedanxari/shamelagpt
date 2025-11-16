//
//  ResponseParserTests.swift
//  shamelagptTests
//
//  Created by Ameed Khalid on 05/11/2025.
//

import XCTest
@testable import ShamelaGPT

final class ResponseParserTests: XCTestCase {

    // MARK: - Parsing Success Cases

    func testParseResponseWithSources() throws {
        // Given
        let markdown = """
        This is the main content of the answer.

        Sources:

        * **book_name:** Sahih Bukhari, **source_url:** https://shamela.ws/book/1/23
        * **book_name:** Sahih Muslim, **source_url:** https://shamela.ws/book/2/45
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.cleanContent, "This is the main content of the answer.")
        XCTAssertEqual(result.sources.count, 2)
        XCTAssertEqual(result.sources[0].bookTitle, "Sahih Bukhari")
        XCTAssertEqual(result.sources[0].sourceUrl, "https://shamela.ws/book/1/23")
        XCTAssertEqual(result.sources[1].bookTitle, "Sahih Muslim")
        XCTAssertEqual(result.sources[1].sourceUrl, "https://shamela.ws/book/2/45")
    }

    func testParseResponseWithoutSources() throws {
        // Given
        let markdown = "This is the main content without sources."

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.cleanContent, "This is the main content without sources.")
        XCTAssertEqual(result.sources.count, 0)
    }

    func testParseEmptyResponse() throws {
        // Given
        let markdown = ""

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.cleanContent, "")
        XCTAssertEqual(result.sources.count, 0)
    }

    func testParseResponseWithMultipleSources() throws {
        // Given
        let markdown = """
        Content here.

        Sources:

        * **book_name:** Book 1, **source_url:** https://shamela.ws/book/1/1
        * **book_name:** Book 2, **source_url:** https://shamela.ws/book/2/2
        * **book_name:** Book 3, **source_url:** https://shamela.ws/book/3/3
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 3)
    }

    func testParseResponseWithArabicBookNames() throws {
        // Given
        let markdown = """
        Islamic jurisprudence answer.

        Sources:

        * **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/52
        * **book_name:** صحيح مسلم, **source_url:** https://shamela.ws/book/5678/123
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 2)
        XCTAssertEqual(result.sources[0].bookTitle, "صحيح البخاري")
        XCTAssertEqual(result.sources[1].bookTitle, "صحيح مسلم")
    }

    func testParseResponsePreservesNewlines() throws {
        // Given
        let markdown = """
        Line 1

        Line 2

        Line 3

        Sources:

        * **book_name:** Test Book, **source_url:** https://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertTrue(result.cleanContent.contains("Line 1"))
        XCTAssertTrue(result.cleanContent.contains("Line 2"))
        XCTAssertTrue(result.cleanContent.contains("Line 3"))
    }

    func testParseResponseWithVolumeAndPage() throws {
        // Given
        let markdown = """
        Content.

        Sources:

        * **book_name:** Test Book, **source_url:** https://shamela.ws/book/1234/567
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources[0].pageNumber, 567)
    }

    func testParseResponseWithPageOnly() throws {
        // Given
        let markdown = """
        Content.

        Sources:

        * **book_name:** Test Book, **source_url:** https://shamela.ws/book/999/42
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources[0].pageNumber, 42)
        XCTAssertNil(result.sources[0].volumeNumber)
    }

    // MARK: - Parsing Edge Cases

    func testParseResponseWithMalformedSources() throws {
        // Given
        let markdown = """
        Content here.

        Sources:

        * **book_name:** Book 1
        * Invalid source line
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.cleanContent, "Content here.")
        // Should handle malformed sources gracefully - ignore invalid ones
        XCTAssertEqual(result.sources.count, 0)
    }

    func testParseResponseWithIncompleteSourceData() throws {
        // Given - missing source_url
        let markdown = """
        Content.

        Sources:

        * **book_name:** Book Title
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 0)
    }

    func testParseResponseWithMultipleSourcesSections() throws {
        // Given - only first Sources: section should be parsed
        let markdown = """
        Content.

        Sources:

        * **book_name:** Book 1, **source_url:** https://shamela.ws/book/1/1

        More content here.

        Sources:

        * **book_name:** Book 2, **source_url:** https://shamela.ws/book/2/2
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then - should only parse first Sources section
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources[0].bookTitle, "Book 1")
    }

    func testParseResponseWithSpecialCharacters() throws {
        // Given
        let markdown = """
        Content.

        Sources:

        * **book_name:** Book (With Parentheses), **source_url:** https://shamela.ws/book/1/1
        * **book_name:** Book & Symbol, **source_url:** https://shamela.ws/book/2/2
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 2)
        XCTAssertEqual(result.sources[0].bookTitle, "Book (With Parentheses)")
        XCTAssertEqual(result.sources[1].bookTitle, "Book & Symbol")
    }

    func testParseResponseWithWhitespaceInSources() throws {
        // Given
        let markdown = """
        Content.

        Sources:

        *   **book_name:**   Book Title   ,   **source_url:**   https://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources[0].bookTitle, "Book Title")
        XCTAssertEqual(result.sources[0].sourceUrl, "https://shamela.ws/book/1/1")
    }

    func testParseResponseWithMalformedMarkdown() throws {
        // Given - malformed markdown
        let markdown = """
        Content.

        Sources:

        * book_name: No Asterisks, source_url: https://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then - should handle gracefully with fallback extraction
        XCTAssertEqual(result.cleanContent, "Content.")
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources.first?.sourceUrl, "https://shamela.ws/book/1/1")
    }

    // MARK: - Content Extraction Tests

    func testCleanContentExcludesSourcesSection() throws {
        // Given
        let markdown = """
        Main content here.

        Sources:

        * **book_name:** Book, **source_url:** https://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertFalse(result.cleanContent.contains("Sources:"))
        XCTAssertFalse(result.cleanContent.contains("book_name"))
        XCTAssertEqual(result.cleanContent, "Main content here.")
    }

    func testCleanContentTrimsWhitespace() throws {
        // Given
        let markdown = "   \n  Content with whitespace  \n  "

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.cleanContent, "Content with whitespace")
    }

    func testCleanContentPreservesMarkdown() throws {
        // Given
        let markdown = """
        # Heading

        **Bold text** and *italic text*

        - List item 1
        - List item 2
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertTrue(result.cleanContent.contains("# Heading"))
        XCTAssertTrue(result.cleanContent.contains("**Bold text**"))
        XCTAssertTrue(result.cleanContent.contains("*italic text*"))
        XCTAssertTrue(result.cleanContent.contains("- List item 1"))
    }

    func testCleanContentWithCodeBlocks() throws {
        // Given
        let markdown = """
        Here is some code:

        ```swift
        let x = 42
        ```

        Sources:

        * **book_name:** Book, **source_url:** https://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertTrue(result.cleanContent.contains("```swift"))
        XCTAssertTrue(result.cleanContent.contains("let x = 42"))
        XCTAssertFalse(result.cleanContent.contains("Sources:"))
    }

    // MARK: - Missing Field Tests

    func testParseResponseWithMissingBookName() throws {
        // Given - missing book_name
        let markdown = """
        Content.

        Sources:

        * **source_url:** https://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources.first?.sourceUrl, "https://shamela.ws/book/1/1")
    }

    func testParseResponseWithMissingSourceURL() throws {
        // Given - missing source_url
        let markdown = """
        Content.

        Sources:

        * **book_name:** Book Title, **something_else:** value
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 0)
    }

    func testParseResponseWithEmptyBookName() throws {
        // Given - empty book name
        let markdown = """
        Content.

        Sources:

        * **book_name:** , **source_url:** https://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources.first?.sourceUrl, "https://shamela.ws/book/1/1")
    }

    // MARK: - URL Tests

    func testParseResponseWithHTTPURL() throws {
        // Given
        let markdown = """
        Content.

        Sources:

        * **book_name:** Book, **source_url:** http://shamela.ws/book/1/1
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 1)
        XCTAssertEqual(result.sources[0].sourceUrl, "http://shamela.ws/book/1/1")
    }

    func testParseResponseWithComplexURL() throws {
        // Given
        let markdown = """
        Content.

        Sources:

        * **book_name:** Book, **source_url:** https://shamela.ws/book/1234/5678?param=value
        """

        // When
        let result = ResponseParser.parseMarkdownResponse(markdown)

        // Then
        XCTAssertEqual(result.sources.count, 1)
        // URL extraction stops at whitespace, so query params might be included
        XCTAssertTrue(result.sources[0].sourceUrl?.hasPrefix("https://shamela.ws/book/1234") ?? false)
    }
}
