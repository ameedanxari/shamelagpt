package com.shamelagpt.android.presentation

import android.content.ClipData
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Build
import androidx.activity.ComponentActivity
import com.shamelagpt.android.core.util.Logger

/**
 * Lightweight activity to receive ACTION_SEND / ACTION_SEND_MULTIPLE from other apps.
 * Extracts shared text or image URIs and forwards them to MainActivity for processing.
 */
class ShareReceiverActivity : ComponentActivity() {
    private val tag = "ShareReceiver"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        Logger.i(tag, "onCreate action=${intent?.action} type=${intent?.type ?: "null"}")
        handleShareIntent(intent)
        finish()
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Logger.i(tag, "onNewIntent action=${intent?.action} type=${intent?.type ?: "null"}")
        intent?.let { handleShareIntent(it) }
        finish()
    }

    private fun handleShareIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type
        Logger.i(tag, "handleShareIntent action=$action mime=${type ?: "null"}")

        val forward = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_GRANT_READ_URI_PERMISSION
        }

        if (Intent.ACTION_SEND == action) {
            val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
            val stream: Uri? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }

            sharedText?.let { forward.putExtra("shamela_shared_text", it) }
            stream?.let { uri ->
                // Grant temporary read permission where possible; ignore failures in limited test envs
                try {
                    contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } catch (ex: Exception) {
                    // Ignore - may not be supported for certain URI schemes in tests
                }
                forward.clipData = ClipData.newUri(contentResolver, "shared_image", uri)
                forward.putExtra("shamela_shared_uris", arrayListOf(uri))
            }
            Logger.i(
                tag,
                "ACTION_SEND parsed textPresent=${!sharedText.isNullOrBlank()} streamPresent=${stream != null}"
            )
        } else if (Intent.ACTION_SEND_MULTIPLE == action) {
            val uris: ArrayList<Uri>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
            }
            uris?.let { list ->
                // Persist permissions for each
                list.forEach { uri ->
                    try {
                        contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    } catch (ex: Exception) {
                        // ignore
                    }
                }
                if (list.isNotEmpty()) {
                    val clipData = ClipData.newUri(contentResolver, "shared_image", list.first())
                    list.drop(1).forEach { uri -> clipData.addItem(ClipData.Item(uri)) }
                    forward.clipData = clipData
                }
                forward.putExtra("shamela_shared_uris", list)
                Logger.i(tag, "ACTION_SEND_MULTIPLE parsed uriCount=${list.size}")
            }
        }

        // Preserve MIME type if present
        type?.let { forward.putExtra("shamela_shared_mime", it) }

        // Launch main activity to handle the shared payload
        Logger.i(
            tag,
            "Forwarding to MainActivity extras text=${forward.hasExtra("shamela_shared_text")} uris=${forward.hasExtra("shamela_shared_uris")}"
        )
        startActivity(forward)
    }
}
