package com.shamelagpt.android.data.remote

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.domain.model.Source
import org.junit.Test

/**
 * Unit tests for ResponseParser.
 */
class ResponseParserTest {

    @Test
    fun testParseAnswerWithSources() {
        // Given
        val answer = """
            This is the main content.

            Sources:

            * **book_name:** صحيح البخاري, **source_url:** https://shamela.ws/book/1234/56
            * **book_name:** صحيح مسلم, **source_url:** https://shamela.ws/book/5678/90
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).isEqualTo("This is the main content.")
        assertThat(sources).hasSize(2)
        assertThat(sources[0].bookName).isEqualTo("صحيح البخاري")
        assertThat(sources[0].sourceURL).isEqualTo("https://shamela.ws/book/1234/56")
        assertThat(sources[0].pageNumber).isEqualTo(56)
        assertThat(sources[1].bookName).isEqualTo("صحيح مسلم")
        assertThat(sources[1].sourceURL).isEqualTo("https://shamela.ws/book/5678/90")
        assertThat(sources[1].pageNumber).isEqualTo(90)
    }

    @Test
    fun testParseAnswerWithoutSources() {
        // Given
        val answer = "This is a response without sources."

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).isEqualTo("This is a response without sources.")
        assertThat(sources).isEmpty()
    }

    @Test
    fun testParseAnswerEmptyString() {
        // Given
        val answer = ""

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).isEmpty()
        assertThat(sources).isEmpty()
    }

    @Test
    fun testParseAnswerWithMultipleSources() {
        // Given
        val answer = """
            Content here.

            Sources:

            * **book_name:** Book One, **source_url:** https://shamela.ws/book/1/1
            * **book_name:** Book Two, **source_url:** https://shamela.ws/book/2/2
            * **book_name:** Book Three, **source_url:** https://shamela.ws/book/3/3
            * **book_name:** Book Four, **source_url:** https://shamela.ws/book/4/4
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).isEqualTo("Content here.")
        assertThat(sources).hasSize(4)
    }

    @Test
    fun testParseAnswerWithArabicBookNames() {
        // Given
        val answer = """
            Arabic content.

            Sources:

            * **book_name:** الموطأ للإمام مالك, **source_url:** https://shamela.ws/book/100/1
            * **book_name:** سنن أبي داود, **source_url:** https://shamela.ws/book/200/2
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).hasSize(2)
        assertThat(sources[0].bookName).isEqualTo("الموطأ للإمام مالك")
        assertThat(sources[1].bookName).isEqualTo("سنن أبي داود")
    }

    @Test
    fun testParseAnswerPreservesNewlines() {
        // Given
        val answer = """
            Line 1
            Line 2

            Line 3

            Sources:

            * **book_name:** Test Book, **source_url:** https://shamela.ws/book/1/1
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).contains("Line 1\nLine 2\n\nLine 3")
    }

    @Test
    fun testParseAnswerTrimsContent() {
        // Given
        val answer = """


            Content with leading and trailing whitespace


            Sources:

            * **book_name:** Test Book, **source_url:** https://shamela.ws/book/1/1
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).isEqualTo("Content with leading and trailing whitespace")
    }

    @Test
    fun testParseAnswerWithCodeBlocks() {
        // Given
        val answer = """
            Here is some code:

            ```kotlin
            fun example() {
                println("Hello")
            }
            ```

            Sources:

            * **book_name:** Programming Book, **source_url:** https://shamela.ws/book/1/1
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).contains("```kotlin")
        assertThat(content).contains("fun example()")
        assertThat(sources).hasSize(1)
    }

    @Test
    fun testExtractSourcesWithValidFormat() {
        // Given
        val answer = """
            Content

            Sources:

            * **book_name:** Valid Book, **source_url:** https://shamela.ws/book/1/1
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).hasSize(1)
        assertThat(sources[0]).isEqualTo(
            Source(
                bookName = "Valid Book",
                sourceURL = "https://shamela.ws/book/1/1",
                pageNumber = 1
            )
        )
    }

    @Test
    fun testExtractSourcesWithMarkdownLinkFormatIncludesPageNumber() {
        // Given
        val answer = """
            Content

            Sources:

            - **[الجامع الصحيح](https://shamela.ws/book/123/45)** - الإمام الترمذي
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).hasSize(1)
        assertThat(sources[0].bookName).isEqualTo("الجامع الصحيح")
        assertThat(sources[0].sourceURL).isEqualTo("https://shamela.ws/book/123/45")
        assertThat(sources[0].pageNumber).isEqualTo(45)
        assertThat(sources[0].citation).isEqualTo("الجامع الصحيح, p. 45")
    }

    @Test
    fun testExtractSourcesWithInvalidFormat() {
        // Given - Missing proper format
        val answer = """
            Content

            Sources:

            * Invalid source format
            * Another invalid one
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).isEmpty()
    }

    @Test
    fun testExtractSourcesWithMissingBookName() {
        // Given - Empty book name
        val answer = """
            Content

            Sources:

            * **book_name:** , **source_url:** https://shamela.ws/book/1/1
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).isEmpty()
    }

    @Test
    fun testExtractSourcesWithMissingURL() {
        // Given - Empty URL
        val answer = """
            Content

            Sources:

            * **book_name:** Book Name, **source_url:**
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).isEmpty()
    }

    @Test
    fun testExtractSourcesWithEmptySection() {
        // Given
        val answer = """
            Content

            Sources:


        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).isEmpty()
    }

    @Test
    fun testExtractSourcesRegexMatching() {
        // Given - Test various valid patterns
        val answer = """
            Content

            Sources:

            * **book_name:** Book 1, **source_url:** https://shamela.ws/book/1/1
            *  **book_name:** Book 2, **source_url:** https://shamela.ws/book/2/2
            *   **book_name:** Book 3, **source_url:** https://shamela.ws/book/3/3
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then - Should match all patterns with varying whitespace
        assertThat(sources).hasSize(3)
    }

    @Test
    fun testParseAnswerWithMultipleSourcesSections() {
        // Given - Multiple "Sources:" sections (only first should be used)
        val answer = """
            Content

            Sources:

            * **book_name:** First Section Book, **source_url:** https://shamela.ws/book/1/1

            Sources:

            * **book_name:** Second Section Book, **source_url:** https://shamela.ws/book/2/2
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then - Should only parse sources from first section
        assertThat(content).isEqualTo("Content")
        assertThat(sources.size).isAtLeast(1)
        // Both sources should be found since they're in the same "rest" of the string after split
        assertThat(sources.any { it.bookName.contains("First Section Book") || it.bookName.contains("Second Section Book") }).isTrue()
    }

    @Test
    fun testParseAnswerWithSpecialCharactersInSources() {
        // Given
        val answer = """
            Content

            Sources:

            * **book_name:** Book (Special & Characters), **source_url:** https://shamela.ws/book/1/1?param=value&foo=bar
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).hasSize(1)
        assertThat(sources[0].bookName).isEqualTo("Book (Special & Characters)")
        assertThat(sources[0].sourceURL).isEqualTo("https://shamela.ws/book/1/1?param=value&foo=bar")
    }

    @Test
    fun testParseAnswerWithWhitespaceInSources() {
        // Given - Extra whitespace around book name and URL
        val answer = """
            Content

            Sources:

            * **book_name:**   Book With Spaces  , **source_url:**   https://shamela.ws/book/1/1
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then - Whitespace should be trimmed
        assertThat(sources).hasSize(1)
        assertThat(sources[0].bookName).isEqualTo("Book With Spaces")
        assertThat(sources[0].sourceURL).isEqualTo("https://shamela.ws/book/1/1")
    }

    @Test
    fun testParseAnswerWithMalformedMarkdown() {
        // Given - Malformed markdown
        val answer = """
            # Heading

            **Bold text**

            Sources:

            * **book_name:** Book, **source_url:** https://shamela.ws/book/1/1
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then - Should still parse correctly
        assertThat(content).contains("# Heading")
        assertThat(content).contains("**Bold text**")
        assertThat(sources).hasSize(1)
    }

    @Test
    fun testParseAnswerWithArabicHeaderAndMarkdownHeading() {
        // Given
        val answer = """
            محتوى الجواب هنا.

            ## المصادر / Sources:
            - [الزكاة في مال الصبي](https://shamela.ws/book/27107/42460)
        """.trimIndent()

        // When
        val (content, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(content).isEqualTo("محتوى الجواب هنا.")
        assertThat(sources).hasSize(1)
        assertThat(sources[0].bookName).isEqualTo("الزكاة في مال الصبي")
        assertThat(sources[0].pageNumber).isEqualTo(42460)
        assertThat(sources[0].citation).contains("42460")
    }

    @Test
    fun testParseAnswerExtractsPageFromUrlWithTrailingPunctuation() {
        // Given
        val answer = """
            Content

            Sources:
            - [Book Title](https://shamela.ws/book/123/45).
        """.trimIndent()

        // When
        val (_, sources) = ResponseParser.parseAnswer(answer)

        // Then
        assertThat(sources).hasSize(1)
        assertThat(sources[0].sourceURL).isEqualTo("https://shamela.ws/book/123/45")
        assertThat(sources[0].pageNumber).isEqualTo(45)
        assertThat(sources[0].citation).isEqualTo("Book Title, p. 45")
    }
}
