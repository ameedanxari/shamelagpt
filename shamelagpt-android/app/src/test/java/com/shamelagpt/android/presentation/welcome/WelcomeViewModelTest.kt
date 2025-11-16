package com.shamelagpt.android.presentation.welcome

import com.shamelagpt.android.core.preferences.PreferencesManager
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class WelcomeViewModelTest {

    private val preferencesManager = mockk<PreferencesManager>(relaxed = true)
    private val viewModel = WelcomeViewModel(preferencesManager)

    @Test
    fun `hasSeenWelcome returns value from preferences`() {
        every { preferencesManager.hasSeenWelcome() } returns true
        assertTrue(viewModel.hasSeenWelcome())
        
        every { preferencesManager.hasSeenWelcome() } returns false
        assertFalse(viewModel.hasSeenWelcome())
    }

    @Test
    fun `completeWelcome updates preferences`() {
        viewModel.completeWelcome()
        verify { preferencesManager.setHasSeenWelcome(true) }
    }
}
