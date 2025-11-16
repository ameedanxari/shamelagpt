package com.shamelagpt.android.core.util

import android.content.Intent
import android.net.Uri
import android.os.Build

data class FactCheckSharePayload(
    val text: String?,
    val uris: List<Uri>,
    val mimeType: String?
)

/**
 * In-memory share payload store to bridge ShareReceiverActivity -> MainActivity -> ChatViewModel.
 */
object FactCheckSharePayloadStore {
    private const val TAG = "SharePayloadStore"
    private const val EXTRA_SHARED_TEXT = "shamela_shared_text"
    private const val EXTRA_SHARED_URIS = "shamela_shared_uris"
    private const val EXTRA_SHARED_MIME = "shamela_shared_mime"

    private var pendingPayload: FactCheckSharePayload? = null

    fun storeFromIntent(intent: Intent?) {
        if (intent == null) {
            Logger.d(TAG, "storeFromIntent skipped: intent is null")
            return
        }

        val sharedText = intent.getStringExtra(EXTRA_SHARED_TEXT)?.trim()
        val uris: ArrayList<Uri>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(EXTRA_SHARED_URIS, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(EXTRA_SHARED_URIS)
        }
        val mimeType = intent.getStringExtra(EXTRA_SHARED_MIME)

        val normalizedText = sharedText?.takeIf { it.isNotBlank() }
        val normalizedUris = uris?.filterNotNull().orEmpty()

        if (normalizedText == null && normalizedUris.isEmpty()) {
            Logger.d(TAG, "storeFromIntent found no share payload extras")
            return
        }

        pendingPayload = FactCheckSharePayload(
            text = normalizedText,
            uris = normalizedUris,
            mimeType = mimeType
        )
        Logger.i(
            TAG,
            "stored payload textPresent=${normalizedText != null} uriCount=${normalizedUris.size} mimeType=${mimeType ?: "null"}"
        )
    }

    fun consume(): FactCheckSharePayload? {
        val payload = pendingPayload
        pendingPayload = null
        Logger.i(
            TAG,
            "consume payload present=${payload != null} uriCount=${payload?.uris?.size ?: 0} textPresent=${!payload?.text.isNullOrBlank()}"
        )
        return payload
    }
}
