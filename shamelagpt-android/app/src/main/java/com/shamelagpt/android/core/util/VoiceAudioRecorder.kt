package com.shamelagpt.android.core.util

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.io.File

private const val TAG = "VoiceAudioRecorder"

/**
 * Records microphone audio to a cache file for upload to `/api/transcribe`.
 *
 * Prefers MPEG-4 / AAC (`audio/mp4`), which the backend accepts for audio uploads.
 * Auto-stops at [MAX_DURATION_MS] via [MediaRecorder.setMaxDuration].
 */
class VoiceAudioRecorder(private val context: Context) {

    data class Recording(
        val bytes: ByteArray,
        val mimeType: String,
        val fileName: String
    ) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false
            other as Recording
            return mimeType == other.mimeType &&
                fileName == other.fileName &&
                bytes.contentEquals(other.bytes)
        }

        override fun hashCode(): Int {
            var result = bytes.contentHashCode()
            result = 31 * result + mimeType.hashCode()
            result = 31 * result + fileName.hashCode()
            return result
        }
    }

    companion object {
        const val MAX_DURATION_MS = 120_000
        const val MAX_UPLOAD_BYTES = 20 * 1024 * 1024
        private const val BIT_RATE = 128_000
        private const val SAMPLE_RATE = 44_100
    }

    var onMaxDurationReached: (() -> Unit)? = null

    private var recorder: MediaRecorder? = null
    private var outputFile: File? = null
    private var mimeType: String = "audio/mp4"
    private var fileName: String = "voice.m4a"
    private var recording = false
    private val mainHandler = Handler(Looper.getMainLooper())

    fun isRecording(): Boolean = recording

    fun start(): Result<Unit> {
        if (recording) {
            Logger.w(TAG, "start ignored: already recording")
            return Result.failure(IllegalStateException("Already recording"))
        }
        return try {
            val dir = File(context.cacheDir, "voice")
            if (!dir.exists() && !dir.mkdirs()) {
                return Result.failure(IllegalStateException("Could not create voice cache directory"))
            }
            val file = File(dir, "voice_${System.currentTimeMillis()}.m4a")
            outputFile = file
            mimeType = "audio/mp4"
            fileName = file.name

            val mediaRecorder = createRecorder()
            mediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            mediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            mediaRecorder.setAudioEncodingBitRate(BIT_RATE)
            mediaRecorder.setAudioSamplingRate(SAMPLE_RATE)
            mediaRecorder.setOutputFile(file.absolutePath)
            mediaRecorder.setMaxDuration(MAX_DURATION_MS)
            mediaRecorder.setOnInfoListener { _, what, _ ->
                if (what == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED) {
                    Logger.i(TAG, "max recording duration reached")
                    mainHandler.post { onMaxDurationReached?.invoke() }
                }
            }
            mediaRecorder.prepare()
            mediaRecorder.start()
            recorder = mediaRecorder
            recording = true
            Logger.i(TAG, "voice recording started file=${file.name}")
            Result.success(Unit)
        } catch (e: Exception) {
            Logger.e(TAG, "failed to start voice recording", e)
            releaseInternal(deleteFile = true)
            recording = false
            Result.failure(e)
        }
    }

    fun stop(): Result<Recording> {
        if (!recording && recorder == null) {
            return Result.failure(IllegalStateException("Not recording"))
        }
        return try {
            try {
                recorder?.stop()
            } catch (e: RuntimeException) {
                Logger.w(TAG, "voice recorder stop threw ${e::class.simpleName}")
            }
            releaseInternal(deleteFile = false)
            recording = false
            val file = outputFile
            outputFile = null
            if (file == null || !file.exists() || file.length() == 0L) {
                file?.delete()
                return Result.failure(IllegalStateException("Empty recording"))
            }
            val bytes = file.readBytes()
            file.delete()
            Logger.i(TAG, "voice recording stopped bytes=${bytes.size} mime=$mimeType")
            Result.success(Recording(bytes, mimeType, fileName))
        } catch (e: Exception) {
            Logger.e(TAG, "failed to stop voice recording", e)
            releaseInternal(deleteFile = true)
            recording = false
            outputFile = null
            Result.failure(e)
        }
    }

    fun cancel() {
        releaseInternal(deleteFile = true)
        recording = false
        outputFile = null
        Logger.i(TAG, "voice recording cancelled")
    }

    fun destroy() {
        cancel()
        onMaxDurationReached = null
    }

    private fun createRecorder(): MediaRecorder {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(context)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
    }

    private fun releaseInternal(deleteFile: Boolean) {
        try {
            recorder?.release()
        } catch (e: Exception) {
            Logger.w(TAG, "voice recorder release failed: ${e::class.simpleName}")
        }
        recorder = null
        if (deleteFile) {
            outputFile?.delete()
            outputFile = null
        }
    }
}
