package com.shamelagpt.android.core.util

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.shamelagpt.android.R

import android.widget.Toast

object EmailIntentHelper {
    private const val FEEDBACK_EMAIL = "contact@creatrixe.com"

    fun openFeedbackEmail(context: Context) {
        val subject = Uri.encode(context.getString(R.string.feedback_email_subject))
        val mailUri = Uri.parse("mailto:$FEEDBACK_EMAIL?subject=$subject")
        val intent = Intent(Intent.ACTION_SENDTO, mailUri)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Logger.e("EmailIntentHelper", "No email client found: ${e.message}")
            Toast.makeText(context, context.getString(R.string.no_email_client_error), Toast.LENGTH_LONG).show()
        }
    }
}
