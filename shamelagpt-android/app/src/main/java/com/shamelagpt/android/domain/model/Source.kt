package com.shamelagpt.android.domain.model

/**
 * Domain model representing a source citation.
 *
 * @property bookName Name of the referenced book
 * @property sourceURL URL to the source on Shamela.ws
 */
data class Source(
    val bookName: String,
    val sourceURL: String
)
