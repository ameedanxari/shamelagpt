package com.shamelagpt.android.data.remote

import com.shamelagpt.android.domain.model.Source

/**
 * Parses API responses to extract clean content and sources.
 */
object ResponseParser {

    /**
     * Parses the answer markdown to extract clean content and sources.
     *
     * The answer format is:
     * ```
     * Content...
     *
     * Sources:
     *
     * * **book_name:** Book Title, **source_url:** https://shamela.ws/book/123/45
     * * **book_name:** Another Book, **source_url:** https://shamela.ws/book/456/78
     * ```
     *
     * @param answer The markdown formatted answer from API
     * @return Pair of (clean content, list of sources)
     */
    fun parseAnswer(answer: String): Pair<String, List<Source>> {
        // Split by "Sources:" section
        val parts = answer.split(Regex("\\n\\s*Sources:\\s*\\n"), limit = 2)

        val content = parts[0].trim()
        val sources = if (parts.size > 1) {
            extractSources(parts[1])
        } else {
            emptyList()
        }

        return Pair(content, sources)
    }

    /**
     * Extracts sources from the sources section of the markdown.
     *
     * @param sourcesSection The sources section text
     * @return List of Source objects
     */
    private fun extractSources(sourcesSection: String): List<Source> {
        val sources = mutableListOf<Source>()

        // Pattern to match: * **book_name:** Book Title, **source_url:** https://...
        val pattern = Regex(
            """\*\s*\*\*book_name:\*\*\s*([^,]+),\s*\*\*source_url:\*\*\s*(\S+)""",
            RegexOption.MULTILINE
        )

        pattern.findAll(sourcesSection).forEach { match ->
            val bookName = match.groupValues[1].trim()
            val sourceUrl = match.groupValues[2].trim()

            if (bookName.isNotEmpty() && sourceUrl.isNotEmpty()) {
                sources.add(Source(bookName = bookName, sourceURL = sourceUrl))
            }
        }

        return sources
    }
}
