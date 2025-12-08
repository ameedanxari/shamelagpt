package com.shamelagpt.android.data.remote

import com.shamelagpt.android.domain.model.Source

/**
 * Parses API responses to extract clean content and sources.
 */
object ResponseParser {

    /**
     * Parses the answer markdown to extract clean content and sources.
     *
     * Supports headers like "Sources:", "المصادر", or "المصادر / Sources".
     *
     * @param answer The markdown formatted answer from API
     * @return Pair of (clean content, list of sources)
     */
    fun parseAnswer(answer: String): Pair<String, List<Source>> {
        val normalized = answer.replace("\r\n", "\n")
        val headerPattern = Regex("(?mi)^(?:المصادر|Sources)(?:\\s*/\\s*(?:Sources|المصادر))?\\s*:?.*$")

        val headerMatch = headerPattern.find(normalized)
        if (headerMatch == null) {
            return normalized.trim() to emptyList()
        }

        val contentPart = normalized.substring(0, headerMatch.range.first)
        val sourcesPart = normalized.substring(headerMatch.range.last + 1)
        val nextHeader = headerPattern.find(sourcesPart)
        val sourcesSlice = if (nextHeader != null) {
            sourcesPart.substring(0, nextHeader.range.first)
        } else {
            sourcesPart
        }

        val sources = extractSources(sourcesSlice)
        return contentPart.trim() to sources
    }

    /**
     * Extracts sources from the sources section of the markdown.
     *
     * @param sourcesSection The sources section text
     * @return List of Source objects
     */
    private fun extractSources(sourcesSection: String): List<Source> {
        val sources = mutableListOf<Source>()

        // Accept lines beginning with "-" or "*"
        sourcesSection
            .split("\n")
            .map { it.trim() }
            .filter { it.startsWith("-") || it.startsWith("*") }
            .forEach { line ->
                val cleanLine = line.replace(Regex("^[*-]\\s*"), "")

                // Try **book_name:** format
                val bookNamePattern = Regex("""\*\*book_name:\*\*\s*([^,]+)""")
                val sourceUrlPattern = Regex("""\*\*source_url:\*\*\s*(https?://\S+)""")
                val bookName = bookNamePattern.find(cleanLine)?.groupValues?.get(1)?.trim()
                val urlStructured = sourceUrlPattern.find(cleanLine)?.groupValues?.get(1)?.trim()

                if (!bookName.isNullOrEmpty() && !urlStructured.isNullOrEmpty()) {
                    sources.add(Source(bookName = bookName, sourceURL = urlStructured))
                    return@forEach
                }

                // Fallback: split on first URL in the line (e.g., "Title - https://...")
                val urlFallback = findFirstUrl(cleanLine)
                if (urlFallback != null) {
                    val title = cleanLine
                        .replace(urlFallback, "")
                        .replace(" - ", " ")
                        .trim()
                    sources.add(
                        Source(
                            bookName = if (title.isEmpty()) urlFallback else title,
                            sourceURL = urlFallback
                        )
                    )
                }
            }

        return sources
    }

    private fun findFirstUrl(text: String): String? {
        val pattern = Regex("https?://[^\\s]+")
        return pattern.find(text)?.value
    }
}
