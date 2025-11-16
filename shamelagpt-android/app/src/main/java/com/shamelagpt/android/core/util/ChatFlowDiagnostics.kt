package com.shamelagpt.android.core.util

import android.os.SystemClock
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

/**
 * Lightweight runtime diagnostics for identifying where chat flow is when the app stalls.
 */
object ChatFlowDiagnostics {
    private const val TAG = "ChatFlowDiagnostics"

    private val phase = AtomicReference("idle")
    private val conversationId = AtomicReference<String?>(null)
    private val threadId = AtomicReference<String?>(null)
    private val detail = AtomicReference<String?>(null)
    private val updatedElapsedMs = AtomicLong(SystemClock.elapsedRealtime())

    fun markPhase(
        phaseName: String,
        conversationId: String? = null,
        threadId: String? = null,
        detail: String? = null
    ) {
        phase.set(phaseName)
        this.conversationId.set(conversationId)
        this.threadId.set(threadId)
        this.detail.set(detail)
        updatedElapsedMs.set(SystemClock.elapsedRealtime())

        Logger.d(
            TAG,
            "phase=$phaseName conversationId=${Logger.redactedId(conversationId)} " +
                "threadId=${Logger.redactedId(threadId)} detail=${detail ?: "none"}"
        )
    }

    fun clear(detail: String? = null) {
        markPhase(
            phaseName = "idle",
            conversationId = null,
            threadId = null,
            detail = detail
        )
    }

    fun snapshot(): String {
        val ageMs = (SystemClock.elapsedRealtime() - updatedElapsedMs.get()).coerceAtLeast(0L)
        return "phase=${phase.get()} " +
            "conversationId=${Logger.redactedId(conversationId.get())} " +
            "threadId=${Logger.redactedId(threadId.get())} " +
            "detail=${detail.get() ?: "none"} " +
            "ageMs=$ageMs"
    }
}
