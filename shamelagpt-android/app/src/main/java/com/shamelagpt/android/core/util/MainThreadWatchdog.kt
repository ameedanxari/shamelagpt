package com.shamelagpt.android.core.util

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import kotlin.concurrent.thread

/**
 * Detects prolonged main-thread stalls and logs the blocked stack with chat flow context.
 */
object MainThreadWatchdog {
    private const val TAG = "MainThreadWatchdog"
    private const val HEARTBEAT_INTERVAL_MS = 500L
    private const val CHECK_INTERVAL_MS = 1000L
    private const val STALL_THRESHOLD_MS = 5000L

    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var started = false
    @Volatile private var lastHeartbeatElapsedMs = SystemClock.elapsedRealtime()
    @Volatile private var lastReportedElapsedMs = 0L

    private val heartbeatRunnable = object : Runnable {
        override fun run() {
            lastHeartbeatElapsedMs = SystemClock.elapsedRealtime()
            mainHandler.postDelayed(this, HEARTBEAT_INTERVAL_MS)
        }
    }

    fun start() {
        synchronized(this) {
            if (started) return
            started = true
            lastHeartbeatElapsedMs = SystemClock.elapsedRealtime()
            mainHandler.post(heartbeatRunnable)
            thread(
                name = "Shamela-MainWatchdog",
                isDaemon = true
            ) { monitorLoop() }
            Logger.i(TAG, "Started with thresholdMs=$STALL_THRESHOLD_MS")
        }
    }

    private fun monitorLoop() {
        while (started) {
            try {
                Thread.sleep(CHECK_INTERVAL_MS)
            } catch (_: InterruptedException) {
                // Keep monitoring unless process exits.
            }

            val now = SystemClock.elapsedRealtime()
            val stalledMs = now - lastHeartbeatElapsedMs
            if (stalledMs < STALL_THRESHOLD_MS) continue

            val sinceLastReport = now - lastReportedElapsedMs
            if (sinceLastReport < STALL_THRESHOLD_MS) continue
            lastReportedElapsedMs = now

            logStall(stalledMs)
        }
    }

    private fun logStall(stalledMs: Long) {
        val mainThread = Looper.getMainLooper().thread
        val stack = mainThread.stackTrace
            .take(30)
            .joinToString(separator = " <- ") { frame ->
                "${frame.className}.${frame.methodName}:${frame.lineNumber}"
            }

        Logger.e(
            TAG,
            "Detected possible main-thread stall stalledMs=$stalledMs " +
                "chat=${ChatFlowDiagnostics.snapshot()} mainStack=$stack"
        )
    }
}
