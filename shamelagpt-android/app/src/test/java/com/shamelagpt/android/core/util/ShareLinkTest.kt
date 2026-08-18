package com.shamelagpt.android.core.util

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ShareLinkTest {

    @Test
    fun normalizeReturnsCanonicalLinkWhenRawIsNull() {
        val result = ShareLink.normalize(null, conversationId = "abc-123")
        assertThat(result).isEqualTo("https://shamelagpt.com/shared?chatid=abc-123")
    }

    @Test
    fun normalizeReturnsCanonicalLinkWhenRawIsEmpty() {
        val result = ShareLink.normalize("   ", conversationId = "abc-123")
        assertThat(result).isEqualTo("https://shamelagpt.com/shared?chatid=abc-123")
    }

    @Test
    fun normalizeLeavesQueryFormUntouched() {
        val raw = "https://shamelagpt.com/shared?chatid=abc-123"
        assertThat(ShareLink.normalize(raw, conversationId = "abc-123")).isEqualTo(raw)
    }

    @Test
    fun normalizeConvertsLegacyPathSegmentForm() {
        val uuid = "f1e2d3c4-5678-90ab-cdef-1234567890ab"
        val raw = "https://shamelagpt.com/shared/$uuid"

        val result = ShareLink.normalize(raw, conversationId = uuid)

        assertThat(result).isEqualTo("https://shamelagpt.com/shared?chatid=$uuid")
    }

    @Test
    fun normalizePreservesNonProductionOrigin() {
        val uuid = "f1e2d3c4-5678-90ab-cdef-1234567890ab"
        val raw = "https://staging.shamelagpt.com/shared/$uuid"

        val result = ShareLink.normalize(raw, conversationId = uuid)

        assertThat(result).isEqualTo("https://staging.shamelagpt.com/shared?chatid=$uuid")
    }

    @Test
    fun normalizePreservesOriginWithExplicitPort() {
        val raw = "http://localhost:3000/shared/abc-123"

        val result = ShareLink.normalize(raw, conversationId = "abc-123")

        assertThat(result).isEqualTo("http://localhost:3000/shared?chatid=abc-123")
    }

    @Test
    fun normalizeFallsBackWhenRawIsUnparseable() {
        val result = ShareLink.normalize("not a url at all", conversationId = "abc-123")
        assertThat(result).isEqualTo("https://shamelagpt.com/shared?chatid=abc-123")
    }

    @Test
    fun normalizeFallsBackWhenPathIsUnrelated() {
        val result = ShareLink.normalize("https://shamelagpt.com/pricing", conversationId = "abc-123")
        assertThat(result).isEqualTo("https://shamelagpt.com/shared?chatid=abc-123")
    }
}
