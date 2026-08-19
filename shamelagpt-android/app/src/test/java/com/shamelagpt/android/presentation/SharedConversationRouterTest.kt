package com.shamelagpt.android.presentation

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.mock.MockConversationRepository
import com.shamelagpt.android.mock.TestData
import kotlinx.coroutines.test.runTest
import org.junit.Test

class SharedConversationRouterTest {

    @Test
    fun resolveOpensOwnedConversationInApp() = runTest {
        val repository = MockConversationRepository()
        repository.addConversation(TestData.createConversation(id = "mine"))

        val action = SharedConversationRouter.resolve("mine", repository)

        assertThat(action).isEqualTo(SharedLinkAction.OpenInApp("mine"))
    }

    @Test
    fun resolveOpensUnknownConversationInBrowser() = runTest {
        val repository = MockConversationRepository()

        val action = SharedConversationRouter.resolve("someone-else", repository)

        assertThat(action).isEqualTo(
            SharedLinkAction.OpenInBrowser("https://shamelagpt.com/shared?chatid=someone-else")
        )
    }
}
