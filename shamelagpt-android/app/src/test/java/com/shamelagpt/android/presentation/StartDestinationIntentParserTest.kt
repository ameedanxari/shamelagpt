package com.shamelagpt.android.presentation

import android.content.Intent
import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.presentation.navigation.ChatRoute
import com.shamelagpt.android.presentation.navigation.HistoryRoute
import com.shamelagpt.android.presentation.navigation.SettingsRoute
import io.mockk.every
import io.mockk.mockk
import org.junit.Test

class StartDestinationIntentParserTest {

    @Test
    fun parseReturnsNullForNullIntent() {
        assertThat(StartDestinationIntentParser.parse(null)).isNull()
    }

    @Test
    fun parseSharedTextRoutesToChat() {
        val intent = mockIntent(hasSharedText = true)

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(ChatRoute())
    }

    @Test
    fun parseSharedUrisRoutesToChat() {
        val intent = mockIntent(hasSharedUris = true)

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(ChatRoute())
    }

    @Test
    fun parseSharePayloadOverridesDeepLinkConversationId() {
        val intent = mockIntent(
            hasSharedUris = true,
            data = mockUri(
                scheme = "https",
                host = "shamelagpt.com",
                path = "/chat",
                queryConversationId = "conv-existing"
            )
        )

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(ChatRoute())
    }

    @Test
    fun parseHttpsChatWithConversationIdRoutesToChatConversation() {
        val intent = mockIntent(
            data = mockUri(
                scheme = "https",
                host = "shamelagpt.com",
                path = "/chat",
                queryConversationId = "conv-1"
            )
        )

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(ChatRoute("conv-1"))
    }

    @Test
    fun parseHttpsChatWithoutConversationIdRoutesToNewChat() {
        val intent = mockIntent(
            data = mockUri(
                scheme = "https",
                host = "www.shamelagpt.com",
                path = "/chat"
            )
        )

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(ChatRoute())
    }

    @Test
    fun parseCustomSchemeHistoryRoutesToHistory() {
        val intent = mockIntent(
            data = mockUri(
                scheme = "shamelagpt",
                host = "history",
                path = ""
            )
        )

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(HistoryRoute)
    }

    @Test
    fun parseCustomSchemeSettingsRoutesToSettings() {
        val intent = mockIntent(
            data = mockUri(
                scheme = "shamelagpt",
                host = "settings",
                path = ""
            )
        )

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(SettingsRoute)
    }

    @Test
    fun parseCustomSchemeChatPathRoutesToChat() {
        val intent = mockIntent(
            data = mockUri(
                scheme = "shamelagpt",
                host = null,
                path = "/chat",
                queryConversationId = "conv-77"
            )
        )

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isEqualTo(ChatRoute("conv-77"))
    }

    @Test
    fun parseUnknownDeepLinkReturnsNull() {
        val intent = mockIntent(
            data = mockUri(
                scheme = "https",
                host = "example.com",
                path = "/chat",
                queryConversationId = "conv-1"
            )
        )

        val route = StartDestinationIntentParser.parse(intent)

        assertThat(route).isNull()
    }

    private fun mockIntent(
        hasSharedText: Boolean = false,
        hasSharedUris: Boolean = false,
        data: android.net.Uri? = null
    ): Intent {
        return mockk {
            every { hasExtra("shamela_shared_text") } returns hasSharedText
            every { hasExtra("shamela_shared_uris") } returns hasSharedUris
            every { this@mockk.data } returns data
        }
    }

    private fun mockUri(
        scheme: String,
        host: String?,
        path: String,
        queryConversationId: String? = null
    ): android.net.Uri {
        return mockk {
            every { this@mockk.scheme } returns scheme
            every { this@mockk.host } returns host
            every { this@mockk.path } returns path
            every { getQueryParameter("id") } returns queryConversationId
        }
    }
}
