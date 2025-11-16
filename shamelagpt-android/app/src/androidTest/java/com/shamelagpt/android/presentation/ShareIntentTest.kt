package com.shamelagpt.android.presentation

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry
import androidx.test.runner.lifecycle.Stage
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumentation tests to verify share intents are forwarded from ShareReceiverActivity to MainActivity.
 */
@RunWith(AndroidJUnit4::class)
class ShareIntentTest {
    @Test
    fun shareText_forwardsToMainActivity_withExtra() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val intent = Intent(context, ShareReceiverActivity::class.java).apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, "Test shared text from app")
            type = "text/plain"
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        context.startActivity(intent)

        val mainIntent = waitForMainActivityIntent()
        assertNotNull("MainActivity intent should exist", mainIntent)
        assertEquals("Shared text should be forwarded", "Test shared text from app", mainIntent.getStringExtra("shamela_shared_text"))
    }

    @Test
    fun shareImage_forwardsUrisToMainActivity() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val fakeUri = Uri.parse("content://com.fake.provider/image/1")

        val intent = Intent(context, ShareReceiverActivity::class.java).apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_STREAM, fakeUri)
            type = "image/*"
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        context.startActivity(intent)

        val mainIntent = waitForMainActivityIntent()
        assertNotNull("MainActivity intent should exist", mainIntent)
        @Suppress("DEPRECATION")
        val uris = mainIntent.getParcelableArrayListExtra<Uri>("shamela_shared_uris")
        assertNotNull("Shared URIs should be forwarded", uris)
        assertEquals(1, uris?.size)
        assertEquals(fakeUri, uris?.get(0))
    }

    private fun waitForMainActivityIntent(timeoutMs: Long = 10_000): Intent {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val deadline = System.currentTimeMillis() + timeoutMs

        while (System.currentTimeMillis() < deadline) {
            var resumedActivities: Collection<Activity> = emptyList()
            instrumentation.runOnMainSync {
                resumedActivities = ActivityLifecycleMonitorRegistry.getInstance()
                    .getActivitiesInStage(Stage.RESUMED)
            }

            val mainActivity = resumedActivities
                .filterIsInstance<MainActivity>()
                .firstOrNull()
            if (mainActivity != null) {
                return mainActivity.intent
            }

            Thread.sleep(200)
        }

        throw AssertionError("MainActivity should be resumed after share intent")
    }
}
