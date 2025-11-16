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
        val headerPattern = Regex(
            pattern = """(?mi)^\s*#*\s*(?:المصادر|Sources)(?:\s*/\s*(?:Sources|المصادر))?\s*:?\s*$"""
        )

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

                // Try markdown link format: **[Book Title](URL)** - Author
                val markdownLinkPattern = Regex("""\*\*\[(.*?)\]\((.*?)\)\*\*\s*-\s*(.*)""")
                val markdownMatch = markdownLinkPattern.find(cleanLine)
                if (markdownMatch != null) {
                    val title = markdownMatch.groupValues[1].trim()
                    val url = normalizeSourceUrl(markdownMatch.groupValues[2].trim())
                    if (title.isNotBlank() && url.isNotBlank()) {
                        sources.add(
                            Source(
                                bookName = title,
                                sourceURL = url,
                                pageNumber = extractPageNumber(url)
                            )
                        )
                        return@forEach
                    }
                }

                // Try markdown link format without bold wrapper: [Book Title](URL)
                val markdownSimplePattern = Regex("""\[(.*?)]\((https?://[^)\s]+)\)""")
                val simpleMatch = markdownSimplePattern.find(cleanLine)
                if (simpleMatch != null) {
                    val title = simpleMatch.groupValues[1].trim()
                    val url = normalizeSourceUrl(simpleMatch.groupValues[2].trim())
                    if (title.isNotBlank() && url.isNotBlank()) {
                        sources.add(
                            Source(
                                bookName = title,
                                sourceURL = url,
                                pageNumber = extractPageNumber(url)
                            )
                        )
                        return@forEach
                    }
                }

                // Try **book_name:** format
                val bookNamePattern = Regex("""\*\*book_name:\*\*\s*([^,]+)""")
                val sourceUrlPattern = Regex("""\*\*source_url:\*\*\s*(https?://\S+)""")
                val bookName = bookNamePattern.find(cleanLine)?.groupValues?.get(1)?.trim()
                val urlStructured = sourceUrlPattern.find(cleanLine)?.groupValues?.get(1)?.trim()

                if (!bookName.isNullOrBlank() && !urlStructured.isNullOrBlank()) {
                    val normalizedUrl = normalizeSourceUrl(urlStructured)
                    sources.add(
                        Source(
                            bookName = bookName,
                            sourceURL = normalizedUrl,
                            pageNumber = extractPageNumber(normalizedUrl)
                        )
                    )
                    return@forEach
                }

                // Try Arabic structured format
                val bookNameArabicPattern = Regex("""\*\*(?:اسم\s*الكتاب|عنوان\s*الكتاب):\*\*\s*([^،,]+)""")
                val sourceUrlArabicPattern = Regex("""\*\*(?:رابط\s*المصدر|رابط):\*\*\s*(https?://\S+)""")
                val bookNameArabic = bookNameArabicPattern.find(cleanLine)?.groupValues?.get(1)?.trim()
                val urlArabic = sourceUrlArabicPattern.find(cleanLine)?.groupValues?.get(1)?.trim()

                if (!bookNameArabic.isNullOrBlank() && !urlArabic.isNullOrBlank()) {
                    val normalizedUrl = normalizeSourceUrl(urlArabic)
                    sources.add(
                        Source(
                            bookName = bookNameArabic,
                            sourceURL = normalizedUrl,
                            pageNumber = extractPageNumber(normalizedUrl)
                        )
                    )
                    return@forEach
                }

                // If it looks like a structured line but failed validation, don't use fallback
                if (cleanLine.contains("**book_name:**") ||
                    cleanLine.contains("**source_url:**") ||
                    cleanLine.contains("**اسم الكتاب:**") ||
                    cleanLine.contains("**عنوان الكتاب:**") ||
                    cleanLine.contains("**رابط المصدر:**") ||
                    cleanLine.contains("**رابط:**")
                ) {
                    return@forEach
                }

                // Fallback: split on first URL in the line (e.g., "Title - https://...")
                val urlFallback = findFirstUrl(cleanLine)
                if (urlFallback != null) {
                    val normalizedUrl = normalizeSourceUrl(urlFallback)
                    val title = cleanLine
                        .replace(urlFallback, "")
                        .replace(" - ", " ")
                        .replace("(", "")
                        .replace(")", "")
                        .replace("[", "")
                        .replace("]", "")
                        .trimEnd('-', ':', '؛', ';', ',', '،')
                        .trim()
                    sources.add(
                        Source(
                            bookName = if (title.isEmpty()) normalizedUrl else title,
                            sourceURL = normalizedUrl,
                            pageNumber = extractPageNumber(normalizedUrl)
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

    private fun normalizeSourceUrl(url: String): String {
        return url.trim().trimEnd(')', ']', '}', '.', ',', '،', ';', '؛')
    }

    private fun extractPageNumber(url: String): Int? {
        val cleaned = normalizeSourceUrl(url)
        val withoutQuery = cleaned.substringBefore('?').substringBefore('#').trimEnd('/')
        return withoutQuery.substringAfterLast('/').toIntOrNull()
    }
}
