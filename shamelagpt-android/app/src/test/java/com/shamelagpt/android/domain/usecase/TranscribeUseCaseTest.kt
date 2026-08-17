package com.shamelagpt.android.domain.usecase

import com.google.common.truth.Truth.assertThat
import com.shamelagpt.android.data.remote.dto.TranscribeResponse
import com.shamelagpt.android.mock.MockChatRepository
import com.shamelagpt.android.util.MainCoroutineRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runTest
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@ExperimentalCoroutinesApi
class TranscribeUseCaseTest {

    @get:Rule
    val mainCoroutineRule = MainCoroutineRule()

    private lateinit var mockChatRepository: MockChatRepository
    private lateinit var useCase: TranscribeUseCase

    @Before
    fun setup() {
        mockChatRepository = MockChatRepository()
        useCase = TranscribeUseCase(mockChatRepository)
    }

    @Test
    fun invokeUploadsAudioWithAutoDetect() = runTest {
        mockChatRepository.transcribeResult = Result.success(
            TranscribeResponse(text = "نماز", language = "ur")
        )

        val result = useCase(
            audioBytes = byteArrayOf(1, 2),
            mimeType = "audio/mp4",
            fileName = "voice.m4a",
            language = null
        )

        assertThat(result.isSuccess).isTrue()
        assertThat(result.getOrNull()?.text).isEqualTo("نماز")
        assertThat(mockChatRepository.transcribeCallCount).isEqualTo(1)
        assertThat(mockChatRepository.lastTranscribeLanguage).isNull()
    }
}
