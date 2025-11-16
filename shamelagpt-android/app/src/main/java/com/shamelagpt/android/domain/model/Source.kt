package com.shamelagpt.android.domain.model

/**
 * Domain model representing a source citation.
 *
 * @property bookName Name of the referenced book
 * @property sourceURL URL to the source on Shamela.ws
 * @property pageNumber Optional page number extracted from source URL
 */
data class Source(
    val bookName: String,
    val sourceURL: String,
    val pageNumber: Int? = null
) {
    /**
     * Formatted citation text for UI and sharing.
     */
    val citation: String
        get() = pageNumber?.let { "$bookName, p. $it" } ?: bookName
}
